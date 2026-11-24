import 'dart:math';
import 'package:cropCompliance/providers/auth_provider.dart' as autPro;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import '../../theme/theme_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();

  String? _selectedCompanyId;
  UserRole _selectedRole = UserRole.USER;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _companies = [];
  List<UserModel> _users = [];
  bool _createNewCompany = false;

  // Extra farms to grant a new user on top of the one chosen above.
  Set<String> _newUserExtraFarms = {};

  // Existing-users list: search + status filter, and per-user "busy" markers
  // so a toggle can't be fired twice while it is saving.
  final _searchController = TextEditingController();
  String _search = '';
  _UserFilter _filter = _UserFilter.all;
  final Set<String> _busyUserIds = {};

  static const Color _brandGreen = Color(0xFF2E7D32);

  InputDecoration _modernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _brandGreen, width: 1.5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Companies and users are independent — fetch them side by side.
      final snaps = await Future.wait([
        FirebaseFirestore.instance.collection('companies').get(),
        FirebaseFirestore.instance.collection('users').get(),
      ]);
      final companiesSnapshot = snaps[0];
      final usersSnapshot = snaps[1];

      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList()
        ..sort((a, b) => (a['name'] as String)
            .toLowerCase()
            .compareTo((b['name'] as String).toLowerCase()));

      final users = usersSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _companies = companies;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  /// True if a company with this name already exists (case-insensitive).
  /// Used to block accidental duplicate company records.
  bool _companyNameExists(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return false;
    return _companies
        .any((c) => (c['name'] as String? ?? '').trim().toLowerCase() == n);
  }

  Future<String?> _createCompany() async {
    if (_companyNameController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a company name';
      });
      return null;
    }

    try {
      final companyRef = await FirebaseFirestore.instance.collection('companies').add({
        'name': _companyNameController.text.trim(),
        'address': _companyAddressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return companyRef.id;
    } catch (e) {
      setState(() {
        _error = 'Error creating company: $e';
      });
      return null;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_createNewCompany && _selectedCompanyId == null) {
      setState(() => _error = 'Please select a company');
      return;
    }

    // Block duplicate company records up front. Creating a second company with
    // the same name is what produced the duplicate "All Terrain Agri Services".
    if (_createNewCompany && _companyNameExists(_companyNameController.text)) {
      setState(() => _error =
          'A company named "${_companyNameController.text.trim()}" already '
          'exists. Untick "Create new company" and pick it from the list.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Use a unique name so we can safely call this multiple times.
    final secondaryAppName = 'userCreation_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseApp? secondaryApp;
    // Track a freshly-created company so we can roll it back if the user step
    // fails — otherwise the company is orphaned with no users (the exact bug
    // that created the empty company here).
    String? createdCompanyId;
    bool userCreated = false;

    try {
      String? companyId = _selectedCompanyId;
      if (_createNewCompany) {
        companyId = await _createCompany();
        if (companyId == null) {
          setState(() => _isLoading = false);
          return;
        }
        createdCompanyId = companyId;
      }

      // Create the new user through a SECONDARY Firebase app so the admin's
      // session on the primary app is never replaced.
      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;

      // Write the Firestore document as the still-signed-in admin
      // (primary app auth is untouched).
      // Extra farms only make sense for an existing company and a non-admin
      // (admins can already reach every farm).
      final extraFarms = (_createNewCompany || _selectedRole == UserRole.ADMIN)
          ? <String>[]
          : (_newUserExtraFarms.toList()..remove(companyId));

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _selectedRole.toString().split('.').last,
        'companyId': companyId,
        'additionalCompanyIds': extraFarms,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      userCreated = true;

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _companyNameController.clear();
      _companyAddressController.clear();
      setState(() {
        _selectedRole = UserRole.USER;
        _createNewCompany = false;
        _newUserExtraFarms = {};
        _isLoading = false;
      });

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'email-already-in-use'
            ? 'That email is already registered.'
            : 'Auth error: ${e.message}';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _error = 'Firebase error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error creating user: $e';
        _isLoading = false;
      });
    } finally {
      // Roll back a company that was created but never got its user, so we
      // never leave an orphan behind.
      if (createdCompanyId != null && !userCreated) {
        try {
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(createdCompanyId)
              .delete();
        } catch (_) {/* best-effort cleanup */}
      }
      // Always clean up the secondary app to free resources.
      await secondaryApp?.delete();
    }
  }

  // ── Farm access & account status ──────────────────────────────────────────

  String _companyName(String id) {
    for (final c in _companies) {
      if (c['id'] == id) return c['name'] as String;
    }
    return 'Unknown farm';
  }

  void _replaceUser(UserModel updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i >= 0) setState(() => _users[i] = updated);
  }

  /// Opens the farm picker. [initial] is the current selection; [lockedId] (if
  /// given) is shown ticked and can't be removed. Returns null if cancelled.
  Future<Set<String>?> _pickFarms({
    required String title,
    required String subtitle,
    required Set<String> initial,
    String? lockedId,
  }) {
    return showDialog<Set<String>>(
      context: context,
      builder: (_) => _FarmPickerDialog(
        title: title,
        subtitle: subtitle,
        companies: _companies,
        initial: initial,
        lockedId: lockedId,
      ),
    );
  }

  /// Lets an admin choose exactly which farms a user can work in. The first
  /// one stays the user's primary farm if it's still ticked.
  Future<void> _manageFarmAccess(UserModel user) async {
    final result = await _pickFarms(
      title: 'Farm access',
      subtitle: '${user.name} can switch between the farms you tick.',
      initial: user.accessibleCompanyIds.toSet(),
    );
    if (result == null || result.isEmpty) return;

    // Keep the existing primary farm if it's still selected; otherwise promote
    // the first remaining farm (in alphabetical order) so there's always one.
    final ordered = _companies
        .map((c) => c['id'] as String)
        .where(result.contains)
        .toList();
    final primary =
        result.contains(user.companyId) ? user.companyId : ordered.first;
    final extras = ordered.where((id) => id != primary).toList();

    setState(() => _busyUserIds.add(user.id));
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'companyId': primary,
        'additionalCompanyIds': extras,
      });
      _replaceUser(user.copyWith(companyId: primary, additionalCompanyIds: extras));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${user.name} now has access to ${result.length} farm${result.length == 1 ? '' : 's'}.'),
          backgroundColor: _brandGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update farm access: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(user.id));
    }
  }

  /// Activates or deactivates an account. The profile flag is written first (it
  /// is what the app checks at every sign-in); then the server function is
  /// asked to also lock/unlock the sign-in itself, so a deactivated person
  /// can't get in with their password at all.
  Future<void> _setActive(UserModel user, bool active) async {
    final me = Provider.of<autPro.AuthProvider>(context, listen: false).currentUser;
    if (user.id == me?.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You can’t deactivate your own account.'),
      ));
      return;
    }

    if (!active) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(children: [
            const Icon(Icons.block, color: _brandGreen),
            const SizedBox(width: 10),
            const Expanded(child: Text('Deactivate account?')),
          ]),
          content: Text(
            '${user.name} (${user.email}) will no longer be able to sign in. '
            'Their documents and history are kept, and you can reactivate the '
            'account at any time.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _brandGreen),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busyUserIds.add(user.id));
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'isActive': active});
      _replaceUser(user.copyWith(isActive: active));

      // Best effort: also lock/unlock the sign-in itself (needs the
      // `setUserActive` Cloud Function to be deployed).
      var signInLocked = true;
      try {
        await FirebaseFunctions.instance
            .httpsCallable('setUserActive')
            .call({'userId': user.id, 'active': active});
      } catch (_) {
        signInLocked = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            active
                ? '${user.name} is active again.'
                : signInLocked
                    ? '${user.name} has been deactivated.'
                    : '${user.name} has been deactivated in the app. Deploy the '
                        '`setUserActive` function to also lock their sign-in.',
          ),
          backgroundColor: _brandGreen,
          duration: Duration(seconds: signInLocked || active ? 3 : 7),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update the account: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _busyUserIds.remove(user.id));
    }
  }

  List<UserModel> get _filteredUsers {
    final q = _search.trim().toLowerCase();
    return _users.where((u) {
      switch (_filter) {
        case _UserFilter.active:
          if (!u.isActive) return false;
          break;
        case _UserFilter.deactivated:
          if (u.isActive) return false;
          break;
        case _UserFilter.auditors:
          if (u.role != UserRole.AUDITER) return false;
          break;
        case _UserFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _sendPasswordReset(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.lock_reset_outlined,
                color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Text('Send Password Reset'),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              const TextSpan(text: 'This will send a password reset email to\n'),
              TextSpan(
                text: user.email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                  text: '\n\nThe client clicks the link in the email and sets their own new password.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_outlined, size: 16),
            label: const Text('Send Email'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset email sent to ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sets a user's password directly via the `updateUserPassword` Cloud
  /// Function (Admin SDK) — bypasses email entirely. Reliable fallback while
  /// Firebase's default reset-email sender has poor deliverability (no
  /// verified sending domain). The admin relays the new password to the user
  /// directly (call/WhatsApp/SMS).
  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _setPasswordDirectly(UserModel user) async {
    final passwordCtrl = TextEditingController(text: _generatePassword());
    bool obscure = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.password_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Expanded(child: Text('Set Password Directly')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Sets the password for\n'),
                    TextSpan(
                      text: user.email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text:
                            ' immediately — no email is sent. Give the user this password yourself (call, WhatsApp, SMS).'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: obscure ? 'Show' : 'Hide',
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                      IconButton(
                        tooltip: 'Generate new',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setDialogState(
                            () => passwordCtrl.text = _generatePassword()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('At least 6 characters. A strong one is generated for you.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: passwordCtrl.text.trim().length >= 6
                  ? () => Navigator.pop(ctx, true)
                  : null,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Set Password'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final newPassword = passwordCtrl.text.trim();
    if (newPassword.length < 6) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('updateUserPassword');
      await callable.call({'userId': user.id, 'newPassword': newPassword});

      if (mounted) Navigator.pop(context); // close spinner

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 10),
                const Text('Password Set'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name} (${user.email}) can now log in with:'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          newPassword,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: newPassword));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send this to them directly — no email was sent.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) Navigator.pop(context); // close spinner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close spinner
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<autPro.AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'User Management',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    // Re-insert your missing UI build code here.
    // If youâ€™d like, I can regenerate the full widget tree using the new compact modern input style.

    return AppScaffoldWrapper(
      title: 'User Management',
      backgroundColor: Colors.grey[100],
      child: _isLoading
          ? const LoadingIndicator(message: 'Loading user data...')
          : _error != null
          ? ErrorDisplay(error: _error!, onRetry: _loadData)
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New User',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _modernInputDecoration('Full Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _modernInputDecoration('Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(fontSize: 14),
                        decoration: _modernInputDecoration('Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Company Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Switch(
                            value: _createNewCompany,
                            onChanged: (value) {
                              setState(() {
                                _createNewCompany = value;
                              });
                            },
                          ),
                          Text(_createNewCompany ? 'Create New' : 'Select Existing'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_createNewCompany) ...[
                        TextFormField(
                          controller: _companyNameController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _modernInputDecoration('Company Name'),
                          validator: (value) {
                            if (_createNewCompany && (value == null || value.isEmpty)) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _companyAddressController,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          decoration: _modernInputDecoration('Company Address'),
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _modernInputDecoration('Select Company'),
                          value: _selectedCompanyId,
                          items: _companies.map((company) {
                            return DropdownMenuItem<String>(
                              value: company['id'] as String,
                              child: Text(
                                company['name'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCompanyId = value;
                              // The primary farm can't also be an "extra" one.
                              _newUserExtraFarms.remove(value);
                            });
                          },
                          validator: (value) {
                            if (!_createNewCompany && (value == null || value.isEmpty)) {
                              return 'Please select a company';
                            }
                            return null;
                          },
                        ),
                        // Optional: more farms for this user (not for admins,
                        // who can already reach every farm).
                        if (_selectedRole != UserRole.ADMIN) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _selectedCompanyId == null
                                  ? null
                                  : () async {
                                      final result = await _pickFarms(
                                        title: 'Additional farms',
                                        subtitle:
                                            'Besides ${_companyName(_selectedCompanyId!)}, which farms can this user switch to?',
                                        initial: {
                                          _selectedCompanyId!,
                                          ..._newUserExtraFarms,
                                        },
                                        lockedId: _selectedCompanyId,
                                      );
                                      if (result != null) {
                                        setState(() => _newUserExtraFarms = result
                                          ..remove(_selectedCompanyId));
                                      }
                                    },
                              icon: const Icon(Icons.agriculture_outlined, size: 18),
                              label: Text(
                                _selectedCompanyId == null
                                    ? 'Choose a company first to add more farms'
                                    : _newUserExtraFarms.isEmpty
                                        ? 'Give access to more farms (optional)'
                                        : '${_newUserExtraFarms.length} additional farm'
                                            '${_newUserExtraFarms.length == 1 ? '' : 's'} — tap to edit',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _brandGreen,
                                side: BorderSide(
                                    color: _brandGreen.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        decoration: _modernInputDecoration('Role'),
                        value: _selectedRole,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                              if (value == UserRole.ADMIN) _newUserExtraFarms = {};
                            });
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _roleHint(_selectedRole),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createUser,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Create User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Existing Users (${_users.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildUserSearchAndFilters(),
            const SizedBox(height: 12),
            if (_filteredUsers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                      _users.isEmpty
                          ? 'No users yet.'
                          : 'No users match your search or filter.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else
              ..._filteredUsers.map(_buildUserCard),
          ],
        ),
      ),
    );
  }

  // ── Existing-users list ───────────────────────────────────────────────────

  String _roleHint(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Full access, including every farm and this admin area.';
      case UserRole.AUDITER:
        return 'Read-only. Sees only the Audit Index and only approved documents, '
            'for the farms you give them.';
      case UserRole.USER:
        return 'Works within the farms they are given access to.';
    }
  }

  // Role chips stay inside the app palette: brand green, the theme's amber
  // accent, and neutral grey.
  ({Color bg, Color fg}) _roleColors(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return (bg: _brandGreen.withOpacity(0.12), fg: _brandGreen);
      case UserRole.AUDITER:
        return (
          bg: ThemeConstants.accentColor.withOpacity(0.30),
          fg: const Color(0xFF8A5A00),
        );
      case UserRole.USER:
        return (bg: Colors.grey.shade200, fg: Colors.grey.shade800);
    }
  }

  Widget _buildUserSearchAndFilters() {
    int count(bool Function(UserModel) test) => _users.where(test).length;

    Widget chip(String label, _UserFilter f, int n) {
      final selected = _filter == f;
      return ChoiceChip(
        label: Text('$label ($n)'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = f),
        backgroundColor: Colors.white,
        selectedColor: _brandGreen.withOpacity(0.14),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? _brandGreen : Colors.grey.shade700,
        ),
        shape: StadiumBorder(
          side: BorderSide(color: selected ? _brandGreen : Colors.grey.shade300),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 14),
          onChanged: (v) => setState(() => _search = v),
          decoration: _modernInputDecoration('Search by name or email').copyWith(
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('All', _UserFilter.all, _users.length),
            chip('Active', _UserFilter.active, count((u) => u.isActive)),
            chip('Deactivated', _UserFilter.deactivated, count((u) => !u.isActive)),
            chip('Auditors', _UserFilter.auditors,
                count((u) => u.role == UserRole.AUDITER)),
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg, {IconData? icon}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final me = Provider.of<autPro.AuthProvider>(context, listen: false).currentUser;
    final isSelf = user.id == me?.id;
    final busy = _busyUserIds.contains(user.id);
    final isAdminUser = user.role == UserRole.ADMIN;
    final role = _roleColors(user.role);
    final dim = user.isActive ? 1.0 : 0.55;

    const maxFarmChips = 3;
    final farmIds = user.accessibleCompanyIds;
    final shownFarms = farmIds.take(maxFarmChips).toList();
    final hiddenFarms = farmIds.length - shownFarms.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: dim,
                  child: CircleAvatar(
                    backgroundColor:
                        user.isActive ? _brandGreen : Colors.grey.shade500,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: dim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSelf ? '${user.name}  (you)' : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _pill(user.role.name, role.bg, role.fg),
                            if (isAdminUser)
                              _pill('All farms', Colors.grey.shade100,
                                  Colors.grey.shade700,
                                  icon: Icons.agriculture_outlined)
                            else ...[
                              for (final id in shownFarms)
                                _pill(_companyName(id), Colors.grey.shade100,
                                    Colors.grey.shade700,
                                    icon: Icons.agriculture_outlined),
                              if (hiddenFarms > 0)
                                _pill('+$hiddenFarms more', Colors.grey.shade100,
                                    Colors.grey.shade700),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: isSelf
                          ? 'You can’t deactivate your own account'
                          : user.isActive
                              ? 'Deactivate account'
                              : 'Activate account',
                      child: Switch(
                        value: user.isActive,
                        onChanged:
                            (busy || isSelf) ? null : (v) => _setActive(user, v),
                        activeTrackColor: _brandGreen,
                        activeThumbColor: Colors.white,
                      ),
                    ),
                    Text(
                      busy
                          ? 'Saving…'
                          : user.isActive
                              ? 'Active'
                              : 'Deactivated',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: user.isActive ? _brandGreen : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                Tooltip(
                  message: isAdminUser
                      ? 'Admins can already access every farm'
                      : 'Choose which farms this user can access',
                  child: TextButton.icon(
                    onPressed: (isAdminUser || busy) ? null : () => _manageFarmAccess(user),
                    icon: const Icon(Icons.agriculture_outlined, size: 16),
                    label: Text(
                      farmIds.length > 1
                          ? 'Farm access (${farmIds.length})'
                          : 'Farm access',
                    ),
                    style: TextButton.styleFrom(foregroundColor: _brandGreen),
                  ),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => _setPasswordDirectly(user),
                  icon: const Icon(Icons.password_outlined, size: 16),
                  label: const Text('Set password'),
                  style: TextButton.styleFrom(foregroundColor: _brandGreen),
                ),
                TextButton.icon(
                  onPressed: busy ? null : () => _sendPasswordReset(user),
                  icon: const Icon(Icons.mail_outline, size: 16),
                  label: const Text('Email reset link'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _UserFilter { all, active, deactivated, auditors }

/// Dialog for choosing which farms a user may access: searchable, with
/// select-all / clear, and one farm (the primary) optionally locked on.
class _FarmPickerDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> companies; // {id, name}, already sorted
  final Set<String> initial;
  final String? lockedId;

  const _FarmPickerDialog({
    required this.title,
    required this.subtitle,
    required this.companies,
    required this.initial,
    this.lockedId,
  });

  @override
  State<_FarmPickerDialog> createState() => _FarmPickerDialogState();
}

class _FarmPickerDialogState extends State<_FarmPickerDialog> {
  static const Color _green = Color(0xFF2E7D32);
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
    if (widget.lockedId != null) _selected.add(widget.lockedId!);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = widget.companies
        .where((c) => q.isEmpty || (c['name'] as String).toLowerCase().contains(q))
        .toList();
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    final canSave = _selected.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.agriculture_outlined, color: _green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(widget.subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search farms…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selected = {
                          ...widget.companies.map((c) => c['id'] as String)
                        }),
                    child: const Text('Select all'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected = {
                          if (widget.lockedId != null) widget.lockedId!
                        }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('No farms match “$_query”',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final id = visible[i]['id'] as String;
                        final name = visible[i]['name'] as String;
                        final locked = id == widget.lockedId;
                        return CheckboxListTile(
                          dense: true,
                          value: _selected.contains(id),
                          activeColor: _green,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(name,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: locked ? const Text('Primary farm') : null,
                          onChanged: locked
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(id);
                                    } else {
                                      _selected.remove(id);
                                    }
                                  }),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      canSave
                          ? '${_selected.length} selected'
                          : 'Select at least one farm',
                      style: TextStyle(
                          fontSize: 13,
                          color: canSave ? Colors.grey.shade700 : Colors.red.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: canSave ? () => Navigator.pop(context, _selected) : null,
                    style: FilledButton.styleFrom(backgroundColor: _green),
                    child: const Text('Save'),
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