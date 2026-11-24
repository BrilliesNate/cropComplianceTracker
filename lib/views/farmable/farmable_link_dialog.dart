import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/services/farmable_service.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/farmable_models.dart';
import 'package:flutter/material.dart';

/// Admin dialog to link or unlink a Farmable farm to a company.
/// Opens from the Company Management screen.
class FarmableLinkDialog extends StatefulWidget {
  final CompanyModel company;
  final void Function(int? farmId) onSaved;

  const FarmableLinkDialog({
    Key? key,
    required this.company,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<FarmableLinkDialog> createState() => _FarmableLinkDialogState();
}

class _FarmableLinkDialogState extends State<FarmableLinkDialog> {
  final _service = FarmableService();

  List<FarmableLocation> _farms = [];
  // farmId → name of the OTHER company it's already linked to.
  Map<int, String> _linkedElsewhere = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _selected;

  final _filterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.company.farmableLocationId;
    _filterCtrl.addListener(() => setState(() {}));
    _loadFarms();
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getFarms(),
        _loadLinkedMap(),
      ]);
      setState(() {
        _farms = results[0] as List<FarmableLocation>;
        _linkedElsewhere = results[1] as Map<int, String>;
        _loading = false;
      });
    } on FarmableException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not connect to Farmable'; _loading = false; });
    }
  }

  /// Builds a map of farmId → other company's name for every farm already
  /// linked to a DIFFERENT company, so we can lock those to prevent
  /// mis-assigning a farm. Best-effort — a failure here won't block listing.
  Future<Map<int, String>> _loadLinkedMap() async {
    final map = <int, String>{};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .where('farmableLocationId', isNotEqualTo: null)
          .get();
      for (final d in snap.docs) {
        if (d.id == widget.company.id) continue; // ignore this company
        final data = d.data();
        final fid = data['farmableLocationId'];
        if (fid is int) map[fid] = (data['name'] as String?) ?? 'Another company';
      }
    } catch (_) {/* best-effort */}
    return map;
  }

  List<FarmableLocation> get _filtered {
    final q = _filterCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _farms;
    return _farms
        .where((f) => f.displayName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _save() async {
    // Guard: never allow assigning a farm that's already linked elsewhere.
    if (_selected != null && _linkedElsewhere.containsKey(_selected)) {
      setState(() => _error =
          'That farm is already linked to ${_linkedElsewhere[_selected]}. '
          'Unlink it there first.');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.company.id)
          .update({
        'farmableLocationId': _selected,
      });
      widget.onSaved(_selected);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _saving = false; _error = 'Failed to save: $e'; });
    }
  }

  Future<void> _unlink() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unlink Farmable Farm'),
        content: const Text('This will remove the Farmable connection for this company. Farm data will no longer appear on their dashboard.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unlink', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.company.id)
          .update({'farmableLocationId': FieldValue.delete()});
      widget.onSaved(null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _saving = false; _error = 'Failed to unlink: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('FARMABLE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Link Farm',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(widget.company.name,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _farms.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 40),
                    const SizedBox(height: 8),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadFarms,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Farms accessible to Crop Compliance are listed below. Farms '
                  'already linked to another company are locked to prevent '
                  'mis-assigning them.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _filterCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search farms…',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search,
                          size: 18, color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No farms match your search.',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final farm = _filtered[i];
                          final takenBy = _linkedElsewhere[farm.id];
                          final isCurrent =
                              widget.company.farmableLocationId == farm.id;
                          final location = [farm.city, farm.country]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', ');

                          // Locked — already linked to a different company.
                          if (takenBy != null) {
                            return ListTile(
                              enabled: false,
                              leading: Icon(Icons.lock_outline,
                                  size: 20, color: Colors.grey.shade400),
                              title: Text(farm.displayName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500)),
                              subtitle: Text('Already linked to $takenBy',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade400)),
                            );
                          }

                          final isSelected = _selected == farm.id;
                          return RadioListTile<int>(
                            value: farm.id,
                            groupValue: _selected,
                            onChanged: (v) => setState(() => _selected = v),
                            activeColor: primary,
                            title: Text(
                              farm.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              isCurrent
                                  ? 'Currently linked to this company'
                                  : location,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrent
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
              ),
            ],

            if (_error != null && _farms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(_error!,
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade600)),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (widget.company.hasFarmable)
                    TextButton.icon(
                      onPressed: _saving ? null : _unlink,
                      icon: Icon(Icons.link_off,
                          size: 16, color: Colors.red.shade400),
                      label: Text('Unlink',
                          style: TextStyle(color: Colors.red.shade400)),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: (_saving || _selected == null) ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
