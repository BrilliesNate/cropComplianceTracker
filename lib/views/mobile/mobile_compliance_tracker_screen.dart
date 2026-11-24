import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/utils/data_bootstrap.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'compliance_journey.dart';
import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Compliance Tracker for phones: the farm's progress as a journey —
/// what's behind you, what to do right now, what's in front of you — with
/// one big button for the next upload.
class MobileComplianceTrackerScreen extends StatefulWidget {
  const MobileComplianceTrackerScreen({super.key});

  @override
  State<MobileComplianceTrackerScreen> createState() =>
      _MobileComplianceTrackerScreenState();
}

class _MobileComplianceTrackerScreenState
    extends State<MobileComplianceTrackerScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ready = isCompanyDataWarm(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCompanyData(context);
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final docs = Provider.of<DocumentProvider>(context);
    final packages = auth.effectivePackages;

    final journey = buildJourney(
      categories: docs.getCategoriesForPackages(packages),
      types: docs.getDocumentTypesForPackages(packages),
      documents: docs.documents,
    );

    return Scaffold(
      backgroundColor: MobileColors.page,
      body: Column(children: [
        MobileHeader(title: context.l10n.trackerTitle),
        Expanded(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => loadCompanyData(context),
                  child: _content(context, journey),
                ),
        ),
      ]),
      bottomNavigationBar:
          const MobileBottomNav(current: MobileTab.home, atTabRoot: false),
    );
  }

  Widget _content(BuildContext context, ComplianceJourney j) {
    if (j.total == 0) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: 60),
          Icon(Icons.fact_check_outlined, size: 56, color: MobileColors.muted),
          SizedBox(height: 12),
          Text(
            context.l10n.trackerNoStandards,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: MobileColors.ink),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.trackerAskAdmin,
            textAlign: TextAlign.center,
            style: TextStyle(color: MobileColors.muted),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 20),
        _progressRow(j),
        const SizedBox(height: 4),
        _landscape(j.fraction),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7FBF7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _behind(j),
                const Divider(height: 32),
                _rightNow(j),
                const Divider(height: 32),
                _ahead(j),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: j.now == null
                      ? MobilePrimaryButton(
                          label: context.l10n.trackerOpenChecklist,
                          icon: Icons.folder_open,
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(RouteConstants.auditIndex),
                        )
                      : MobilePrimaryButton(
                          label: _actionLabel(j.now!),
                          icon: Icons.cloud_upload_outlined,
                          onPressed: () => _openStep(j.now!),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Progress row with the 7-dot stepper ──────────────────────────────────

  Widget _progressRow(ComplianceJourney j) {
    const dots = 7;
    final here = (j.fraction * (dots - 1)).round().clamp(0, dots - 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.l10n.trackerOverallProgress,
              style: TextStyle(fontSize: 14, color: MobileColors.ink)),
          Text('${j.percent}%',
              style: const TextStyle(
                  fontSize: 44,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: MobileColors.greenMid)),
          const Text('complete',
              style: TextStyle(fontSize: 14, color: MobileColors.ink)),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final gap = c.maxWidth / (dots - 1);
            return SizedBox(
              height: 70,
              child: Stack(clipBehavior: Clip.none, children: [
                // Line
                Positioned(
                  left: 0,
                  right: 0,
                  top: 50,
                  child: Row(children: [
                    Expanded(
                      flex: here,
                      child: Container(height: 3, color: MobileColors.greenMid),
                    ),
                    Expanded(
                      flex: dots - 1 - here,
                      child: Container(height: 3, color: Colors.grey.shade300),
                    ),
                  ]),
                ),
                for (var i = 0; i < dots; i++)
                  Positioned(
                    left: (i * gap) - (i == here ? 13 : 10),
                    top: i == here ? 38 : 41,
                    child: _dot(done: i < here, current: i == here),
                  ),
                // "You are here" bubble
                Positioned(
                  left: (here * gap - 44).clamp(-20, c.maxWidth - 70),
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: MobileColors.greenMid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(context.l10n.trackerYouAreHere,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            );
          }),
        ),
      ]),
    );
  }

  Widget _dot({required bool done, required bool current}) {
    if (current) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
            color: MobileColors.greenMid, shape: BoxShape.circle),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: done ? MobileColors.greenMid : const Color(0xFFDDE2DC),
        shape: BoxShape.circle,
        border: Border.all(
            color: done ? Colors.white : Colors.grey.shade400, width: 2),
      ),
      child: done
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }

  // ── Landscape: colour up to the progress, greyscale after ────────────────

  static const _grey = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  Widget _landscape(double fraction) {
    const h = 170.0;
    Widget photo() => Image.asset('assets/images/image1-4.webp',
        height: h, fit: BoxFit.cover, alignment: const Alignment(0, 0.6));
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(children: [
          // The whole scene in greyscale (the road still ahead)…
          SizedBox(
              width: w,
              height: h,
              child: ColorFiltered(colorFilter: _grey, child: photo())),
          // …with full colour up to how far the farm has come.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: w * fraction.clamp(0.0, 1.0),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: w,
                maxWidth: w,
                child: SizedBox(width: w, height: h, child: photo()),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  // ── Behind you / Right now / In front of you ─────────────────────────────

  Widget _section({
    required String title,
    required String count,
    required Color countColor,
    required List<Widget> items,
  }) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 120,
        child: Padding(
          padding: const EdgeInsets.only(left: 24, top: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            Text(count,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: countColor)),
          ]),
        ),
      ),
      Expanded(child: Column(children: items)),
    ]);
  }

  Widget _timelineRow({
    required Widget marker,
    required String text,
    TextStyle? style,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 9, 20, 9),
        child: Row(children: [
          SizedBox(width: 30, child: Center(child: marker)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style ??
                    const TextStyle(fontSize: 15, color: MobileColors.ink)),
          ),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  Widget _behind(ComplianceJourney j) {
    final shown = j.done.reversed.take(4).toList().reversed.toList();
    final more = j.done.length - shown.length;
    return _section(
      title: context.l10n.trackerBehindYou,
      count: context.l10n.trackerDoneCount(j.done.length),
      countColor: MobileColors.greenMid,
      items: [
        if (j.done.isEmpty)
          _timelineRow(
            marker: Icon(Icons.flag_outlined, color: Colors.grey.shade500),
            text: context.l10n.trackerFirstUploadHere,
            style: const TextStyle(color: MobileColors.muted),
          ),
        for (final s in shown)
          _timelineRow(
            marker: const Icon(Icons.check_circle,
                color: MobileColors.greenMid, size: 26),
            text: s.type.name,
            onTap: () => _openDocument(s),
          ),
        if (more > 0)
          _timelineRow(
            marker: const Icon(Icons.circle,
                size: 10, color: MobileColors.greenMid),
            text: context.l10n.trackerAndMore(more),
            style: const TextStyle(fontSize: 15, color: MobileColors.muted),
            onTap: _openChecklist,
          ),
      ],
    );
  }

  Widget _rightNow(ComplianceJourney j) {
    final s = j.now;
    if (s == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(children: [
          const Icon(Icons.celebration_outlined,
              color: MobileColors.greenMid, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.l10n.trackerAllCaughtUp,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      );
    }
    final pill = switch (s.status) {
      TypeStatus.rejected => StatusPill(
          label: context.l10n.statusRejected,
          fg: MobileColors.red,
          bg: MobileColors.redTint),
      TypeStatus.expired => StatusPill(
          label: context.l10n.statusExpired,
          fg: Color(0xFF8A5A00),
          bg: MobileColors.amberTint),
      _ => StatusPill(
          label: context.l10n.statusRequired,
          fg: MobileColors.green,
          bg: MobileColors.greenSoft),
    };
    final hint = switch (s.status) {
      TypeStatus.rejected => s.latest?.rejectionReason?.isNotEmpty == true
          ? context.l10n.trackerHintRejectedReason(s.latest!.rejectionReason!)
          : context.l10n.trackerHintRejected,
      TypeStatus.expired => context.l10n.trackerHintExpired,
      _ => context.l10n
          .trackerHintUpload(s.type.name.toLowerCase(), s.category.name),
    };
    return InkWell(
      onTap: () => _openStep(s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(84, 4, 20, 4),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: -64,
            top: 4,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: MobileColors.greenMid, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 26),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(context.l10n.trackerRightNow,
                    style: TextStyle(
                        fontSize: 14, color: MobileColors.greenMid)),
              ),
              pill,
            ]),
            const SizedBox(height: 4),
            Text(s.type.name,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: MobileColors.ink)),
            const SizedBox(height: 4),
            Text(hint,
                style: const TextStyle(
                    fontSize: 14, color: MobileColors.muted, height: 1.3)),
          ]),
        ]),
      ),
    );
  }

  Widget _ahead(ComplianceJourney j) {
    final shown = j.ahead.take(3).toList();
    final more = j.ahead.length - shown.length;
    return _section(
      title: context.l10n.trackerInFront,
      count: context.l10n.trackerToGo(j.ahead.length),
      countColor: MobileColors.muted,
      items: [
        if (j.ahead.isEmpty)
          _timelineRow(
            marker: Icon(Icons.flag, color: Colors.grey.shade400),
            text: j.now == null
                ? context.l10n.trackerNothingLeft
                : context.l10n.trackerLastOne,
            style: const TextStyle(color: MobileColors.muted),
          ),
        for (var i = 0; i < shown.length; i++)
          _timelineRow(
            marker: CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFDDE2DC),
              child: Text('${i + 2}',
                  style: const TextStyle(
                      fontSize: 12, color: MobileColors.muted)),
            ),
            text: shown[i].type.name,
            style: const TextStyle(fontSize: 15, color: Color(0xFF5E6B5C)),
            trailing: shown[i].status.needsAction
                ? StatusPill(
                    label: shown[i].status.label(context.l10n),
                    fg: MobileColors.red,
                    bg: MobileColors.redTint)
                : null,
            onTap: () => _openStep(shown[i]),
          ),
        if (more > 0)
          _timelineRow(
            marker: Icon(Icons.circle, size: 10, color: Colors.grey.shade400),
            text: context.l10n.trackerAndMore(more),
            style: const TextStyle(fontSize: 15, color: MobileColors.muted),
            onTap: _openChecklist,
          ),
      ],
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  String _actionLabel(JourneyStep s) {
    final l10n = context.l10n;
    return switch (s.status) {
      TypeStatus.rejected => l10n.actionResubmitType(s.type.name),
      TypeStatus.expired => l10n.actionRenewType(s.type.name),
      _ => l10n.actionUploadType(s.type.name),
    };
  }

  void _openStep(JourneyStep s) {
    if (!s.type.isUploadable) {
      Navigator.of(context).pushNamed(RouteConstants.documentForm, arguments: {
        'categoryId': s.category.id,
        'documentTypeId': s.type.id,
      });
      return;
    }
    Navigator.of(context).pushNamed(RouteConstants.documentUpload, arguments: {
      'categoryId': s.category.id,
      'documentTypeId': s.type.id,
      if (s.status.needsAction && s.latest != null)
        'existingDocumentId': s.latest!.id,
    });
  }

  void _openDocument(JourneyStep s) {
    if (s.latest == null) return;
    Navigator.of(context).pushNamed(RouteConstants.documentDetail,
        arguments: {'documentId': s.latest!.id});
  }

  void _openChecklist() =>
      Navigator.of(context).pushReplacementNamed(RouteConstants.auditIndex);
}
