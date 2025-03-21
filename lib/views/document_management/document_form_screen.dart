import 'package:cropcompliance/core/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import 'widgets/document_form_builder.dart';

class DocumentFormScreen extends StatefulWidget {
  final String categoryId;
  final String documentTypeId;

  const DocumentFormScreen({
    Key? key,
    required this.categoryId,
    required this.documentTypeId,
  }) : super(key: key);

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final Map<String, dynamic> _formData = {};
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.initialize();
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _submitForm() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    // Get document type to check if expiry date is required
    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == widget.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    if (documentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document type not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (documentType.hasExpiryDate && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (authProvider.currentUser != null) {
        final document = await documentProvider.createDocument(
          user: authProvider.currentUser!,
          categoryId: widget.categoryId,
          documentTypeId: widget.documentTypeId,
          files: [],
          formData: _formData,
          expiryDate: _expiryDate,
        );

        if (document != null && mounted) {
          Navigator.of(context).pop();

          if (documentType.requiresSignature) {
            Navigator.of(context).pushNamed(
              RouteConstants.documentDetail,
              arguments: {'documentId': document.id},
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: const LoadingIndicator(message: 'Loading document type...'),
      );
    }

    if (categoryProvider.error != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: ErrorDisplay(
          error: categoryProvider.error!,
          onRetry: _initializeData,
        ),
      );
    }

    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == widget.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    if (documentType == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Document type not found'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fill ${documentType.name}',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentType.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Use form builder based on document type
                DocumentFormBuilder(
                  documentType: documentType,
                  onFormDataChanged: (key, value) {
                    setState(() {
                      _formData[key] = value;
                    });
                  },
                ),

                if (documentType.hasExpiryDate) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: _expiryDate != null
                        ? Text(
                      '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    )
                        : const Text('Select expiry date'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectExpiryDate,
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Submit Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}