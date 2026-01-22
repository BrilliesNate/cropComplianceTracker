import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../core/services/firestore_service.dart';
import '../../models/company_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _createNewCompany = true;
  String? _selectedCompanyId;

  final FirestoreService _firestoreService = FirestoreService();
  List<CompanyModel> _companies = [];
  bool _isLoadingCompanies = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
    });

    final companies = await _firestoreService.getCompanies();

    setState(() {
      _companies = companies;
      _isLoadingCompanies = false;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String companyId = _selectedCompanyId ?? '';

      // Create new company if needed
      if (_createNewCompany) {
        final company = CompanyModel(
          id: '',
          name: _companyNameController.text.trim(),
          address: _addressController.text.trim(),
          createdAt: DateTime.now(),
          packages: ['siza_wieta'],  // ADD THIS LINE
        );

        companyId = await _firestoreService.addCompany(company) ?? '';
      }

      if (companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create company. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyId: companyId,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.agriculture,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create an Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
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
                          Text(_createNewCompany
                              ? 'New Company'
                              : 'Existing Company'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_createNewCompany) ...[
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (_createNewCompany &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Company Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (_createNewCompany &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter company address';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        _isLoadingCompanies
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Company',
                                  prefixIcon: Icon(Icons.business),
                                ),
                                value: _selectedCompanyId,
                                items: _companies.map((company) {
                                  return DropdownMenuItem<String>(
                                    value: company.id,
                                    child: Text(company.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompanyId = value;
                                  });
                                },
                                validator: (value) {
                                  if (!_createNewCompany &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please select a company';
                                  }
                                  return null;
                                },
                              ),
                      ],
                      const SizedBox(height: 24),
                      if (authProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _register,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Register'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed(RouteConstants.login);
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
