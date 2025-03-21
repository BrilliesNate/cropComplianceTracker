import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../audit_tracker/widgets/document_upload_card.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String categoryId;
  final String documentTypeId;

  const DocumentUploadScreen({
    Key? key,
    required this.categoryId,
    required this.documentTypeId,
  }) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
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

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: const LoadingIndicator(message: 'Loading document type...'),
      );
    }

    if (categoryProvider.error != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: ErrorDisplay(
          error: categoryProvider.error!,
          onRetry: _initializeData,
        ),
      );
    }

    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    final documentType = documentTypes.firstWhere(
          (dt) => dt.id == widget.documentTypeId,
      orElse: () => DocumentTypeModel(
        id: '',
        categoryId: '',
        name: 'Unknown Document Type',
        allowMultipleDocuments: false,
        isUploadable: true,
        hasExpiryDate: false,
        hasNotApplicableOption: false,
        requiresSignature: false,
        signatureCount: 0,
      ),
    );

    if (documentType.id.isEmpty) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Document type not found'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Upload ${documentType.name}',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: DocumentUploadCard(
          categoryId: widget.categoryId,
          documentType: documentType,
        ),
      ),
    );
  }
}