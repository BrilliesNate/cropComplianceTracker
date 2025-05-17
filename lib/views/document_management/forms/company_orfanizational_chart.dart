import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

class CompanyOrganizationalChart extends StatefulWidget {
  const CompanyOrganizationalChart({Key? key}) : super(key: key);

  @override
  State<CompanyOrganizationalChart> createState() => _CompanyOrganizationalChartState();
}

class _CompanyOrganizationalChartState extends State<CompanyOrganizationalChart> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _approvedController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Signature controller
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  // Signature image
  Uint8List? _signatureImage;

  // Role controllers - all empty by default
  final Map<String, TextEditingController> _roleControllers = {
    'PERSON RESPONSIBLE FOR IMPLEMENTING THE ETHICAL CODE:': TextEditingController(),
    'CHIEF HEALTH AND SAFETY PERSON 16(1):': TextEditingController(),
    'CHIEF HEALTH AND SAFETY OFFICER 16(2):': TextEditingController(),
    'INCIDENT INVESTIGATOR:': TextEditingController(),
    'FIRE/EMERGENCY COORDINATOR:': TextEditingController(),
    'CHEMICAL COORDINATOR:': TextEditingController(),
    'SUPERVISER OF MACHINERY:': TextEditingController(),
    'LADDER INSPECTOR:': TextEditingController(),
    'STACKING AND STORAGE COORDINATOR:': TextEditingController(),
    'WORKER REPRESENTATIVE:': TextEditingController(),
    'HEALTH AND SAFETY REPRESENTATIVE:': TextEditingController(),
    'FIRST AID OFFICER:': TextEditingController(),
    'FIRE-FIGHTING TEAM MEMBERS:': TextEditingController(),
    'FORKLIFT OPERATORS:': TextEditingController(),
    'TRACTOR OPERATORS:': TextEditingController(),
    'CHEMICAL OPERATORS:': TextEditingController(),
  };

  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _approvedController.dispose();
    _dateController.dispose();
    _signatureController.dispose();

    for (var controller in _roleControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Show signature dialog
  void _showSignatureDialog() {
    // Clear previous signature
    _signatureController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Your Signature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Sign below:'),
              const SizedBox(height: 16),
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _signatureController.clear();
                    },
                    child: const Text('Clear'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_signatureController.isNotEmpty) {
                        final signatureImage = await _signatureController.toPngBytes();
                        setState(() {
                          _signatureImage = signatureImage;
                        });
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Save Signature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveDocument() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showSuccessMessage = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccessMessage = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Organizational Chart'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSuccessMessage)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Document saved successfully!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/svg/logoIcon.svg',
                              width: 32,
                              height: 32,

                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Name (PTY) LTD',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text('Company Organizational Chart'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Document info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Document Number'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _documentNumberController,
                                  decoration: _inputDecoration(''),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date *'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: _selectDate,
                                  decoration: _inputDecoration(''),
                                  validator: (value) => value!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Approved'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _approvedController,
                                  decoration: _inputDecoration(''),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Signature'),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _showSignatureDialog,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _signatureImage == null
                                        ? const Center(
                                      child: Text('Click to sign'),
                                    )
                                        : Image.memory(_signatureImage!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Roles table
                      ..._roleControllers.entries.map((entry) => _buildRoleField(entry.key, entry.value)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Save Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildRoleField(String role, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: Text(
              role,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: _inputDecoration('Enter name'),
            ),
          ),
        ],
      ),
    );
  }
}