import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../services/storage_service.dart';
import 'connectivity_service.dart';
import 'offline_write.dart';

/// A queued file that has now been uploaded.
class UploadedFile {
  final String documentId;
  final String fileName;
  final String url;
  const UploadedFile(this.documentId, this.fileName, this.url);
}

/// One file waiting to be uploaded to a document.
class OutboxJob {
  final String id;

  /// 'documentFile' (a file on a document) or 'signature' (a signature image;
  /// [targetId] is the signatures/{id} record waiting for its imageUrl).
  final String kind;
  final String? targetId;
  final String documentId;
  final String companyId;
  final String localPath; // private copy inside the app's storage
  final String fileName; // original name — also the key in pendingFiles
  final DateTime createdAt;
  int attempts;
  String? lastError;

  OutboxJob({
    required this.id,
    this.kind = 'documentFile',
    this.targetId,
    required this.documentId,
    required this.companyId,
    required this.localPath,
    required this.fileName,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'targetId': targetId,
        'documentId': documentId,
        'companyId': companyId,
        'localPath': localPath,
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  static OutboxJob fromJson(Map<String, dynamic> j) => OutboxJob(
        id: j['id'],
        kind: j['kind'] ?? 'documentFile',
        targetId: j['targetId'],
        documentId: j['documentId'],
        companyId: j['companyId'],
        localPath: j['localPath'],
        fileName: j['fileName'],
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        attempts: j['attempts'] ?? 0,
        lastError: j['lastError'],
      );
}

/// Offline uploads for the mobile app.
///
/// Firestore queues its own writes offline, but Firebase Storage does not —
/// a file picked with no signal used to simply fail. Instead, the file is
/// copied into the app's private storage and its document is created at once
/// with `pendingFiles: [name]`, so it shows up everywhere straight away
/// ("Waiting to upload"). This outbox then uploads it as soon as there is a
/// connection — on start-up, whenever the signal returns, and on a timer —
/// adds the download URL to the document and clears the pending marker.
///
/// The queue is a JSON file next to the copies, so it survives the app being
/// closed or the phone restarting. Jobs are never dropped automatically: a
/// failing upload keeps retrying (the user's evidence must not vanish).
class UploadOutbox {
  UploadOutbox._();
  static final UploadOutbox instance = UploadOutbox._();

  /// Files waiting to upload (drives the "N waiting" badge).
  final ValueNotifier<int> pending = ValueNotifier<int>(0);

  /// True while an upload pass is running.
  final ValueNotifier<bool> syncing = ValueNotifier<bool>(false);

  /// Fires after each file is uploaded and attached, so providers holding
  /// documents in memory can swap "waiting" for the real file at once.
  final StreamController<UploadedFile> _uploaded =
      StreamController<UploadedFile>.broadcast();
  Stream<UploadedFile> get uploaded => _uploaded.stream;

  final _storage = StorageService();
  final _uuid = const Uuid();
  List<OutboxJob> _jobs = [];
  Directory? _dir;
  File? _queueFile;
  bool _started = false;
  bool _flushing = false;
  Timer? _timer;

  bool get supported => !kIsWeb;

  /// Loads the saved queue and starts syncing. Safe to call more than once.
  Future<void> start() async {
    if (_started || !supported) return;
    _started = true;
    try {
      final base = await getApplicationDocumentsDirectory();
      _dir = Directory('${base.path}/upload_outbox'); // l10n-ignore: path
      await _dir!.create(recursive: true);
      _queueFile = File('${_dir!.path}/queue.json'); // l10n-ignore: path
      if (await _queueFile!.exists()) {
        final raw = jsonDecode(await _queueFile!.readAsString()) as List;
        _jobs = raw
            .map((e) => OutboxJob.fromJson(Map<String, dynamic>.from(e)))
            .where((j) => File(j.localPath).existsSync())
            .toList();
      }
    } catch (e) {
      debugPrint('UploadOutbox: could not load queue: $e');
    }
    pending.value = _jobs.length;

    ConnectivityService.instance.online.addListener(() {
      if (ConnectivityService.instance.isOnline) flush();
    });
    // Retry on a timer too — the network flag can say "online" before the
    // internet is actually reachable, and a failed attempt must be retried.
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_jobs.isNotEmpty) flush();
    });
    unawaited(flush());
  }

  /// Copies [source] into the outbox for [documentId]. Returns the job.
  Future<OutboxJob> enqueue({
    required String documentId,
    required String companyId,
    required File source,
    String? fileName,
    String kind = 'documentFile',
    String? targetId,
  }) async {
    await start();
    final name = fileName ?? source.path.split(Platform.pathSeparator).last;
    final id = _uuid.v4();
    final copy = File('${_dir!.path}/${id}_$name');
    await source.copy(copy.path);
    final job = OutboxJob(
      id: id,
      kind: kind,
      targetId: targetId,
      documentId: documentId,
      companyId: companyId,
      localPath: copy.path,
      fileName: name,
      createdAt: DateTime.now(),
    );
    _jobs.add(job);
    await _persist();
    pending.value = _jobs.length;
    return job;
  }

  /// Local copies still waiting for [documentId] (to preview them offline).
  List<File> localFilesFor(String documentId) => _jobs
      .where((j) => j.documentId == documentId && j.kind == 'documentFile')
      .map((j) => File(j.localPath))
      .toList();

  /// Jobs that have failed at least once (to show "will retry").
  int get failingCount => _jobs.where((j) => j.attempts > 0).length;

  /// Uploads everything it can. Returns how many files were uploaded.
  Future<int> flush() async {
    if (!supported || _flushing || _jobs.isEmpty) return 0;
    if (!ConnectivityService.instance.isOnline) return 0;
    _flushing = true;
    syncing.value = true;
    var done = 0;
    try {
      for (final job in List<OutboxJob>.from(_jobs)) {
        if (!ConnectivityService.instance.isOnline) break;
        final file = File(job.localPath);
        if (!await file.exists()) {
          _jobs.remove(job); // copy vanished — nothing left to upload
          continue;
        }
        final isSignature = job.kind == 'signature';
        final url = isSignature
            ? await _storage.uploadSignature(
                file, job.companyId, job.targetId ?? job.id)
            : await _storage.uploadFile(
                file, job.companyId, job.documentId, job.fileName);
        if (url == null) {
          job.attempts++;
          job.lastError = 'upload failed'; // l10n-ignore: internal log
          continue;
        }
        // Attach the upload and clear its pending marker. Queued behind the
        // record's own creation, so the order is kept even offline.
        final db = FirebaseFirestore.instance;
        await commitWrite(
          isSignature
              ? db.collection('signatures').doc(job.targetId).update({
                  'imageUrl': url,
                  'pendingImage': false,
                })
              : db.collection('documents').doc(job.documentId).update({
                  'fileUrls': FieldValue.arrayUnion([url]),
                  'pendingFiles': FieldValue.arrayRemove([job.fileName]),
                }),
          label: isSignature ? 'attach signature' : 'attach uploaded file', // l10n-ignore: log label
        );
        _jobs.remove(job);
        done++;
        _uploaded.add(UploadedFile(job.documentId, job.fileName, url));
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('UploadOutbox: flush error: $e');
    } finally {
      await _persist();
      pending.value = _jobs.length;
      syncing.value = false;
      _flushing = false;
    }
    if (done > 0) debugPrint('UploadOutbox: uploaded $done file(s)');
    return done;
  }

  Future<void> _persist() async {
    final f = _queueFile;
    if (f == null) return;
    try {
      await f.writeAsString(jsonEncode(_jobs.map((j) => j.toJson()).toList()));
    } catch (e) {
      debugPrint('UploadOutbox: could not save queue: $e');
    }
  }

  void dispose() => _timer?.cancel();
}
