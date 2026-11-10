import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/employee_model.dart';
import '../models/leave_balance_model.dart';
import '../models/payslip_model.dart';

class PayrollSettings {
  final String companyId;
  final String uifRegNumber;
  // Editable company address printed on every payslip PDF. Stored here
  // (and not on CompanyModel) so the payslip manager owns it independently.
  final String companyAddress;
  /// Last bank chosen for the bulk-payment file (a BankExportTemplate id),
  /// pre-selected next time. Null until the farm first exports.
  final String? bankExportTemplateId;

  PayrollSettings({
    required this.companyId,
    required this.uifRegNumber,
    this.companyAddress = '',
    this.bankExportTemplateId,
  });

  PayrollSettings copyWith({
    String? uifRegNumber,
    String? companyAddress,
    String? bankExportTemplateId,
  }) =>
      PayrollSettings(
        companyId: companyId,
        uifRegNumber: uifRegNumber ?? this.uifRegNumber,
        companyAddress: companyAddress ?? this.companyAddress,
        bankExportTemplateId:
            bankExportTemplateId ?? this.bankExportTemplateId,
      );

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'uifRegNumber': uifRegNumber,
        'companyAddress': companyAddress,
        if (bankExportTemplateId != null)
          'bankExportTemplateId': bankExportTemplateId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

  factory PayrollSettings.empty(String companyId) =>
      PayrollSettings(companyId: companyId, uifRegNumber: '');

  factory PayrollSettings.fromMap(Map<String, dynamic> map, String companyId) =>
      PayrollSettings(
        companyId: companyId,
        uifRegNumber: map['uifRegNumber'] ?? '',
        companyAddress: map['companyAddress'] ?? '',
        bankExportTemplateId: map['bankExportTemplateId'] as String?,
      );
}

class PayslipProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  List<EmployeeModel> _employees = [];
  List<PayslipModel> _payslips = [];
  PayrollSettings? _payrollSettings;
  Map<String, LeaveBalanceModel> _leaveBalances = {};
  bool _isLoading = false;
  String? _error;
  String? _currentCompanyId;

  List<EmployeeModel> get employees => _employees;
  List<PayslipModel> get payslips => _payslips;
  PayrollSettings? get payrollSettings => _payrollSettings;
  Map<String, LeaveBalanceModel> get leaveBalances => _leaveBalances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// The company whose payroll data is currently held (or being loaded).
  String? get loadedCompanyId => _currentCompanyId;

  // ── Load ──────────────────────────────────────────────────────────────────

  // The load currently in progress, so a second caller asking for the same
  // company waits for it instead of returning early with empty data.
  Future<void>? _inFlight;

  Future<void> loadForCompany(String companyId, {bool force = false}) {
    if (_currentCompanyId == companyId && !force) {
      return _inFlight ?? Future<void>.value();
    }
    final load = _loadForCompany(companyId);
    _inFlight = load;
    return load.whenComplete(() {
      if (identical(_inFlight, load)) _inFlight = null;
    });
  }

  Future<void> _loadForCompany(String companyId) async {
    _currentCompanyId = companyId;
    _employees = [];
    _payslips = [];
    _payrollSettings = null;
    _leaveBalances = {};
    _setLoading(true);
    _error = null;

    try {
      final results = await Future.wait([
        _db
            .collection('employees')
            .where('companyId', isEqualTo: companyId)
            .get(),
        _db
            .collection('payslips')
            .where('companyId', isEqualTo: companyId)
            .get(),
        _db.collection('payrollSettings').doc(companyId).get(),
        _db
            .collection('leaveBalances')
            .where('companyId', isEqualTo: companyId)
            .get(),
      ]);

      _employees = (results[0] as QuerySnapshot)
          .docs
          .map((d) => EmployeeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      _payslips = (results[1] as QuerySnapshot)
          .docs
          .map((d) => PayslipModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList()
        ..sort((a, b) => b.payPeriodStart.compareTo(a.payPeriodStart));

      final settingsDoc = results[2] as DocumentSnapshot;
      _payrollSettings = settingsDoc.exists
          ? PayrollSettings.fromMap(
              settingsDoc.data() as Map<String, dynamic>, companyId)
          : PayrollSettings.empty(companyId);

      _leaveBalances = {};
      for (final doc in (results[3] as QuerySnapshot).docs) {
        final lb = LeaveBalanceModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        _leaveBalances[lb.employeeId] = lb;
      }
    } catch (e) {
      print('PayslipProvider: loadForCompany ERROR: $e');
      _error = e.toString();
    } finally {
      print(
          'PayslipProvider: loaded ${_employees.length} employees, ${_payslips.length} payslips for $companyId');
      _setLoading(false);
    }
  }

  // ── Payroll Settings ──────────────────────────────────────────────────────

  /// Remembers the farm's bank for the bulk-payment file. Writes only this
  /// one field (merge) so it can't overwrite other payroll settings.
  Future<bool> saveBankExportTemplate(String companyId, String templateId) async {
    try {
      await _db.collection('payrollSettings').doc(companyId).set({
        'companyId': companyId,
        'bankExportTemplateId': templateId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      if (_currentCompanyId == companyId) {
        _payrollSettings = (_payrollSettings ?? PayrollSettings.empty(companyId))
            .copyWith(bankExportTemplateId: templateId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> savePayrollSettings(PayrollSettings settings) async {
    try {
      await _db
          .collection('payrollSettings')
          .doc(settings.companyId)
          .set(settings.toMap(), SetOptions(merge: true));
      // Callers build fresh settings objects; keep the remembered bank
      // (toMap omits it when null, so Firestore keeps it too via merge).
      _payrollSettings = settings.bankExportTemplateId == null
          ? settings.copyWith(
              bankExportTemplateId: _payrollSettings?.bankExportTemplateId)
          : settings;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Employee CRUD ─────────────────────────────────────────────────────────

  Future<bool> saveEmployee(EmployeeModel employee) async =>
      await upsertEmployee(employee) != null;

  /// Creates or updates an employee and returns the saved record.
  ///
  /// An employee with an id that isn't in the list (e.g. re-creating a
  /// removed record under its original id so its old payslips link up
  /// again) is added, not silently dropped.
  Future<EmployeeModel?> upsertEmployee(EmployeeModel employee) async {
    try {
      final id = employee.id.isEmpty ? _uuid.v4() : employee.id;
      final idx = _employees.indexWhere((e) => e.id == id);
      final data = employee.copyWith().toMap();
      if (idx == -1) {
        data['createdAt'] = Timestamp.fromDate(DateTime.now());
      }
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _db.collection('employees').doc(id).set(data, SetOptions(merge: true));

      final saved = EmployeeModel.fromMap(data, id);
      if (idx == -1) {
        _employees.add(saved);
        _employees.sort((a, b) => a.name.compareTo(b.name));
      } else {
        _employees[idx] = saved;
      }
      notifyListeners();
      return saved;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Points [payslipIds] at [employeeId] — repairs payslips whose employee
  /// record was removed or never linked. Only the link changes; the
  /// payslip's name/amount snapshot is kept as issued.
  Future<bool> relinkPayslips(
      Iterable<String> payslipIds, String employeeId) async {
    try {
      final ids = payslipIds.toSet();
      final batch = _db.batch();
      for (final id in ids) {
        batch.update(_db.collection('payslips').doc(id), {
          'employeeId': employeeId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      await batch.commit();
      for (var i = 0; i < _payslips.length; i++) {
        final p = _payslips[i];
        if (ids.contains(p.id)) {
          final map = p.toMap()..['employeeId'] = employeeId;
          _payslips[i] = PayslipModel.fromMap(map, p.id);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String employeeId) async {
    try {
      await _db.collection('employees').doc(employeeId).delete();
      _employees.removeWhere((e) => e.id == employeeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Payslip CRUD ──────────────────────────────────────────────────────────

  Future<PayslipModel?> savePayslip(PayslipModel payslip) async {
    try {
      final isNew = payslip.id.isEmpty;
      final id = isNew ? _uuid.v4() : payslip.id;
      final data = payslip.toMap();
      if (isNew) {
        data['createdAt'] = Timestamp.fromDate(DateTime.now());
      }
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _db.collection('payslips').doc(id).set(data, SetOptions(merge: true));

      final saved = PayslipModel.fromMap(data, id);
      if (isNew) {
        _payslips.insert(0, saved);
      } else {
        final idx = _payslips.indexWhere((p) => p.id == id);
        if (idx != -1) _payslips[idx] = saved;
      }
      notifyListeners();
      return saved;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePayslip(String payslipId) async {
    try {
      await _db.collection('payslips').doc(payslipId).delete();
      _payslips.removeWhere((p) => p.id == payslipId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  PayslipModel? getPayslipById(String id) {
    try {
      return _payslips.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Leave Balances ────────────────────────────────────────────────────────

  LeaveBalanceModel getLeaveBalance(String employeeId) {
    return _leaveBalances[employeeId] ??
        LeaveBalanceModel.empty(
            employeeId, _currentCompanyId ?? '');
  }

  Future<bool> saveLeaveBalance(LeaveBalanceModel balance) async {
    try {
      await _db
          .collection('leaveBalances')
          .doc(balance.employeeId)
          .set(balance.toMap(), SetOptions(merge: true));
      _leaveBalances[balance.employeeId] = balance;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Computed leave status ─────────────────────────────────────────────────

  /// Total hours worked INSIDE the system (from payslips). Opening leave
  /// balances are no longer derived from prior hours — they're entered
  /// directly — so this only sums in-system worked hours used for accrual.
  double totalHoursWorked(String employeeId) => _payslips
      .where((p) => p.employeeId == employeeId)
      .fold<double>(0, (sum, p) => sum + p.workedHoursForAccrual);

  // ── Holiday leave ───────────────────────────────────────────────
  /// Holiday leave accrued from in-system work (1 hr per 17 hrs worked).
  double holidayLeaveAccrued(String employeeId) =>
      totalHoursWorked(employeeId) / 17.0;

  double holidayLeaveUsed(String employeeId) => _payslips
      .where((p) => p.employeeId == employeeId)
      .fold<double>(0, (sum, p) => sum + p.holidayLeaveHours);

  /// Opening + accrued-in-system − taken.
  double holidayLeaveBalance(String employeeId) =>
      getLeaveBalance(employeeId).openingHolidayHours +
      holidayLeaveAccrued(employeeId) -
      holidayLeaveUsed(employeeId);

  // ── Sick leave ──────────────────────────────────────────────────
  double sickLeavePreAccrued(String employeeId) =>
      totalHoursWorked(employeeId) / 26.0;

  double sickLeaveUsed(String employeeId) => _payslips
      .where((p) => p.employeeId == employeeId)
      .fold<double>(0, (sum, p) => sum + p.sickLeaveHours);

  /// In-system sick leave entitlement (excludes opening balance):
  /// admin-granted 30-day batches once past 6 months, else pre-6mo accrual.
  double sickLeaveInSystem(String employeeId) {
    final emp = _employees.firstWhere((e) => e.id == employeeId,
        orElse: () => EmployeeModel(
            id: employeeId,
            companyId: '',
            name: '',
            idNumber: '',
            normalHourlyRate: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()));
    final stored = getLeaveBalance(employeeId);
    if (emp.isPostSixMonths && stored.totalSickLeaveAllocated > 0) {
      return stored.totalSickLeaveAllocated;
    }
    return sickLeavePreAccrued(employeeId);
  }

  /// Opening + in-system entitlement − taken.
  double sickLeaveBalance(String employeeId) =>
      getLeaveBalance(employeeId).openingSickHours +
      sickLeaveInSystem(employeeId) -
      sickLeaveUsed(employeeId);

  // ── Family responsibility leave ─────────────────────────────────
  EmployeeModel? _employeeById(String id) {
    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Start of the employee's CURRENT 12-month family-leave cycle, measured from
  /// their employment anniversary. Null when no start date is on file.
  DateTime? familyLeaveCycleStart(String employeeId) {
    final start = _employeeById(employeeId)?.employmentStartDate;
    if (start == null) return null;
    final now = DateTime.now();
    var years = now.year - start.year;
    var anniv = DateTime(start.year + years, start.month, start.day);
    if (anniv.isAfter(now)) {
      years -= 1;
      anniv = DateTime(start.year + years, start.month, start.day);
    }
    return anniv;
  }

  /// Statutory family responsibility leave for the current cycle: auto-granted
  /// 3 days (24 h) once the employee is eligible (>4 months employed). An admin
  /// can still override the hours via the allocation dialog. Forfeit-based, so
  /// it does NOT accumulate across cycles.
  double familyLeaveEntitlement(String employeeId) {
    final emp = _employeeById(employeeId);
    if (emp == null || !emp.isFamilyLeaveEligible) return 0;
    final stored = getLeaveBalance(employeeId);
    return stored.familyLeaveAllocatedHours > 0
        ? stored.familyLeaveAllocatedHours
        : 24.0; // 3 days × 8 hrs
  }

  /// Family leave taken within the current cycle only (previous cycles reset).
  double familyLeaveUsed(String employeeId) {
    final cycleStart = familyLeaveCycleStart(employeeId);
    return _payslips
        .where((p) =>
            p.employeeId == employeeId &&
            (cycleStart == null || !p.payPeriodStart.isBefore(cycleStart)))
        .fold<double>(0, (sum, p) => sum + p.familyLeaveHours);
  }

  /// Opening (pre-system) + this cycle's entitlement − taken this cycle.
  double familyLeaveBalance(String employeeId) =>
      getLeaveBalance(employeeId).openingFamilyHours +
      familyLeaveEntitlement(employeeId) -
      familyLeaveUsed(employeeId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
