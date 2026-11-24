import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'connectivity_service.dart';
import 'upload_outbox.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// A slim status bar for the mobile app:
///  - offline → "You're offline — your work is saved on this phone…"
///  - back online with files still waiting → "Uploading 3 files…"
///  - otherwise nothing at all.
/// Reassures users that working without signal is normal and nothing is lost.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final outbox = UploadOutbox.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.online,
      builder: (_, online, __) => ValueListenableBuilder<int>(
        valueListenable: outbox.pending,
        builder: (_, pending, __) => ValueListenableBuilder<bool>(
          valueListenable: outbox.syncing,
          builder: (_, syncing, __) {
            if (online && pending == 0) return const SizedBox.shrink();

            final String text;
            final IconData icon;
            final Color bg;
            if (!online) {
              icon = Icons.cloud_off_outlined;
              bg = const Color(0xFF455A64);
              text = pending > 0
                  ? context.l10n.offlineWithFiles(pending)
                  : context.l10n.offlineNoFiles;
            } else {
              icon = Icons.cloud_upload_outlined;
              bg = const Color(0xFF2E7D32);
              text = syncing
                  ? context.l10n.offlineUploading(pending)
                  : context.l10n.offlineRetrying(pending);
            }

            return Material(
              color: bg,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Row(children: [
                    if (online && syncing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12.5)),
                    ),
                    if (online && !syncing && pending > 0)
                      TextButton(
                        onPressed: outbox.flush,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(context.l10n.offlineRetryNow),
                      ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


/// Wraps the whole app (MaterialApp.builder): shows [OfflineBanner] along the
/// bottom of every screen when needed. While it's showing, the screen above
/// no longer pads for the phone's bottom inset — the banner does — so
/// nothing is padded twice.
///
/// The widget tree here keeps the SAME shape whether or not the banner shows
/// (only values change). Changing the shape would rebuild the app's Navigator
/// and throw the user back to the first screen every time the signal changed.
class OfflineShell extends StatelessWidget {
  final Widget child;
  const OfflineShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    final outbox = UploadOutbox.instance;
    final mq = MediaQuery.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        ConnectivityService.instance.online,
        outbox.pending,
      ]),
      child: child,
      builder: (context, app) {
        final visible = !ConnectivityService.instance.isOnline ||
            outbox.pending.value > 0;
        return Column(children: [
          Expanded(
            child: MediaQuery(
              data: visible
                  ? mq.copyWith(
                      padding: mq.padding.copyWith(bottom: 0),
                      viewPadding: mq.viewPadding.copyWith(bottom: 0),
                    )
                  : mq,
              child: app!,
            ),
          ),
          const OfflineBanner(), // draws nothing when not needed
        ]);
      },
    );
  }
}
