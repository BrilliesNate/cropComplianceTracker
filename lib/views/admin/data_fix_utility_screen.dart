import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/fairtrade_seed_data.dart';
import 'package:cropCompliance/siza_environmental_seed_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Counts of data attached to one company, used by the duplicate inspector.
class _DupCompany {
  final CompanyModel company;
  final int users;
  final int employees;
  final int payslips;
  final int documents;
  const _DupCompany({
    required this.company,
    required this.users,
    required this.employees,
    required this.payslips,
    required this.documents,
  });
  int get total => users + employees + payslips + documents;
}

/// A set of companies that share the same (case-insensitive) name.
class _DupGroup {
  final String name;
  final List<_DupCompany> companies;
  const _DupGroup({required this.name, required this.companies});
}

/// Lightweight document row used by the superseded scan.
class _DocLite {
  final String id;
  final String companyId;
  final String typeId;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final bool isSuperseded;
  const _DocLite({
    required this.id,
    required this.companyId,
    required this.typeId,
    required this.createdAt,
    required this.expiryDate,
    required this.isSuperseded,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
}

/// A group of same-type documents for one company where older versions should
/// be marked superseded (keep the newest, supersede the rest).
class _SupGroup {
  final String companyName;
  final String docTypeName;
  final String keeperId;
  final List<String> toSupersede;
  const _SupGroup({
    required this.companyName,
    required this.docTypeName,
    required this.keeperId,
    required this.toSupersede,
  });
}

/// TEMPORARY ADMIN UTILITY SCREEN
/// Use this to fix the 75 documents that were uploaded to the wrong company.
///
/// STEPS:
/// 1. Select the SOURCE company (wrong company where docs ended up)
/// 2. Select the TARGET company (correct company where docs should be)
/// 3. Preview the documents that will be moved
/// 4. Confirm the move
///
/// After fixing the data, you can remove this screen from the app.

class DataFixUtilityScreen extends StatefulWidget {
  const DataFixUtilityScreen({Key? key}) : super(key: key);

  @override
  State<DataFixUtilityScreen> createState() => _DataFixUtilityScreenState();
}

class _DataFixUtilityScreenState extends State<DataFixUtilityScreen> {
  List<CompanyModel> _companies = [];
  bool _isLoadingCompanies = true;

  CompanyModel? _sourceCompany;
  CompanyModel? _targetCompany;

  List<DocumentModel> _sourceDocuments = [];
  Set<String> _selectedDocIds = {};
  bool _isLoadingDocuments = false;
  bool _isProcessing = false;

  String? _error;
  String? _successMessage;

  // ── Duplicate company inspector state ──────────────────────────────────────
  bool _isScanning = false;
  bool _hasScanned = false;
  List<_DupGroup> _dupGroups = [];

  // ── Superseded document cleanup state ──────────────────────────────────────
  bool _isScanningSup = false;
  bool _hasScannedSup = false;
  List<_SupGroup> _supGroups = [];
  int _supTotal = 0;

  // ── Uploader-name backfill state ───────────────────────────────────────────
  bool _isScanningUp = false;
  bool _hasScannedUp = false;
  Map<String, String> _upUpdates = {}; // documentId → uploader name
  int _upUnresolved = 0; // uploader account no longer exists

  // ── Stray expiry date cleanup state ────────────────────────────────────────
  bool _isScanningExp = false;
  bool _hasScannedExp = false;
  List<String> _expAutoIds = []; // "upload day + 365" stamps — safe to clear
  List<String> _expOtherIds = []; // other dates on no-expiry types
  int _expAutoExpired = 0; // how many of the auto-stamped currently read "Expired"
  Map<String, int> _expAutoByType = {};

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('name')
          .get();

      setState(() {
        _companies = snapshot.docs.map((doc) {
          return CompanyModel.fromMap(doc.data(), doc.id);
        }).toList();
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load companies: $e';
        _isLoadingCompanies = false;
      });
    }
  }

