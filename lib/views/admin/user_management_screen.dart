import 'package:cropCompliance/providers/auth_provider.dart' as autPro;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
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
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
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
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final companiesSnapshot = await FirebaseFirestore.instance.collection('companies').get();
      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList();

      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = usersSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _companies = companies;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: \$e';
        _isLoading = false;
      });
    }
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
        _error = 'Error creating company: \$e';
      });
      return null;
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_createNewCompany && _selectedCompanyId == null) {
      setState(() {
        _error = 'Please select a company';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? companyId = _selectedCompanyId;
      if (_createNewCompany) {
        companyId = await _createCompany();
        if (companyId == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': _selectedRole.toString().split('.').last,
          'companyId': companyId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _companyNameController.clear();
        _companyAddressController.clear();
        _selectedRole = UserRole.USER;
        _createNewCompany = false;
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error creating user: \$e';
        _isLoading = false;
      });
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
    // If you’d like, I can regenerate the full widget tree using the new compact modern input style.

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
                          decoration: _modernInputDecoration('Select Company'),
                          value: _selectedCompanyId,
                          items: _companies.map((company) {
                            return DropdownMenuItem<String>(
                              value: company['id'] as String,
                              child: Text(company['name'] as String),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCompanyId = value;
                            });
                          },
                          validator: (value) {
                            if (!_createNewCompany && (value == null || value.isEmpty)) {
                              return 'Please select a company';
                            }
                            return null;
                          },
                        ),
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
                            });
                          }
                        },
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
            Text(
              'Existing Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Chip(
                      label: Text(user.role.name),
                      backgroundColor: _getRoleColor(user.role),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return Colors.purple.shade100;
      case UserRole.AUDITER:
        return Colors.blue.shade100;
      case UserRole.USER:
        return Colors.green.shade100;
    }
  }
}
