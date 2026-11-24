import 'dart:io';

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/offline/connectivity_service.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// A file chosen for upload (a path on the phone, or bytes on the web).
class _Picked {
  final String name;
  final File? file;
  final Uint8List? bytes;
  const _Picked(this.name, {this.file, this.bytes});
}

/// Upload a document from a phone: pick the expiry date on the calendar,
/// choose a file or take a photo, and upload. Works offline — the file is
/// kept on the phone and uploads itself when there's signal.
class MobileUploadScreen extends StatefulWidget {
  final String categoryId;
  final String documentTypeId;

  /// The expired / rejected document this upload replaces, if any.
  final String? existingDocumentId;

  const MobileUploadScreen({
    super.key,
    required this.categoryId,
    required this.documentTypeId,
    this.existingDocumentId,
  });

  @override
  State<MobileUploadScreen> createState() => _MobileUploadScreenState();
}

class _MobileUploadScreenState extends State<MobileUploadScreen> {
  static DateFormat get _long => DateFormat('d MMMM yyyy'); // follows the app language

  DocumentTypeModel? _type;
  bool _loading = true;
  bool _uploading = false;
  final List<_Picked> _files = [];
  final _spec = TextEditingController();
  DateTime? _expiry;
  DateTime? _reviewed;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year + 1, now.month); // expiries are usually ~1 yr out
    _loadType();
  }

  @override
  void dispose() {
    _spec.dispose();
    super.dispose();
  }

  Future<void> _loadType() async {
    final docs = Provider.of<DocumentProvider>(context, listen: false);
    DocumentTypeModel? t;
    for (final x in docs.documentTypes) {
      if (x.id == widget.documentTypeId) t = x;
    }
    t ??= await FirestoreService().getDocumentType(widget.documentTypeId);
    if (mounted) {
      setState(() {
        _type = t;
        _loading = false;
      });
    }
  }

  // ── Picking ──────────────────────────────────────────────────────────────

  bool get _multiple => _type?.allowMultipleDocuments ?? false;

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      allowMultiple: _multiple,
      withData: kIsWeb,
    );
    if (r == null) return;
    setState(() {
      if (!_multiple) _files.clear();
      for (final f in r.files) {
        if (kIsWeb && f.bytes != null) {
          _files.add(_Picked(f.name, bytes: f.bytes));
        } else if (f.path != null) {
          _files.add(_Picked(f.name, file: File(f.path!)));
        }
      }
    });
  }

  Future<void> _takePhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 2400);
    if (x == null) return;
    final stamp = DateFormat('yyyy-MM-dd HHmm').format(DateTime.now());
    final base = _type?.name ?? context.l10n.photoDefaultName;
    final name = '$base $stamp.jpg'
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    final picked = kIsWeb
        ? _Picked(name, bytes: await x.readAsBytes())
        : _Picked(name, file: File(x.path));
    setState(() {
      if (!_multiple) _files.clear();
      _files.add(picked);
    });
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined,
                color: MobileColors.green),
            title: Text(context.l10n.uploadTakePhoto),
            onTap: () {
              Navigator.pop(ctx);
              _takePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined,
                color: MobileColors.green),
            title: Text(context.l10n.uploadChooseFileTypes),
            onTap: () {
              Navigator.pop(ctx);
              _pickFile();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _preview() {
    final f = _files.isNotEmpty ? _files.first : null;
    if (f?.file != null) OpenFile.open(f!.file!.path);
  }

  // ── Upload ───────────────────────────────────────────────────────────────

  String? get _blocker {
    final t = _type;
    final l10n = context.l10n;
    if (t == null) return l10n.commonLoading;
    if (_files.isEmpty) return l10n.uploadNeedFileFirst;
    if (t.hasExpiryDate && _expiry == null) {
      return l10n.uploadNeedExpiry;
    }
    if (t.hasReviewedDate && _reviewed == null) {
      return l10n.uploadNeedReviewed;
    }
    if (t.requiresSpecification && _spec.text.trim().isEmpty) {
      return l10n.uploadNeedSpec;
    }
    return null;
  }

  Future<void> _upload() async {
    final blocker = _blocker;
    if (blocker != null) {
      _toast(blocker);
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final docs = Provider.of<DocumentProvider>(context, listen: false);
    final company = auth.effectiveCompany;
    final user = auth.effectiveUser;
    if (company == null || user == null) {
      _toast(context.l10n.uploadNoFarm);
      return;
    }
    final target = user.copyWith(companyId: company.id);
    final spec = _spec.text.trim().isEmpty ? null : _spec.text.trim();
    final offline = !ConnectivityService.instance.isOnline;

    setState(() => _uploading = true);
    var ok = 0;
    String? firstId;
    try {
      for (final f in _files) {
        final doc = await docs.createDocument(
          user: target,
          categoryId: widget.categoryId,
          documentTypeId: widget.documentTypeId,
          files: [
            if (kIsWeb) {'name': f.name, 'bytes': f.bytes} else f.file!,
          ],
          expiryDate: _expiry,
          specification: spec,
          reviewedDate: _reviewed,
        );
        if (doc != null) {
          ok++;
          firstId ??= doc.id;
        }
      }
      if (widget.existingDocumentId != null && ok > 0) {
        await docs.supersedeDocument(widget.existingDocumentId!,
            newDocumentId: firstId);
      }
    } catch (e) {
      if (mounted) _toast(context.l10n.errorSomethingWrong('$e'));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
    if (!mounted) return;

    if (ok == 0) {
      _toast(context.l10n.uploadFailed);
      return;
    }
    final pendingNow = docs.documents.any((d) => d.id == firstId && d.hasPendingFiles);
    _toast(offline || pendingNow
        ? context.l10n.uploadSavedOffline
        : context.l10n.uploadDoneWaitingReview);
    if (_type!.requiresSignature && firstId != null) {
      Navigator.of(context).pushReplacementNamed(RouteConstants.documentDetail,
          arguments: {'documentId': firstId});
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _type;
    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(
            title: t == null
                ? context.l10n.actionUpload
                : context.l10n.actionUploadType(t.name),
            showBack: true),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : t == null
                  ? _missingType()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        if (t.hasExpiryDate) ...[
                          Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(context.l10n.uploadTapExpiry,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: MobileColors.muted)),
                          ),
                          _monthBar(),
                          const SizedBox(height: 12),
                          _calendar(),
                          const SizedBox(height: 24),
                        ],
                        Text(t.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: MobileColors.ink)),
                        const SizedBox(height: 4),
                        Text(
                          t.hasExpiryDate
                              ? context.l10n.uploadSubtitleWithExpiry
                              : context.l10n.uploadSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: MobileColors.muted),
                        ),
                        const SizedBox(height: 20),
                        _fileCard(t),
                        if (t.hasReviewedDate) ...[
                          const SizedBox(height: 16),
                          _reviewedField(),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _spec,
                          onChanged: (_) => setState(() {}),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: t.requiresSpecification
                                ? context.l10n.uploadSpecRequired
                                : context.l10n.uploadSpecOptional,
                            hintText: context.l10n.uploadSpecHint,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
        ),
        if (t != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_blocker != null && _files.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_blocker!,
                        style: const TextStyle(
                            fontSize: 13, color: MobileColors.muted)),
                  ),
                MobilePrimaryButton(
                  label: _files.isEmpty
                      ? context.l10n.uploadChooseFileOrPhoto
                      : context.l10n.actionUploadType(t.name),
                  icon: _files.isEmpty
                      ? Icons.add_a_photo_outlined
                      : Icons.upload_outlined,
                  busy: _uploading,
                  onPressed: _files.isEmpty ? _chooseSource : _upload,
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _missingType() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.l10n.uploadTypeLoadFailed,
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() => _loading = true);
              _loadType();
            },
            child: Text(context.l10n.commonRetry),
          ),
        ]),
      );

  // ── Calendar ─────────────────────────────────────────────────────────────

  Widget _monthBar() {
    return MobileCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Expanded(
          child: InkWell(
            // Far-away dates: jump with the standard picker.
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _expiry ?? _month,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                helpText: context.l10n.expiryDate,
              );
              if (d != null) {
                setState(() {
                  _expiry = d;
                  _month = DateTime(d.year, d.month);
                });
              }
            },
            child: Text(DateFormat('MMMM yyyy').format(_month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
    );
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final lead = first.weekday - 1; // Monday-first
    final start = first.subtract(Duration(days: lead));
    // Monday-first short day names in the app language (2 Jan 2023 = Mon).
    final names = [
      for (var i = 0; i < 7; i++)
        DateFormat.E().format(DateTime(2023, 1, 2 + i)).replaceAll('.', '')
    ];
    final weeks =
        ((lead + DateUtils.getDaysInMonth(_month.year, _month.month)) / 7)
            .ceil();

    return MobileCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(children: [
        Row(children: [
          for (final n in names)
            Expanded(
              child: Text(n,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 6),
        for (var w = 0; w < weeks; w++)
          Row(children: [
            for (var d = 0; d < 7; d++)
              Expanded(
                child: _dayCell(start.add(Duration(days: w * 7 + d))),
              ),
          ]),
      ]),
    );
  }

  Widget _dayCell(DateTime day) {
    final inMonth = day.month == _month.month;
    final selected = _expiry != null && DateUtils.isSameDay(day, _expiry);
    return GestureDetector(
      onTap: () => setState(() {
        _expiry = day;
        if (!inMonth) _month = DateTime(day.year, day.month);
      }),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? MobileColors.greenMid : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('${day.day}',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : inMonth
                          ? MobileColors.greenMid
                          : Colors.grey.shade400)),
        ),
      ),
    );
  }

  // ── File card ────────────────────────────────────────────────────────────

  Widget _fileCard(DocumentTypeModel t) {
    final name = _files.isEmpty
        ? context.l10n.uploadNoFileYet
        : _files.length == 1
            ? _files.first.name
            : context.l10n.uploadFileAndMore(_files.first.name, _files.length - 1);
    final ext = _files.isEmpty
        ? 'FILE'
        : _files.first.name.split('.').last.toUpperCase();

    return CustomPaint(
      painter: _DashedBorder(),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _chooseSource,
            child: Container(
              width: 120,
              height: 118,
              decoration: BoxDecoration(
                color: MobileColors.greenSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                Container(
                  height: 34,
                  color: MobileColors.greenMid,
                  alignment: Alignment.center,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.upload, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(_files.isEmpty ? context.l10n.actionUpload : context.l10n.actionChange,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                Expanded(
                  child: Center(
                    child: Text(ext.length > 4 ? 'FILE' : ext,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MobileColors.greenMid)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _files.isEmpty
                          ? MobileColors.muted
                          : MobileColors.ink)),
              const SizedBox(height: 8),
              if (t.hasExpiryDate)
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: context.l10n.uploadExpiryLabel,
                      style: TextStyle(color: MobileColors.greenMid)),
                  TextSpan(
                      text: _expiry == null
                          ? context.l10n.uploadNotSet
                          : _long.format(_expiry!),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _expiry == null
                              ? MobileColors.red
                              : MobileColors.greenMid)),
                ])),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Text(context.l10n.uploadSelectedDocs(_files.length),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (_files.isNotEmpty && !kIsWeb)
                  IconButton(
                    tooltip: context.l10n.actionPreview,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    onPressed: _preview,
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _reviewedField() => MobileCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _reviewed ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            helpText: context.l10n.dateLastReviewed,
          );
          if (d != null) setState(() => _reviewed = d);
        },
        child: Row(children: [
          const Icon(Icons.fact_check_outlined, color: MobileColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _reviewed == null
                  ? context.l10n.dateLastReviewedRequired
                  : context.l10n.lastReviewedOn(_long.format(_reviewed!)),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _reviewed == null
                      ? MobileColors.red
                      : MobileColors.ink),
            ),
          ),
          const Icon(Icons.chevron_right),
        ]),
      );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8A9488)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final r = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(18));
    final path = Path()..addRRect(r);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
