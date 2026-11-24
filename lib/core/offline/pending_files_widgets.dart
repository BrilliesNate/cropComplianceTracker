import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../models/document_model.dart';
import 'upload_outbox.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Small "uploading" chip for document rows whose files are still on the
/// uploader's phone (saved offline).
class PendingUploadChip extends StatelessWidget {
  final DocumentModel document;
  const PendingUploadChip({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    if (!document.hasPendingFiles) return const SizedBox.shrink();
    final n = document.pendingFiles.length;
    return Tooltip(
      message: context.l10n.pendingSavedOfflineTooltip(n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_upload_outlined,
              size: 13, color: Colors.blueGrey.shade700),
          const SizedBox(width: 4),
          Text(context.l10n.pendingWaitingToUpload,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800)),
        ]),
      ),
    );
  }
}

/// Shown on a document's page while its files are waiting to upload. On the
/// phone that saved them, the local copies can be opened right away.
class PendingFilesPanel extends StatelessWidget {
  final DocumentModel document;
  const PendingFilesPanel({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    if (!document.hasPendingFiles) return const SizedBox.shrink();
    final local = kIsWeb
        ? const <File>[]
        : UploadOutbox.instance.localFilesFor(document.id);
    final n = document.pendingFiles.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_upload_outlined,
                size: 18, color: Colors.blueGrey.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                local.isNotEmpty
                    ? context.l10n.pendingSavedOnThisPhone(n)
                    : context.l10n.pendingUploadingFromOtherPhone(n),
                style: TextStyle(
                    fontSize: 13, color: Colors.blueGrey.shade900),
              ),
            ),
          ]),
          if (local.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final f in local)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  document.pendingFiles.firstWhere(
                      (name) => f.path.endsWith(name),
                      orElse: () => f.path.split(Platform.pathSeparator).last),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: TextButton(
                  onPressed: () => OpenFile.open(f.path),
                  child: Text(context.l10n.commonOpen),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
