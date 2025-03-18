import 'dart:typed_data';

// Import with explicit aliases to resolve naming conflicts
import 'package:cropcompliance/components/document_item_comp.dart' as components;
import 'package:cropcompliance/models/compliance_tracker_model.dart' as models;
import 'package:cropcompliance/providers/compliance_tracker_provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

class ComplianceTrackerView extends StatefulWidget {
  const ComplianceTrackerView({Key? key}) : super(key: key);

  @override
  State<ComplianceTrackerView> createState() => _ComplianceTrackerViewState();
}

class _ComplianceTrackerViewState extends State<ComplianceTrackerView> {
  // Local variables for UI state - data comes from provider
  models.SortOption _currentSortOption = models.SortOption.priority;
  models.FilterOption? _currentFilterOption;
  String _currentView = 'documents';
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();

    // Initialize data from provider
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);

    // Load data after the widget is built - with improved loading strategy
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithTimeout();
    });
  }

  // Improved loading method with timeout
  Future<void> _loadDataWithTimeout() async {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);

    try {
      // Set a reasonable timeout for initial loading
      await provider.loadUserData().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Don't throw an exception, just show a message that loading continues in background
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Still loading document files in the background...'),
                duration: Duration(seconds: 3),
              ),
            );
            // The loading will continue in the background
          }
      );
    } catch (e) {
      print('ERROR: Initial loading error: $e');

      // Show a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data. Pull down to refresh when ready.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      // Mark initial load as complete even if there were errors
      setState(() {
        _initialLoadComplete = true;
      });

      // Check for notifications after initial load
      _checkDocumentsForNotifications();
    }
  }

  // Method to mark a checklist item as completed and link it to a document
  Future<void> _markChecklistItemCompleted(models.ChecklistItem item, components.DocumentItem document) async {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    await provider.markChecklistItemCompleted(item, document);
  }

  // Method to find a checklist item by name
  models.ChecklistItem? _findChecklistItemByName(String name) {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    for (var category in provider.auditChecklist) {
      for (var item in category.items) {
        if (item.name.toLowerCase() == name.toLowerCase()) {
          return item;
        }
      }
    }
    return null;
  }

  Future<void> _uploadDocumentAlternative() async {
    try {
      // Create a mock upload for demonstration
      final String mockFileName = "Document_${DateTime.now().millisecondsSinceEpoch}.pdf";

      // Show document details dialog without an actual file
      _showAddDocumentDialog(mockFileName, null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to pick and upload a file - This doesn't change as it's just file picking
  Future<Map<String, dynamic>> _uploadDocument({
    List<String>? allowedExtensions,
    FileType fileType = FileType.any,
    bool allowMultiple = false,
  }) async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true, // Important for web to get file bytes
      );

      // Check if user canceled the picker
      if (result == null || result.files.isEmpty) {
        return {
          'success': false,
          'message': 'No file selected',
        };
      }

      // Get the selected file
      PlatformFile file = result.files.first;

      // For web, the bytes property will contain the file data
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null) {
        return {
          'success': false,
          'message': 'Could not read file bytes',
        };
      }

      return {
        'success': true,
        'message': 'File selected successfully',
        'file': file,
        'bytes': fileBytes,
        'name': file.name,
        'size': file.size,
        'extension': file.extension,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error selecting file: $e',
      };
    }
  }

  // Function to show dialog for adding document details
  void _showAddDocumentDialog(String fileName, String? filePath, {Uint8List? fileBytes}) {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    final TextEditingController titleController = TextEditingController(text: fileName);
    final TextEditingController categoryController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 90)); // Default expiry of 90 days
    components.Priority selectedPriority = components.Priority.medium;
    components.DocumentStatus selectedStatus = components.DocumentStatus.pending;

    // For checklist integration
    models.ChecklistItem? selectedChecklistItem;

    // Flatten the checklist items for the dropdown
    List<models.ChecklistItem> allChecklistItems = [];
    for (var category in provider.auditChecklist) {
      allChecklistItems.addAll(category.items);
    }

    // Sort by completion status (incomplete first)
    allChecklistItems.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Document Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<components.Priority>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
                items: components.Priority.values.map((priority) {
                  String label;
                  Color color;

                  switch (priority) {
                    case components.Priority.high:
                      label = 'High';
                      color = Colors.red;
                      break;
                    case components.Priority.medium:
                      label = 'Medium';
                      color = Colors.orange;
                      break;
                    case components.Priority.low:
                      label = 'Low';
                      color = Colors.blue;
                      break;
                  }

                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: color, size: 16),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPriority = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<components.DocumentStatus>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: components.DocumentStatus.values.map((status) {
                  String label;
                  Color color;

                  switch (status) {
                    case components.DocumentStatus.approved:
                      label = 'Approved';
                      color = Colors.green;
                      break;
                    case components.DocumentStatus.rejected:
                      label = 'Rejected';
                      color = Colors.red;
                      break;
                    case components.DocumentStatus.pending:
                      label = 'Pending';
                      color = Colors.orange;
                      break;
                  }

                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      label,
                      style: TextStyle(color: color),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStatus = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Expiry Date: '),
                  TextButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 years ahead
                      );
                      if (pickedDate != null) {
                        selectedDate = pickedDate;
                      }
                    },
                    child: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filePath != null)
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File: $fileName',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Link to Audit Checklist Item:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<models.ChecklistItem>(
                decoration: const InputDecoration(
                  labelText: 'Required Document',
                  helperText: 'Select the document type from the audit checklist',
                ),
                isExpanded: true,
                value: null, // No default value
                items: allChecklistItems.map((item) {
                  return DropdownMenuItem<models.ChecklistItem>(
                    value: item,
                    child: Row(
                      children: [
                        Icon(
                          item.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: item.isCompleted ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (models.ChecklistItem? value) {
                  selectedChecklistItem = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Check if required fields are filled
              if (titleController.text.isEmpty || categoryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Close the dialog first to show the progress indicator
              Navigator.pop(context);

              // Upload document using provider
              if (filePath != null && fileBytes != null) {
                final result = await provider.uploadDocument(
                  title: titleController.text,
                  priority: selectedPriority,
                  status: selectedStatus,
                  expiryDate: selectedDate,
                  category: categoryController.text,
                  fileName: fileName,
                  fileBytes: fileBytes,
                  linkedChecklistItem: selectedChecklistItem,
                );

                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document "${titleController.text}" added successfully'),
                      backgroundColor: const Color(0xFF28A745),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error adding document'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                // Create document without file (fallback to original behavior for demo purposes)
                final newDocument = components.DocumentItem(
                  id: provider.documents.isEmpty ? 1 : provider.documents.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1,
                  title: titleController.text,
                  priority: selectedPriority,
                  status: selectedStatus,
                  expiryDate: selectedDate,
                  category: categoryController.text,
                  filePath: filePath,
                );

                // Add to local list (this will be replaced with provider logic in real implementation)
                setState(() {
                  provider.documents.add(newDocument);
                  if (selectedChecklistItem != null) {
                    provider.markChecklistItemCompleted(selectedChecklistItem!, newDocument);
                  }
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document "${titleController.text}" added successfully (local only)'),
                    backgroundColor: const Color(0xFF28A745),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _checkDocumentsForNotifications() {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    final now = DateTime.now();
    final documents = provider.documents;

    for (final doc in documents) {
      final daysUntilExpiry = doc.expiryDate.difference(now).inDays;

      if (daysUntilExpiry < 0) {
        _showNotification('${doc.title} has expired!', isError: true);
        break; // Only show one notification at a time to avoid overwhelming the user
      } else if (daysUntilExpiry <= 10 && doc.status != components.DocumentStatus.rejected) {
        _showNotification('${doc.title} expires in $daysUntilExpiry days', isWarning: true);
        break;
      }
    }
  }

  void _showNotification(String message, {bool isError = false, bool isWarning = false}) {
    Color backgroundColor;

    if (isError) {
      backgroundColor = Colors.red;
    } else if (isWarning) {
      backgroundColor = Colors.orange;
    } else {
      backgroundColor = const Color(0xFF28A745);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            // Action for viewing document details
          },
        ),
      ),
    );
  }

  void _sortDocuments(List<components.DocumentItem> documents) {
    documents.sort((a, b) {
      switch (_currentSortOption) {
        case models.SortOption.priority:
          return a.priority.index.compareTo(b.priority.index);
        case models.SortOption.status:
          return a.status.index.compareTo(b.status.index);
        case models.SortOption.expiryDate:
          return a.expiryDate.compareTo(b.expiryDate);
        case models.SortOption.title:
          return a.title.compareTo(b.title);
      }
    });
  }

  List<components.DocumentItem> _getFilteredDocuments(List<components.DocumentItem> documents) {
    if (_currentFilterOption == null) {
      return documents;
    }

    return documents.where((doc) {
      switch (_currentFilterOption!) {
        case models.FilterOption.approved:
          return doc.status == components.DocumentStatus.approved;
        case models.FilterOption.rejected:
          return doc.status == components.DocumentStatus.rejected;
        case models.FilterOption.pending:
          return doc.status == components.DocumentStatus.pending;
        case models.FilterOption.expiringSoon:
          final daysUntilExpiry = doc.expiryDate.difference(DateTime.now()).inDays;
          return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
        case models.FilterOption.expired:
          return DateTime.now().isAfter(doc.expiryDate);
        case models.FilterOption.highPriority:
          return doc.priority == components.Priority.high;
      }
    }).toList();
  }

  // Enhanced loading overlay widget with progress bar
  Widget _buildLoadingOverlay(bool isLoading, Widget child) {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: true);

    return Stack(
      children: [
        child,
        if (isLoading || provider.isUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.isUploading) ...[
                        // Upload progress UI
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFF28A745),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Uploading Document',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.uploadStatusMessage,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: provider.uploadProgress / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF28A745),
                                  ),
                                  minHeight: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.uploadProgress < 100
                                        ? 'Uploading...'
                                        : 'Upload Complete!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${provider.uploadProgress.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF28A745),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Regular loading UI
                        const CircularProgressIndicator(
                          color: Color(0xFF28A745),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Error widget
  Widget _buildErrorWidget(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Clear error
              Provider.of<ComplianceTrackerProvider>(context, listen: false)
                  .setError(null);
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ComplianceTrackerProvider>(
      builder: (context, provider, child) {
        // Get data from provider
        final documents = provider.documents;
        final auditChecklist = provider.auditChecklist;
        final fileData = provider.fileData;
        final isLoading = provider.isLoading;
        final error = provider.error;

        // Apply sorting and filtering
        final filteredDocuments = _getFilteredDocuments(List<components.DocumentItem>.from(documents));
        _sortDocuments(filteredDocuments);

        // Calculate completion metrics from provider data
        final totalDocumentsRequired = auditChecklist.fold<int>(
            0, (sum, category) => sum + category.items.length);

        final completedDocumentsCount = auditChecklist.fold<int>(
            0, (sum, category) => sum + category.items.where((item) => item.isCompleted).length);

        final overallCompletionPercentage = totalDocumentsRequired == 0
            ? 0.0
            : (completedDocumentsCount / totalDocumentsRequired) * 100;

        return _buildLoadingOverlay(
          isLoading,
          Scaffold(
            appBar: AppBar(
              title: const Text('Compliance Tracker'),
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    provider.loadUserData();
                    _checkDocumentsForNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing data...'),
                        backgroundColor: Color(0xFF28A745),
                      ),
                    );
                  },
                ),
                PopupMenuButton<models.SortOption>(
                  icon: const Icon(Icons.sort),
                  onSelected: (option) {
                    setState(() {
                      _currentSortOption = option;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: models.SortOption.priority,
                      child: Text('Sort by Priority'),
                    ),
                    const PopupMenuItem(
                      value: models.SortOption.status,
                      child: Text('Sort by Status'),
                    ),
                    const PopupMenuItem(
                      value: models.SortOption.expiryDate,
                      child: Text('Sort by Expiry Date'),
                    ),
                    const PopupMenuItem(
                      value: models.SortOption.title,
                      child: Text('Sort by Title'),
                    ),
                  ],
                ),
                PopupMenuButton<models.FilterOption?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (option) {
                    setState(() {
                      _currentFilterOption = option;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('Show All'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.approved,
                      child: Text('Approved Only'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.rejected,
                      child: Text('Rejected Only'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.pending,
                      child: Text('Pending Only'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.expiringSoon,
                      child: Text('Expiring Soon'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.expired,
                      child: Text('Expired'),
                    ),
                    const PopupMenuItem(
                      value: models.FilterOption.highPriority,
                      child: Text('High Priority'),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Show error if present
                if (error != null) _buildErrorWidget(error),

                _buildReportSummary(documents),
                // Progress indicator for checklist completion
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            color: const Color(0xFF28A745),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Audit Document Checklist: $completedDocumentsCount of $totalDocumentsRequired completed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: overallCompletionPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF28A745)),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${overallCompletionPercentage.toStringAsFixed(1)}% complete',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentView = 'documents';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _currentView == 'documents'
                                  ? const Color(0xFF28A745)
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Documents',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _currentView == 'documents'
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentView = 'checklist';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _currentView == 'checklist'
                                  ? const Color(0xFF28A745)
                                  : Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Audit Checklist',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _currentView == 'checklist'
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content area
                Expanded(
                  child: _currentView == 'documents'
                      ? (filteredDocuments.isEmpty
                      ? _buildEmptyState()
                      : _buildDocumentList(filteredDocuments, fileData))
                      : _buildChecklistView(auditChecklist, fileData),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final result = await _uploadDocument(
                  fileType: FileType.any,
                );

                if (result['success']) {
                  // Access file data
                  final fileName = result['name'];
                  final fileBytes = result['bytes'];

                  // Show the document dialog with the file name and bytes
                  _showAddDocumentDialog(
                    fileName,
                    fileName,  // Using filename as the path identifier
                    fileBytes: fileBytes,
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Error uploading file'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF28A745),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No documents found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentFilterOption != null
                ? 'Try changing your filter'
                : 'Add some documents to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary(List<components.DocumentItem> documents) {
    final totalDocuments = documents.length;
    final approvedCount = documents.where((doc) => doc.status == components.DocumentStatus.approved).length;
    final rejectedCount = documents.where((doc) => doc.status == components.DocumentStatus.rejected).length;
    final pendingCount = documents.where((doc) => doc.status == components.DocumentStatus.pending).length;

    final now = DateTime.now();
    final expiredCount = documents.where((doc) => doc.expiryDate.isBefore(now)).length;
    final expiringSoonCount = documents.where((doc) {
      final daysUntilExpiry = doc.expiryDate.difference(now).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compliance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total',
                totalDocuments.toString(),
                Icons.folder,
              ),
              _buildSummaryItem(
                'Approved',
                approvedCount.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              _buildSummaryItem(
                'Pending',
                pendingCount.toString(),
                Icons.pending,
                color: Colors.orange,
              ),
              _buildSummaryItem(
                'Rejected',
                rejectedCount.toString(),
                Icons.cancel,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$expiringSoonCount Expiring Soon',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$expiredCount Expired',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon,
      {Color color = const Color(0xFF343A40)}) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  // Updated View document function with on-demand loading
  void _viewDocument(components.DocumentItem document, Map<String, Uint8List> fileData) async {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);

    if (document.filePath != null) {
      // Check if we have the file data in memory
      Uint8List? fileBytes = fileData[document.filePath];

      // If not in cache, try to load it on demand
      if (fileBytes == null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading document, please wait...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Try to download the file on demand
        fileBytes = await provider.getDocumentFile(document);
      }

      if (fileBytes != null) {
        // Determine file type from extension to handle it appropriately
        final extension = document.filePath!.split('.').last.toLowerCase();

        // Show a dialog with the file content
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Display file content based on type
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildFilePreview(extension, fileBytes!),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load file for: ${document.title}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file associated with this document'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Helper method to display the file content based on its type
  Widget _buildFilePreview(String extension, Uint8List fileBytes) {
    // Handle different file types
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Image.memory(fileBytes);
      case 'pdf':
        return Column(
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'PDF Viewer not implemented in this example',
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'txt':
      // Display text content
        try {
          final text = String.fromCharCodes(fileBytes);
          return Text(text);
        } catch (e) {
          return Text('Error displaying text file: $e');
        }
      default:
      // Generic file preview
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'File type .$extension',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${(fileBytes.length / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        );
    }
  }

  // Update document function - using provider
  void _updateDocument(components.DocumentItem document) {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    _showAddDocumentDialog(document.title, document.filePath);
  }

  Widget _buildDocumentList(List<components.DocumentItem> documents, Map<String, Uint8List> fileData) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        final isExpired = DateTime.now().isAfter(document.expiryDate);
        final daysUntilExpiry = document.expiryDate.difference(DateTime.now()).inDays;
        final isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPriorityBadge(document.priority),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        document.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(document.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Category: ${document.category}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isExpired
                              ? Colors.red
                              : isExpiringSoon
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expires: ${_formatDate(document.expiryDate)}',
                          style: TextStyle(
                            color: isExpired
                                ? Colors.red
                                : isExpiringSoon
                                ? Colors.orange
                                : Colors.grey[600],
                            fontSize: 14,
                            fontWeight: isExpired || isExpiringSoon
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Show file status indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: fileData.containsKey(document.filePath)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fileData.containsKey(document.filePath)
                                ? Icons.check_circle
                                : Icons.cloud_download,
                            color: fileData.containsKey(document.filePath)
                                ? Colors.green
                                : Colors.grey,
                            size: 12,
                          ),
                          SizedBox(width: 4),
                          Text(
                            fileData.containsKey(document.filePath)
                                ? 'Available'
                                : 'Load on view',
                            style: TextStyle(
                              fontSize: 10,
                              color: fileData.containsKey(document.filePath)
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () => _viewDocument(document, fileData),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF28A745),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _updateDocument(document),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Update'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(components.Priority priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case components.Priority.high:
        icon = Icons.flag;
        color = Colors.red;
        break;
      case components.Priority.medium:
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case components.Priority.low:
        icon = Icons.flag;
        color = Colors.blue;
        break;
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildStatusBadge(components.DocumentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case components.DocumentStatus.approved:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Approved';
        break;
      case components.DocumentStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Rejected';
        break;
      case components.DocumentStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Build the checklist view - using data from provider
  Widget _buildChecklistView(List<models.ChecklistCategory> auditChecklist, Map<String, Uint8List> fileData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: auditChecklist.length,
      itemBuilder: (context, index) {
        final category = auditChecklist[index];
        return _buildChecklistCategory(category, fileData);
      },
    );
  }

  Widget _buildChecklistCategory(models.ChecklistCategory category, Map<String, Uint8List> fileData) {
    // Calculate completion for this category
    final completedCount = category.items.where((item) => item.isCompleted).length;
    final percentage = category.completionPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$completedCount/${category.items.length} completed'),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: percentage == 100 ? Colors.green : Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage == 100 ? Colors.green : const Color(0xFF28A745),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
        children: category.items.map((item) => _buildChecklistItem(item, fileData)).toList(),
      ),
    );
  }

  Widget _buildChecklistItem(models.ChecklistItem item, Map<String, Uint8List> fileData) {
    return ListTile(
      leading: Icon(
        item.isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color: item.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          color: item.isCompleted ? Colors.grey[600] : Colors.black,
        ),
      ),
      subtitle: item.linkedDocument != null
          ? Text(
        'Document: ${item.linkedDocument!.title}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.blue,
        ),
      )
          : null,
      trailing: item.linkedDocument != null
          ? TextButton.icon(
        onPressed: () => _viewDocument(item.linkedDocument!, fileData),
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('View'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF28A745),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      )
          : TextButton.icon(
        onPressed: () => _uploadForChecklistItem(item),
        icon: const Icon(Icons.upload_file, size: 16),
        label: const Text('Upload'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  // Method to handle uploading for a specific checklist item
  void _uploadForChecklistItem(models.ChecklistItem item) async {
    final provider = Provider.of<ComplianceTrackerProvider>(context, listen: false);
    final result = await _uploadDocument(
      fileType: FileType.any,
    );

    if (result['success']) {
      // Access file data
      final fileName = result['name'];
      final fileBytes = result['bytes'];

      // Pre-select this checklist item and open the dialog
      final TextEditingController titleController = TextEditingController(text: item.name);

      // Find parent category for this item
      String categoryName = '';
      for (var category in provider.auditChecklist) {
        if (category.items.contains(item)) {
          categoryName = category.name.split('.').last.trim();
          break;
        }
      }

      final TextEditingController categoryController = TextEditingController(text: categoryName);
      DateTime selectedDate = DateTime.now().add(const Duration(days: 90));
      components.Priority selectedPriority = components.Priority.medium;
      components.DocumentStatus selectedStatus = components.DocumentStatus.pending;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Document Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<components.Priority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                  ),
                  items: components.Priority.values.map((priority) {
                    String label;
                    Color color;

                    switch (priority) {
                      case components.Priority.high:
                        label = 'High';
                        color = Colors.red;
                        break;
                      case components.Priority.medium:
                        label = 'Medium';
                        color = Colors.orange;
                        break;
                      case components.Priority.low:
                        label = 'Low';
                        color = Colors.blue;
                        break;
                    }

                    return DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: color, size: 16),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedPriority = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Expiry Date: '),
                    TextButton(
                      onPressed: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (pickedDate != null) {
                          selectedDate = pickedDate;
                        }
                      },
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File: $fileName',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This document will be linked to: ${item.name}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Close the dialog first to show progress dialog
                Navigator.pop(context);

                // Upload using provider with progress tracking
                final result = await provider.uploadDocument(
                  title: titleController.text,
                  priority: selectedPriority,
                  status: selectedStatus,
                  expiryDate: selectedDate,
                  category: categoryController.text,
                  fileName: fileName,
                  fileBytes: fileBytes,
                  linkedChecklistItem: item,
                );

                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document "${titleController.text}" added successfully'),
                      backgroundColor: const Color(0xFF28A745),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error adding document'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error uploading file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}