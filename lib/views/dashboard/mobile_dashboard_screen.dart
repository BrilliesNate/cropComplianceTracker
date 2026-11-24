import 'package:cropCompliance/views/mobile/mobile_ui.dart';
import 'dart:ui';

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/providers/notification_provider.dart';
import 'package:cropCompliance/core/services/push_notification_service.dart';
import 'package:cropCompliance/views/dashboard/widgets/circle_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:cropCompliance/views/shared/admin_farm_chip.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final docs = Provider.of<DocumentProvider>(context, listen: false);
    final cats = Provider.of<CategoryProvider>(context, listen: false);

    if (auth.currentUser == null) return;

    // Start the notification listener (mobile dashboard doesn't use
    // AppScaffoldWrapper, so we must start it here too).
    Provider.of<NotificationProvider>(context, listen: false)
        .start(auth.currentUser!.id);

    final companyId = auth.effectiveCompany?.id ?? '';

    // ── PERF LOG ─────────────────────────────────────────────────────────
    final total = Stopwatch()..start();
    print('⏱️  [Dashboard] _initData START');

    // Apply package filter immediately — it's synchronous, no network.
    if (auth.effectiveCompany != null) {
      cats.setPackageFilter(auth.effectiveCompany!.packages);
    }

    // Categories are global and don't change between sessions — only
    // fetch them if we don't already have them in memory.
    final needsCatInit = cats.documentTypes.isEmpty;
    print('⏱️  [Dashboard] needsCatInit=$needsCatInit  ' // l10n-ignore: log
        'companyId=$companyId'); // l10n-ignore: log

    // ── Track each call individually so we can see the slowest one ──────
    Future<void> timed(String label, Future<void> Function() fn) async {
      final sw = Stopwatch()..start();
      await fn();
      print('⏱️  [Dashboard] $label: ${sw.elapsedMilliseconds} ms');
    }

    // Fire all network calls in PARALLEL instead of sequentially.
    await Future.wait([
      if (needsCatInit)
        timed('cats.initialize', () => cats.initialize())
      else
        Future.value(),
      timed('docs.refreshForUserContext',
          () => docs.refreshForUserContext(context)),
      if (companyId.isNotEmpty)
        timed('cats.loadCompanyOverrides',
            () => cats.loadCompanyOverrides(companyId))
      else
        Future.value(),
    ]);

    // Apply per-company overrides to docs once everything is loaded.
    if (companyId.isNotEmpty) {
      docs.setDeactivatedDocumentTypeIds(cats.deactivatedDocumentTypeIds);
    }

    print('⏱️  [Dashboard] _initData TOTAL: '
        '${total.elapsedMilliseconds} ms  ' // l10n-ignore: log
        '(docs=${docs.documents.length}, types=${cats.documentTypes.length})'); // l10n-ignore: log
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final docs = Provider.of<DocumentProvider>(context);
    final cats = Provider.of<CategoryProvider>(context);

    // Robustly bind the notification listener to the user — start() is
    // idempotent, so this is safe to call on every build and guarantees the
    // listener runs even if _initData ran before auth resolved.
    final uid = auth.currentUser?.id;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false).start(uid);
          PushNotificationService.instance.init(uid);
        }
      });
    }

    final isLoading = docs.isLoading || cats.isLoading;
    // We consider the dashboard "ready" once any data has arrived from the
    // providers — even an empty result. Until then, do NOT animate the gauge
    // or render real stat numbers (which would just be 0/0).
    final isReady = !isLoading &&
        (docs.documentTypes.isNotEmpty || docs.documents.isNotEmpty);

    final stats = docs.getComplianceStatsForPackages(auth.effectivePackages);
    final totalDocTypes = stats['totalDocTypes'] as int;
    final approvedDocs = stats['approvedDocs'] as int;
    final uploadedDocs = stats['uploadedDocs'] as int;
    final pendingDocs = stats['pendingDocs'] as int;
    final completionPercentage = stats['completionPercentage'] as String;

    final screenHeight = MediaQuery.of(context).size.height;
    final topPad = MediaQuery.of(context).padding.top;

    // ── Layer positions — adjust freely ───────────────────────────────────
    // How far down the body card starts (top of card with rounded corners).
    // Anything above this is just hero; the card sits ON TOP of the hero.
    final bodyTop = (screenHeight * 0.40).clamp(300.0, 400.0);

    // No blank-screen gate. Render the layout immediately and let the
    // gauge animate from 0 → target once data arrives. Documents/comments
    // show subtle skeletons during loading and fade in when ready.

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Hero (always rendered — gauge animates on data) ────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bodyTop + 32,
            child: _buildHero(
              context,
              auth,
              topPad,
              bodyTop,
              completionPercentage,
              approvedDocs,
              uploadedDocs,
              pendingDocs,
              totalDocTypes,
              isReady,
            ),
          ),

          // ── Layer 2: Body card ───────────────────────────────────────────
          Positioned(
            top: bodyTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8F1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: _buildScrollContent(context, docs, isLoading),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNav(current: MobileTab.home),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(
    BuildContext context,
    AuthProvider auth,
    double topPad,
    double heroHeight,
    String completionPercentage,
    int approvedDocs,
    int uploadedDocs,
    int pendingDocs,
    int totalDocTypes,
    bool isReady,
  ) {
    final pctFraction = (double.tryParse(completionPercentage) ?? 0) / 100.0;
    final companyName =
        auth.effectiveCompany?.name ??
        auth.currentUser?.name ??
        context.l10n.dashboardTitle;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background image (zoomed in, cropped from top)
        Positioned.fill(
          child: ClipRect(
            child: Transform.scale(
              scale: 1.35,
              alignment: const Alignment(0, -0.4),
              child: Image.asset(
                'assets/images/image1-4.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // ── Location pill (top) — glass effect. Admins with a farm open get
        // the orange farm badge instead: tap the name to switch, × for all
        // farms (the same badge sits in every page's top bar).
        Positioned(
          top: topPad + 18,
          left: 16,
          right: 78,
          child: adminFarmOpen(auth)
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: AdminFarmChip(),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.35), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),

        // ── Profile avatar (top right) — with notification badge ───────────
        Positioned(
          top: topPad + 18,
          right: 16,
          child: Consumer<NotificationProvider>(
            builder: (context, notif, _) {
              final count = notif.unreadCount;
              return GestureDetector(
                onTap: () => Navigator.of(context)
                    .pushNamed(RouteConstants.notifications),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile_placeholder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF2E7D32),
                            child: const Center(
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Side icon pill (under avatar) ───────────────────────────────────
        Positioned(
          top: topPad + 60,
          right: 20,
          child: Container(
            width: 26,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7B5C).withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.40), width: 0.6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNotificationSideIcon(context),
                const SizedBox(height: 10),
                _sideIcon(Icons.settings_outlined),
                const SizedBox(height: 10),
                _sideIcon(Icons.bookmark_outline),
                const SizedBox(height: 10),
                _sideIcon(Icons.person_outline),
              ],
            ),
          ),
        ),

        // ── Centered gauge ──────────────────────────────────────────────────
        Positioned(
          top: topPad + 102,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 140,
            child: Center(
              child: SizedBox(
                width: 230,
                height: 140,
                child: _AnimatedGauge(
                  target: pctFraction,
                  isReady: isReady,
                ),
              ),
            ),
          ),
        ),

        // ── KPI stats row at bottom of hero ─────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _kpiStat(context.l10n.kpiCompletionRate,
                  isReady ? '$approvedDocs/$totalDocTypes' : null),
              _kpiStat(context.l10n.kpiApprovalRate,
                  isReady ? '$approvedDocs/$uploadedDocs' : null),
              _kpiStat(context.l10n.kpiPendingReview,
                  isReady ? '$pendingDocs' : null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sideIcon(IconData icon, {bool active = false}) {
    if (active) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications,
            color: Color(0xFF2E7D32), size: 12),
      );
    }
    return Icon(icon, color: Colors.white, size: 14);
  }

  /// Notification bell in the hero side-pill — tappable, with an unread badge.
  Widget _buildNotificationSideIcon(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notif, _) {
        final count = notif.unreadCount;
        return GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(RouteConstants.notifications),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications,
                  color: count > 0 ? const Color(0xFF2E7D32) : Colors.white,
                  size: count > 0 ? 12 : 14,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiStat(String label, String? value) {
    final valueChild = value == null
        ? _Pulse(
            key: const ValueKey('skeleton'),
            child: Container(
              width: 38,
              height: 16,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        : Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1)),
              ],
            ),
          );

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: valueChild,
          ),
        ],
      ),
    );
  }

  // ── Scrollable content ────────────────────────────────────────────────────

  Widget _buildScrollContent(
      BuildContext context, DocumentProvider docs, bool isLoading) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      children: [
        _buildDocumentsStrip(context, docs, isLoading),
        const SizedBox(height: 18),
        _buildCommentSection(context, docs, isLoading),
      ],
    );
  }

  // ── Documents strip ───────────────────────────────────────────────────────

  Widget _buildDocumentsStrip(
      BuildContext context, DocumentProvider docs, bool isLoading) {
    final activeIds = docs.documentTypes.map((dt) => dt.id).toSet();
    final allDocs = docs.documents
        .where((d) => activeIds.contains(d.documentTypeId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final Widget content;
    if (isLoading && allDocs.isEmpty) {
      // Skeleton placeholders — same shape as real cards.
      content = ListView.separated(
        key: const ValueKey('docs-skeleton'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const _DocCardSkeleton(),
      );
    } else if (allDocs.isEmpty) {
      content = Center(
        key: const ValueKey('docs-empty'),
        child: Text(context.l10n.docsNoneYet,
            style: TextStyle(color: Colors.grey)),
      );
    } else {
      content = ListView.separated(
        key: const ValueKey('docs-data'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allDocs.take(12).length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildDocCard(context, allDocs[i], docs),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          context.l10n.documentsTitle,
          () => Navigator.of(context).pushNamed(RouteConstants.auditTracker),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              // New child (real data) slides in from the right.
              // Outgoing child (skeleton) just fades — no slide — so the
              // two don't overlap awkwardly.
              if (child.key == const ValueKey('docs-data')) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.25, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              }
              return FadeTransition(opacity: animation, child: child);
            },
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildDocCard(
      BuildContext context, DocumentModel doc, DocumentProvider docs) {
    final isApproved = doc.status == DocumentStatus.APPROVED;
    final isRejected = doc.status == DocumentStatus.REJECTED;

    String typeName = context.l10n.documentLabel;
    try {
      typeName = docs.documentTypes
          .firstWhere((dt) => dt.id == doc.documentTypeId)
          .name;
    } catch (_) {}

    final Color accent = isApproved
        ? const Color(0xFF2E7D32)
        : isRejected
            ? const Color(0xFFE6A100)
            : const Color(0xFFE6A100);

    final Color bg = isApproved
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF6D8);

    final IconData statusIcon =
        isApproved ? Icons.check_circle : Icons.warning_amber_rounded;
    final String statusLabel =
        isApproved
            ? context.l10n.statusApproved
            : isRejected
                ? context.l10n.statusRejected
                : context.l10n.statusPending;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        RouteConstants.documentDetail,
        arguments: {'documentId': doc.id},
      ),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Card split into top (solid accent) and bottom (30% accent)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 68,
                height: 72,
                child: Column(
                  children: [
                    // ── Top section: solid primary color ────────────────
                    Container(
                      height: 22,
                      width: double.infinity,
                      color: accent,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Bottom section: primary at 30% opacity ──────────
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: accent.withOpacity(0.30),
                        alignment: Alignment.center,
                        child: Icon(Icons.picture_as_pdf_outlined,
                            size: 26, color: accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Document name — sits OUTSIDE the card
            Text(
              typeName,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Comment section ───────────────────────────────────────────────────────

  Widget _buildCommentSection(
      BuildContext context, DocumentProvider docs, bool isLoading) {
    final primary = Theme.of(context).primaryColor;

    final rejected = docs.documents
        .where((d) => d.isRejected && d.comments.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final DocumentModel? rejectedDoc =
        rejected.isNotEmpty ? rejected.first : null;

    final Widget body;
    if (isLoading && docs.documents.isEmpty) {
      body = const _CommentCardSkeleton(key: ValueKey('comment-skeleton'));
    } else if (rejectedDoc == null) {
      body = KeyedSubtree(
        key: const ValueKey('comment-ok'),
        child: _buildNoCommentsCard(primary),
      );
    } else {
      body = KeyedSubtree(
        key: ValueKey('comment-${rejectedDoc.id}'),
        child: _buildCommentCard(context, rejectedDoc, docs, primary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          context.l10n.dashboardDocumentComments,
          () => Navigator.of(context).pushNamed(RouteConstants.auditTracker),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              // Real comment card slides UP from the bottom.
              // Outgoing skeleton just fades.
              final isIncoming = child.key != const ValueKey('comment-skeleton');
              if (isIncoming) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              }
              return FadeTransition(opacity: animation, child: child);
            },
            child: body,
          ),
        ),
      ],
    );
  }

  Widget _buildNoCommentsCard(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 40, color: Colors.green.shade400),
          const SizedBox(height: 10),
          Text(context.l10n.dashboardAllGood,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, DocumentModel doc,
      DocumentProvider docs, Color primary) {
    String typeName = context.l10n.documentLabel;
    try {
      typeName =
          docs.documentTypes.firstWhere((dt) => dt.id == doc.documentTypeId).name;
    } catch (_) {}

    final comments = List.of(doc.comments)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestComment = comments.first;
    final rejectedDate = DateFormat('d MMM yyyy').format(doc.updatedAt);

    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                _commentIcon(Icons.chat_bubble_outline),
                const SizedBox(width: 12),
                _commentVertLine(),
                const SizedBox(width: 12),
                _commentIcon(Icons.picture_as_pdf_outlined),
                const SizedBox(width: 12),
                _commentVertLine(),
                const SizedBox(width: 12),
                _commentIcon(Icons.image_outlined),
                const SizedBox(width: 12),
                _commentVertLine(),
                const SizedBox(width: 12),
                _commentIcon(Icons.share_outlined),
              ],
            ),
          ),

          // Document name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              typeName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),

          // Comment text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              latestComment.text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.88), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 18),

          // Status + Resubmit row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  context.l10n.rejectedOnDate(rejectedDate),
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteConstants.documentUpload,
                    arguments: {
                      'categoryId': doc.categoryId,
                      'documentTypeId': doc.documentTypeId,
                      'existingDocumentId': doc.id,
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      context.l10n.actionResubmit,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentIcon(IconData icon) =>
      Icon(icon, color: Colors.white.withOpacity(0.80), size: 20);

  Widget _commentVertLine() =>
      Container(width: 1, height: 20, color: Colors.white.withOpacity(0.30));

  // ── Section header ────────────────────────────────────────────────────────

  Widget _sectionHeader(
      BuildContext context, String title, VoidCallback onViewAll) {
    final primary = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: onViewAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.actionViewAll,
                    style: TextStyle(
                        color: primary, fontWeight: FontWeight.w600, fontSize: 13)),
                Icon(Icons.chevron_right, color: primary, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation pill ────────────────────────────────────────────────

}

// ── Skeleton placeholders ────────────────────────────────────────────────────
//
// Subtle pulse — feels like the layout is "warming up", not loading.

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({super.key, required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Opacity(
          opacity: 0.55 + (_ctrl.value * 0.30),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DocCardSkeleton extends StatelessWidget {
  const _DocCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E8E0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E8E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E8E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCardSkeleton extends StatelessWidget {
  const _CommentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E8E0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Animated gauge ───────────────────────────────────────────────────────────
//
// Two-phase loading animation:
//   1. Fills from 0% up to 100%      (~900ms, ease-out)
//   2. Settles down to the target %  (~700ms, ease-in-out)
// The percentage label tracks the same animated value.

class _AnimatedGauge extends StatefulWidget {
  final double target; // 0.0 – 1.0
  final bool isReady; // only animate when data is in
  const _AnimatedGauge({required this.target, required this.isReady});

  @override
  State<_AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<_AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _gaugeAnim;
  late Animation<double> _numberAnim;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _buildAnims();
    if (widget.isReady) {
      _hasAnimated = true;
      _ctrl.forward();
    }
  }

  void _buildAnims() {
    final t = widget.target.clamp(0.0, 1.0);

    _gaugeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 9,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: t)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 7,
      ),
    ]).animate(_ctrl);

    _numberAnim = Tween<double>(begin: 0.0, end: t)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl);
  }

  @override
  void didUpdateWidget(covariant _AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // First time data arrives → run the animation once.
    if (!_hasAnimated && widget.isReady) {
      _hasAnimated = true;
      _buildAnims();
      _ctrl
        ..reset()
        ..forward();
    }
    // Already animated, but target changed (e.g. user added a payslip) →
    // smoothly tween from current value to the new target. No full reset.
    else if (_hasAnimated && oldWidget.target != widget.target) {
      final currentG = _gaugeAnim.value;
      final currentN = _numberAnim.value;
      final t = widget.target.clamp(0.0, 1.0);
      _gaugeAnim = Tween<double>(begin: currentG, end: t)
          .chain(CurveTween(curve: Curves.easeInOutCubic))
          .animate(_ctrl);
      _numberAnim = Tween<double>(begin: currentN, end: t)
          .chain(CurveTween(curve: Curves.easeInOutCubic))
          .animate(_ctrl);
      _ctrl
        ..reset()
        ..animateTo(1.0, duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final gaugeValue =
            _hasAnimated ? _gaugeAnim.value.clamp(0.0, 1.0) : 0.0;
        final numberValue =
            _hasAnimated ? _numberAnim.value.clamp(0.0, 1.0) : 0.0;
        return CustomPaint(
          painter: ThickLineSemiCircleGauge(
            percentage: gaugeValue,
            baseColor: Colors.white.withOpacity(0.45),
            progressColor: const Color(0xFF2E7D32),
            lineCount: 22,
            dashLength: 34,
            dashWidth: 7,
            innerWidth: 6,
            radius: 78,
            startFromLeft: true,
            strokeCap: StrokeCap.butt,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _hasAnimated
                  ? Text(
                      '${(numberValue * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
