import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:flutter/material.dart';

import 'mobile_ui.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

/// Bottom sheet listing every farm (admins), with search. Returns the farm
/// picked, or null. Used wherever an admin needs a farm open before a screen
/// makes sense (Audit checklist, Payslips) — instead of a dead end, they pick
/// one right there.
Future<CompanyModel?> showFarmPickerSheet(
  BuildContext context, {
  String? title,
  String? message,
  String? currentId,
}) {
  // Web / tablet: a normal dialog. Phones: a bottom sheet.
  if (!isPhoneWidth(MediaQuery.of(context).size.width)) {
    return showDialog<CompanyModel>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Text(title ?? context.l10n.farmChooseAFarm,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: context.l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ]),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(message,
                      style: TextStyle(color: Colors.grey.shade700)),
                ),
              ),
            Flexible(
              child: SizedBox(
                height: 480,
                child: FarmPickerList(
                  currentId: currentId,
                  onPick: (c) => Navigator.of(ctx).pop(c),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
  return showModalBottomSheet<CompanyModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _FarmPicker(
      title: title ?? context.l10n.farmChooseAFarm,
      message: message,
      currentId: currentId,
    ),
  );
}

class _FarmPicker extends StatefulWidget {
  final String title;
  final String? message;
  final String? currentId;
  const _FarmPicker({required this.title, this.message, this.currentId});

  @override
  State<_FarmPicker> createState() => _FarmPickerState();
}

class _FarmPickerState extends State<_FarmPicker> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(widget.title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          if (widget.message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(widget.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MobileColors.muted)),
            ),
          Expanded(
            child: FarmPickerList(
              currentId: widget.currentId,
              onPick: (c) => Navigator.of(context).pop(c),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Search box + list of every farm. Used by the bottom sheet above and by the
/// "Which farm?" page an admin sees when opening a farm page with no farm open.
class FarmPickerList extends StatefulWidget {
  final ValueChanged<CompanyModel> onPick;
  final String? currentId;
  const FarmPickerList({super.key, required this.onPick, this.currentId});

  @override
  State<FarmPickerList> createState() => _FarmPickerListState();
}

class _FarmPickerListState extends State<FarmPickerList> {
  late Future<List<CompanyModel>> _farms = _load();
  String _query = '';

  // Firestore answers from its cache when offline, so this works without
  // signal as long as the farms were loaded once before.
  static Future<List<CompanyModel>> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .orderBy('name')
        .get();
    return snap.docs.map((d) => CompanyModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: context.l10n.farmSearchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0xFFF0F2F0),
            isDense: true,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<CompanyModel>>(
          future: _farms,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 40, color: MobileColors.muted),
                    const SizedBox(height: 8),
                    Text(context.l10n.farmLoadFailed,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _farms = _load()),
                      child: Text(context.l10n.commonRetry),
                    ),
                  ]),
                ),
              );
            }
            final farms = (snap.data ?? const <CompanyModel>[])
                .where((c) =>
                    _query.isEmpty ||
                    c.name.toLowerCase().contains(_query) ||
                    c.address.toLowerCase().contains(_query))
                .toList();
            if (farms.isEmpty) {
              return Center(
                  child: Text(context.l10n.farmNoSearchMatch,
                      style: const TextStyle(color: MobileColors.muted)));
            }
            return ListView.builder(
              itemCount: farms.length,
              itemBuilder: (context, i) {
                final c = farms[i];
                final current = c.id == widget.currentId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MobileColors.greenSoft,
                    child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: MobileColors.green,
                            fontWeight: FontWeight.w800)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: c.address.isEmpty
                      ? null
                      : Text(c.address,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: current
                      ? const Icon(Icons.check_circle,
                          color: MobileColors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () => widget.onPick(c),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