  Future<void> _loadSourceDocuments() async {
    if (_sourceCompany == null) return;

    setState(() {
      _isLoadingDocuments = true;
      _sourceDocuments = [];
      _selectedDocIds = {};
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('companyId', isEqualTo: _sourceCompany!.id)
          .get();

      setState(() {
        _sourceDocuments = snapshot.docs.map((doc) {
          final data = doc.data();
          return DocumentModel.fromMap(
            data,
            doc.id,
            [], // Empty signatures - not needed for this utility
            [], // Empty comments - not needed for this utility
          );
        }).toList();

        // Sort by creation date, newest first
        _sourceDocuments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _isLoadingDocuments = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load documents: $e';
        _isLoadingDocuments = false;
      });
    }
  }

  Future<void> _moveSelectedDocuments() async {
    if (_targetCompany == null || _selectedDocIds.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Move'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to move ${_selectedDocIds.length} documents:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FROM: ${_sourceCompany!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('TO: ${_targetCompany!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will update the companyId field for all selected documents. '
                  'This action can be reversed by moving them back.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('MOVE DOCUMENTS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      int successCount = 0;
      int failCount = 0;

      // Get a batch reference for better performance
      final batch = FirebaseFirestore.instance.batch();

      for (String docId in _selectedDocIds) {
        final docRef = FirebaseFirestore.instance.collection('documents').doc(docId);
        batch.update(docRef, {
          'companyId': _targetCompany!.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();
      successCount = _selectedDocIds.length;

      setState(() {
        _successMessage = 'Successfully moved $successCount documents to ${_targetCompany!.name}';
        _isProcessing = false;
      });

      // Reload to show updated state
      await _loadSourceDocuments();
    } catch (e) {
      setState(() {
        _error = 'Error moving documents: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _deleteSelectedDocuments() async {
    if (_selectedDocIds.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to PERMANENTLY DELETE ${_selectedDocIds.length} documents.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '⚠️ This action CANNOT be undone!\n\n'
                    'Documents and their files will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      int successCount = 0;

      // Delete documents one by one (to also clean up storage)
      for (String docId in _selectedDocIds) {
        try {
          // Get document first to get file URLs
          final docSnapshot = await FirebaseFirestore.instance
              .collection('documents')
              .doc(docId)
              .get();

          if (docSnapshot.exists) {
            // Delete from Firestore
            await FirebaseFirestore.instance
                .collection('documents')
                .doc(docId)
                .delete();
            successCount++;
          }
        } catch (e) {
          print('Error deleting document $docId: $e');
        }
      }

      setState(() {
        _successMessage = 'Successfully deleted $successCount documents';
        _isProcessing = false;
      });

      // Reload to show updated state
      await _loadSourceDocuments();
    } catch (e) {
      setState(() {
        _error = 'Error deleting documents: $e';
        _isProcessing = false;
      });
    }
  }

  // ── Duplicate company inspector / merge ────────────────────────────────────

  Future<int> _countByCompany(String collection, String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.docs.length;
  }

  Future<void> _scanDuplicates() async {
    setState(() {
      _isScanning = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('name')
          .get();
      final companies =
          snap.docs.map((d) => CompanyModel.fromMap(d.data(), d.id)).toList();

      final byName = <String, List<CompanyModel>>{};
      for (final c in companies) {
        byName.putIfAbsent(c.name.trim().toLowerCase(), () => []).add(c);
      }

      final groups = <_DupGroup>[];
      for (final entry in byName.entries) {
        if (entry.value.length < 2) continue;
        final dupCompanies = <_DupCompany>[];
        for (final c in entry.value) {
          dupCompanies.add(_DupCompany(
            company: c,
            users: await _countByCompany('users', c.id),
            employees: await _countByCompany('employees', c.id),
            payslips: await _countByCompany('payslips', c.id),
            documents: await _countByCompany('documents', c.id),
          ));
        }
        groups.add(_DupGroup(name: entry.value.first.name, companies: dupCompanies));
      }

      setState(() {
        _dupGroups = groups;
        _hasScanned = true;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Duplicate scan failed: $e';
        _isScanning = false;
      });
    }
  }

  /// Reassigns every doc in [collection] with companyId == [fromId] to [toId],
  /// committing in batches. Returns the number of docs reassigned.
  Future<int> _reassign(String collection, String fromId, String toId) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .where('companyId', isEqualTo: fromId)
        .get();
    const chunk = 400;
    int moved = 0;
    for (var i = 0; i < snap.docs.length; i += chunk) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs.skip(i).take(chunk)) {
        batch.update(doc.reference, {
          'companyId': toId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        moved++;
      }
      await batch.commit();
    }
    return moved;
  }

  /// Merges every OTHER company in [group] into [keeper]: reassigns all their
  /// data, then deletes the now-empty duplicate company records.
  Future<void> _mergeGroupInto(_DupGroup group, _DupCompany keeper) async {
    final dupes =
        group.companies.where((c) => c.company.id != keeper.company.id).toList();
    if (dupes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.merge_type, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Confirm Merge')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keep this company:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text('${keeper.company.name}  ·  ${keeper.company.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Move all data from, then DELETE:',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            ...dupes.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${d.company.id}  (${d.users}u / ${d.employees}e / ${d.payslips}p / ${d.documents}d)',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Users, employees, payslips, leave balances and documents are '
                'reassigned to the kept company. The duplicate company record is '
                'then deleted. Data is preserved; only the empty duplicate goes away.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('MERGE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });

    try {
      const collections = [
        'users',
        'employees',
        'payslips',
        'leaveBalances',
        'documents',
      ];
      int moved = 0;
      for (final dupe in dupes) {
        for (final col in collections) {
          moved += await _reassign(col, dupe.company.id, keeper.company.id);
        }

        // Users who were granted EXTRA access to the duplicate (multi-farm
        // users) must be pointed at the company that survives, or they would
        // be left holding access to a company that no longer exists.
        final granted = await FirebaseFirestore.instance
            .collection('users')
            .where('additionalCompanyIds', arrayContains: dupe.company.id)
            .get();
        if (granted.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final u in granted.docs) {
            final data = u.data();
            final primary = data['companyId'] as String? ?? '';
            final extras = List<String>.from(
                (data['additionalCompanyIds'] as List?) ?? const [])
              ..remove(dupe.company.id);
            if (primary != keeper.company.id &&
                !extras.contains(keeper.company.id)) {
              extras.add(keeper.company.id);
            }
            batch.update(u.reference, {'additionalCompanyIds': extras});
            moved++;
          }
          await batch.commit();
        }

        await FirebaseFirestore.instance
            .collection('companies')
            .doc(dupe.company.id)
            .delete();
      }

      setState(() {
        _successMessage =
            'Merged into "${keeper.company.name}". Reassigned $moved record(s); '
            'removed ${dupes.length} duplicate compan${dupes.length == 1 ? 'y' : 'ies'}.';
        _isProcessing = false;
      });
      await _scanDuplicates();
      await _loadCompanies();
    } catch (e) {
      setState(() {
        _error = 'Merge failed: $e';
        _isProcessing = false;
      });
    }
  }

  // ── Superseded document cleanup ────────────────────────────────────────────

  Future<void> _scanSuperseded() async {
    setState(() {
      _isScanningSup = true;
      _error = null;
      _successMessage = null;
    });
    try {
      // Doc type names for display only (the allowMultipleDocuments flag is
      // unreliable here — most types default to true — so we do NOT gate on it).
      final typeSnap =
          await FirebaseFirestore.instance.collection('documentTypes').get();
      final typeName = <String, String>{};
      for (final d in typeSnap.docs) {
        typeName[d.id] = (d.data()['name'] as String?) ?? 'Unknown type';
      }
      final companyName = {for (final c in _companies) c.id: c.name};

      final docSnap =
          await FirebaseFirestore.instance.collection('documents').get();
      // group key: companyId|documentTypeId
      final groups = <String, List<_DocLite>>{};
      for (final d in docSnap.docs) {
        final data = d.data();
        final companyId = (data['companyId'] as String?) ?? '';
        final typeId = (data['documentTypeId'] as String?) ?? '';
        if (companyId.isEmpty || typeId.isEmpty) continue;
        groups.putIfAbsent('$companyId|$typeId', () => []).add(_DocLite(
              id: d.id,
              companyId: companyId,
              typeId: typeId,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
              expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
              isSuperseded: data['isSuperseded'] == true,
            ));
      }

      final result = <_SupGroup>[];
      var total = 0;
      for (final entry in groups.entries) {
        final typeId = entry.key.split('|').last;
        // Newest-first among not-yet-superseded documents in this group.
        final active = entry.value.where((d) => !d.isSuperseded).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (active.length <= 1) continue;
        final keeper = active.first;
        // Supersede OLDER documents that are EXPIRED (they've been replaced by
        // a newer version). Non-expired older docs are left alone.
        final toSupersede =
            active.skip(1).where((d) => d.isExpired).map((d) => d.id).toList();
        if (toSupersede.isEmpty) continue;
        total += toSupersede.length;
        result.add(_SupGroup(
          companyName: companyName[keeper.companyId] ?? keeper.companyId,
          docTypeName: typeName[typeId] ?? typeId,
          keeperId: keeper.id,
          toSupersede: toSupersede,
        ));
      }
      result.sort((a, b) {
        final c = a.companyName.compareTo(b.companyName);
        return c != 0 ? c : a.docTypeName.compareTo(b.docTypeName);
      });

      setState(() {
        _supGroups = result;
        _supTotal = total;
        _hasScannedSup = true;
        _isScanningSup = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Superseded scan failed: $e';
        _isScanningSup = false;
      });
    }
  }

  Future<void> _applySuperseded() async {
    if (_supGroups.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.history, color: Colors.blueGrey.shade600),
          const SizedBox(width: 8),
          const Expanded(child: Text('Mark older versions superseded')),
        ]),
        content: Text(
          'Keep the newest of each document and mark $_supTotal older '
          'version(s) as superseded across ${_supGroups.length} document '
          'type(s). Superseded docs leave Action Items but stay findable in '
          'the Audit Index. Nothing is deleted; this can be reversed per doc.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade600,
                foregroundColor: Colors.white),
            child: Text('Supersede $_supTotal'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });
    try {
      var done = 0;
      for (final g in _supGroups) {
        const chunk = 400;
        for (var i = 0; i < g.toSupersede.length; i += chunk) {
          final batch = FirebaseFirestore.instance.batch();
          for (final id in g.toSupersede.skip(i).take(chunk)) {
            batch.update(
                FirebaseFirestore.instance.collection('documents').doc(id), {
              'isSuperseded': true,
              'supersededByDocumentId': g.keeperId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            done++;
          }
          await batch.commit();
        }
      }
      setState(() {
        _successMessage =
            'Marked $done older document version(s) superseded. They will drop '
            'out of Action Items on the next refresh.';
        _isProcessing = false;
      });
      await _scanSuperseded();
    } catch (e) {
      setState(() {
        _error = 'Cleanup failed: $e';
        _isProcessing = false;
      });
    }
  }

  // ── Uploader names ─────────────────────────────────────────────────────────
  //
  // The audit index shows "Uploaded by". Only an admin can look up users from
  // other companies, so for everyone else a document must carry the uploader's
  // name itself. New uploads do; this writes it onto the older ones.

  Future<void> _scanUploaderNames() async {
    setState(() {
      _isScanningUp = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final userSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final names = <String, String>{};
      for (final u in userSnap.docs) {
        final name = ((u.data()['name'] as String?) ?? '').trim();
        if (name.isNotEmpty) names[u.id] = name;
      }

      final docSnap =
          await FirebaseFirestore.instance.collection('documents').get();
      final updates = <String, String>{};
      var unresolved = 0;
      for (final d in docSnap.docs) {
        final data = d.data();
        final existing = ((data['uploadedByName'] as String?) ?? '').trim();
        if (existing.isNotEmpty) continue;
        final name = names[data['userId']];
        if (name != null) {
          updates[d.id] = name;
        } else {
          unresolved++;
        }
      }

      setState(() {
        _upUpdates = updates;
        _upUnresolved = unresolved;
        _hasScannedUp = true;
        _isScanningUp = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Uploader scan failed: $e';
        _isScanningUp = false;
      });
    }
  }

  Future<void> _applyUploaderNames() async {
    if (_upUpdates.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final entries = _upUpdates.entries.toList();
      const chunk = 400;
      for (var i = 0; i < entries.length; i += chunk) {
        final batch = FirebaseFirestore.instance.batch();
        for (final e in entries.skip(i).take(chunk)) {
          batch.update(
              FirebaseFirestore.instance.collection('documents').doc(e.key),
              {'uploadedByName': e.value});
        }
        await batch.commit();
      }
      setState(() {
        _successMessage =
            'Recorded the uploader on ${entries.length} document(s).';
        _isProcessing = false;
      });
      await _scanUploaderNames();
    } catch (e) {
      setState(() {
        _error = 'Backfill failed: $e';
        _isProcessing = false;
      });
    }
  }

  Widget _buildUploaderNamesCard() {
    final primary = Theme.of(context).primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.badge_outlined, color: primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Uploader Names',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed:
                    _isScanningUp || _isProcessing ? null : _scanUploaderNames,
                icon: _isScanningUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: Text(_isScanningUp ? 'Scanning…' : 'Scan'),
              ),
            ]),
            const Text(
              'Older documents don’t carry the name of who uploaded them, so '
              'clients (who can’t look up other companies’ users) see “Unknown '
              'User” in the Audit Index. This writes the name onto them.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_hasScannedUp && _upUpdates.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: Text(
                  _upUnresolved > 0
                      ? 'Nothing more to fill in. $_upUnresolved document(s) were '
                          'uploaded by accounts that no longer exist.'
                      : 'Every document already records who uploaded it. ✅',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (_upUpdates.isNotEmpty) ...[
              Text(
                '${_upUpdates.length} document(s) can be given an uploader name'
                '${_upUnresolved > 0 ? ' ($_upUnresolved more were uploaded by deleted accounts and can’t be)' : ''}.',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _applyUploaderNames,
                  icon: const Icon(Icons.save_outlined),
                  label: Text('Record uploader on ${_upUpdates.length} documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Stray expiry dates ─────────────────────────────────────────────────────
  //
  // Until now, uploading a document whose type has NO expiry date silently
  // stamped it with "today + 365 days". A year later those documents flipped to
  // "Expired". This finds them and clears the date.

  Future<void> _scanStrayExpiry() async {
    setState(() {
      _isScanningExp = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final typeSnap =
          await FirebaseFirestore.instance.collection('documentTypes').get();
      // Types that don't use an expiry date (a missing flag counts as "no
      // expiry", exactly like DocumentTypeModel does).
      final noExpiryTypes = <String, String>{};
      for (final d in typeSnap.docs) {
        final data = d.data();
        if (data['hasExpiryDate'] != true) {
          noExpiryTypes[d.id] = (data['name'] as String?) ?? 'Unknown type';
        }
      }

      final docSnap =
          await FirebaseFirestore.instance.collection('documents').get();
      final now = DateTime.now();
      final auto = <String>[];
      final other = <String>[];
      final byType = <String, int>{};
      var autoExpired = 0;

      for (final d in docSnap.docs) {
        final data = d.data();
        final typeName = noExpiryTypes[data['documentTypeId']];
        if (typeName == null) continue;
        final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
        if (expiry == null) continue;
        final created = (data['createdAt'] as Timestamp?)?.toDate();

        // The old code set expiry = (moment the file was picked) + 365 days, and
        // createdAt a few seconds/minutes later — so expiry sits just under a
        // year after createdAt. Anything in that window is the auto-stamp.
        final days = created == null
            ? double.nan
            : expiry.difference(created).inMinutes / 1440.0;
        if (!days.isNaN && days >= 362 && days <= 366) {
          auto.add(d.id);
          byType.update(typeName, (v) => v + 1, ifAbsent: () => 1);
          if (expiry.isBefore(now)) autoExpired++;
        } else {
          other.add(d.id);
        }
      }

      setState(() {
        _expAutoIds = auto;
        _expOtherIds = other;
        _expAutoExpired = autoExpired;
        _expAutoByType = byType;
        _hasScannedExp = true;
        _isScanningExp = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Expiry scan failed: $e';
        _isScanningExp = false;
      });
    }
  }

  Future<void> _applyStrayExpiry({required bool includeOthers}) async {
    final ids = [..._expAutoIds, if (includeOthers) ..._expOtherIds];
    if (ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear expiry dates'),
        content: Text(
          includeOthers
              ? 'Remove the expiry date from ${ids.length} document(s) whose '
                  'type does not use expiry dates — including '
                  '${_expOtherIds.length} date(s) that do not match the automatic '
                  'one-year pattern and may have been set deliberately.'
              : 'Remove the automatically added expiry date from ${ids.length} '
                  'document(s) whose type does not use expiry dates. '
                  'The documents themselves are not changed.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear ${ids.length}'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _successMessage = null;
    });
    try {
      const chunk = 400;
      for (var i = 0; i < ids.length; i += chunk) {
        final batch = FirebaseFirestore.instance.batch();
        for (final id in ids.skip(i).take(chunk)) {
          batch.update(
              FirebaseFirestore.instance.collection('documents').doc(id),
              {'expiryDate': null});
        }
        await batch.commit();
      }
      setState(() {
        _successMessage =
            'Cleared the expiry date on ${ids.length} document(s). They no '
            'longer count as expired.';
        _isProcessing = false;
      });
      await _scanStrayExpiry();
    } catch (e) {
      setState(() {
        _error = 'Clearing expiry dates failed: $e';
        _isProcessing = false;
      });
    }
  }

  Widget _buildStrayExpiryCard() {
    final primary = Theme.of(context).primaryColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.event_busy_outlined, color: primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Wrongly Expired Documents',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed:
                    _isScanningExp || _isProcessing ? null : _scanStrayExpiry,
                icon: _isScanningExp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: Text(_isScanningExp ? 'Scanning…' : 'Scan'),
              ),
            ]),
            const Text(
              'Documents of a type that has no expiry date were being given one '
              'automatically (upload date + 1 year), so a year later they '
              'showed as Expired. This finds them and removes that date. '
              'Types that do use expiry dates are never touched.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_hasScannedExp && _expAutoIds.isEmpty && _expOtherIds.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primary.withOpacity(0.3)),
                ),
                child: const Text('No stray expiry dates found. ✅',
                    style: TextStyle(fontSize: 13)),
              ),
            if (_expAutoIds.isNotEmpty) ...[
              Text(
                '${_expAutoIds.length} document(s) have an automatically added '
                'expiry date — $_expAutoExpired of them currently show as Expired.',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: (_expAutoByType.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .map((e) => ListTile(
                            dense: true,
                            title: Text(e.key,
                                style: const TextStyle(fontSize: 13)),
                            trailing: Text('${e.value}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primary)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _applyStrayExpiry(includeOthers: false),
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text('Clear ${_expAutoIds.length} automatic dates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            if (_expOtherIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_expOtherIds.length} more document(s) of no-expiry types '
                'have a date that does not match the automatic pattern. They '
                'are left alone unless you choose to clear them too.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _applyStrayExpiry(includeOthers: true),
                  child: Text(
                      'Clear all ${_expAutoIds.length + _expOtherIds.length} (including these)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSupersededCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.layers_clear_outlined, color: Colors.blueGrey.shade500),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Old Document Versions (Action-Item cleanup)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed:
                    _isScanningSup || _isProcessing ? null : _scanSuperseded,
                icon: _isScanningSup
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: Text(_isScanningSup ? 'Scanning…' : 'Scan'),
              ),
            ]),
            const Text(
              'Finds EXPIRED documents that have a newer version of the same '
              'type in the same company (i.e. the old one was replaced). Keeps '
              'the newest and marks those older expired ones superseded, so they '
              'leave Action Items but stay in the Audit Index. Non-expired docs '
              'are never touched.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_hasScannedSup && _supGroups.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text('No old versions to clean up. ✅',
                    style: TextStyle(fontSize: 13)),
              ),
            if (_supGroups.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _supGroups.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, i) {
                    final g = _supGroups[i];
                    return ListTile(
                      dense: true,
                      title: Text(g.docTypeName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(g.companyName,
                          style: const TextStyle(fontSize: 11)),
                      trailing: Text(
                          '${g.toSupersede.length} old',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade600)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _applySuperseded,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.history),
                  label: Text(_isProcessing
                      ? 'Processing…'
                      : 'Keep newest · supersede $_supTotal older'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.content_copy, color: Colors.deepPurple.shade400),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Duplicate Companies',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton.icon(
                onPressed: _isScanning || _isProcessing ? null : _scanDuplicates,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search, size: 18),
                label: Text(_isScanning ? 'Scanning…' : 'Scan'),
              ),
            ]),
            const Text(
              'Finds companies that share a name. Keep the correct one — its data '
              'is preserved and the duplicate’s data is moved into it before the '
              'duplicate is deleted.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_hasScanned && _dupGroups.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text('No duplicate company names found. ✅',
                    style: TextStyle(fontSize: 13)),
              ),
            ..._dupGroups.map(_buildDupGroup),
          ],
        ),
      ),
    );
  }

  Widget _buildDupGroup(_DupGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“${group.name}” — ${group.companies.length} records',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...group.companies.map((c) {
            final empty = c.total == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: empty ? Colors.red.shade200 : Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text('ID: ${c.company.id}',
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace')),
                    ),
                    if (empty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('EMPTY',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${c.users} users · ${c.employees} employees · '
                    '${c.payslips} payslips · ${c.documents} documents',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _mergeGroupInto(group, c),
                      icon: const Icon(Icons.merge_type, size: 16),
                      label: const Text('Keep this · merge others here',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Only admins can access this
    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Access Denied',
        child: const Center(
          child: Text('Only administrators can access this utility.'),
        ),
      );
    }

    return AppScaffoldWrapper(
      title: '🔧 Data Fix Utility',
      child: _isLoadingCompanies
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ADMIN UTILITY: Use this to fix documents that were uploaded to the wrong company. '
                          'Select the source (wrong) company, then move docs to the target (correct) company.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Duplicate company inspector / merge ──────────────────────
            _buildStrayExpiryCard(),

            const SizedBox(height: 24),

            _buildUploaderNamesCard(),

            const SizedBox(height: 24),

            _buildSupersededCard(),

            const SizedBox(height: 24),

            _buildDuplicateCard(),

            const SizedBox(height: 24),

            // ── One-time seed actions ────────────────────────────────────
            // Template for seeding a new audit package into the database.
            // IPW has already been seeded — uncomment + adapt this block (and
            // the import at the top) when adding the next package.
            //
            // Card(
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text('Setup: IPW Audit Package',
            //             style: TextStyle(
            //                 fontWeight: FontWeight.bold, fontSize: 16)),
            //         const SizedBox(height: 4),
            //         Text(
            //           'Seeds the IPW categories and document types. '
            //           'Safe to tap — it skips if IPW already exists.',
            //           style: TextStyle(
            //               fontSize: 13, color: Colors.grey.shade700)),
            //         const SizedBox(height: 12),
            //         Align(
            //           alignment: Alignment.centerLeft,
            //           child: FilledButton.icon(
            //             onPressed: () => setupIPWData(context),
            //             icon: const Icon(Icons.wine_bar, size: 18),
            //             label: const Text('Setup IPW Package'),
            //             style: FilledButton.styleFrom(
            //                 backgroundColor: Colors.purple),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setup: Fairtrade (Hired Labour) Audit Package',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Seeds the 14 Fairtrade categories and their document '
                      'types (from the Fairtrade Audit Index PDF). Safe to tap '
                      '— it skips if Fairtrade already exists. Then switch '
                      'Fairtrade on for each company in Company Management.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => setupFairtradeData(context),
                        icon: const Icon(Icons.handshake_outlined, size: 18),
                        label: const Text('Setup Fairtrade Package'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setup: SIZA Environmental Audit Package',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Seeds the 5 SIZA Environmental categories and their 92 '
                      'document types (from the SIZA Environmental Audit Index). '
                      'Safe to tap — it skips if it already exists. Then switch '
                      'SIZA Environmental on for each company in Company Management.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => setupSizaEnvironmentalData(context),
                        icon: const Icon(Icons.forest_outlined, size: 18),
                        label: const Text('Setup SIZA Environmental Package'),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.lightGreen.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Source company selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: Select SOURCE Company',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text(
                      '(The wrong company where documents ended up)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CompanyModel>(
                      value: _sourceCompany,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Select source company'),
                      items: _companies.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sourceCompany = value;
                          _sourceDocuments = [];
                          _selectedDocIds = {};
                        });
                        if (value != null) {
                          _loadSourceDocuments();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Target company selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 2: Select TARGET Company',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text(
                      '(The correct company where documents should be)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CompanyModel>(
                      value: _targetCompany,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Select target company'),
                      items: _companies
                          .where((c) => c.id != _sourceCompany?.id)
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _targetCompany = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error/Success messages
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade700)),
              ),

            const SizedBox(height: 16),

            // Documents list
            if (_sourceCompany != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step 3: Select Documents (${_sourceDocuments.length} found)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (_sourceDocuments.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedDocIds.length == _sourceDocuments.length) {
                                    _selectedDocIds.clear();
                                  } else {
                                    _selectedDocIds = _sourceDocuments.map((d) => d.id).toSet();
                                  }
                                });
                              },
                              child: Text(
                                _selectedDocIds.length == _sourceDocuments.length
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingDocuments)
                        const Center(child: CircularProgressIndicator())
                      else if (_sourceDocuments.isEmpty)
                        const Text('No documents found in this company.')
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _sourceDocuments.length,
                            itemBuilder: (context, index) {
                              final doc = _sourceDocuments[index];
                              final isSelected = _selectedDocIds.contains(doc.id);

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedDocIds.add(doc.id);
                                    } else {
                                      _selectedDocIds.remove(doc.id);
                                    }
                                  });
                                },
                                title: Text(
                                  'Doc: ${doc.documentTypeId.substring(0, 8)}...',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Created: ${doc.createdAt.toString().substring(0, 16)} | '
                                      'Files: ${doc.fileUrls.length} | '
                                      'Status: ${doc.status.name}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            if (_selectedDocIds.isNotEmpty) ...[
              Text(
                '${_selectedDocIds.length} documents selected',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || _targetCompany == null
                          ? null
                          : _moveSelectedDocuments,
                      icon: _isProcessing
                          ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.swap_horiz),
                      label: Text(_isProcessing ? 'Processing...' : 'MOVE TO TARGET'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _deleteSelectedDocuments,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('DELETE', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}