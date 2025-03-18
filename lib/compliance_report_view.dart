import 'package:flutter/material.dart';

class ComplianceReportView extends StatefulWidget {
  const ComplianceReportView({Key? key}) : super(key: key);

  @override
  State<ComplianceReportView> createState() => _ComplianceReportViewState();
}

class _ComplianceReportViewState extends State<ComplianceReportView> {
  final List<DocumentItem> _documents = [
    DocumentItem(
      id: 1,
      title: 'WIETA Certificate',
      priority: Priority.high,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      category: 'Ethical Trading',
      feedback: 'Approved by regional inspector',
    ),
    DocumentItem(
      id: 2,
      title: 'SIZA Audit Report',
      priority: Priority.high,
      status: DocumentStatus.pending,
      expiryDate: DateTime.now().add(const Duration(days: 10)),
      category: 'Social Responsibility',
      feedback: 'Awaiting final review',
    ),
    DocumentItem(
      id: 3,
      title: 'GlobalGAP Registration',
      priority: Priority.medium,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      category: 'Food Safety & Quality',
      feedback: 'Renewal reminder set',
    ),
    DocumentItem(
      id: 4,
      title: 'Health & Safety Assessment',
      priority: Priority.high,
      status: DocumentStatus.rejected,
      expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Health & Safety',
      feedback: 'Missing safety protocols',
    ),
    DocumentItem(
      id: 5,
      title: 'Water Usage License',
      priority: Priority.medium,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 90)),
      category: 'Water Management',
      feedback: 'Approved for 3 years',
    ),
    DocumentItem(
      id: 6,
      title: 'Environmental Impact Assessment',
      priority: Priority.low,
      status: DocumentStatus.pending,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      category: 'Environmental Management',
      feedback: 'Awaiting soil test results',
    ),
    DocumentItem(
      id: 7,
      title: 'Worker Training Records',
      priority: Priority.medium,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      category: 'Labor & Working Conditions',
      feedback: 'All staff completed training',
    ),
    DocumentItem(
      id: 8,
      title: 'Pesticide Usage Records',
      priority: Priority.high,
      status: DocumentStatus.pending,
      expiryDate: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Chemical Management',
      feedback: 'Additional data required',
    ),
    DocumentItem(
      id: 9,
      title: 'Product Traceability System',
      priority: Priority.high,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 220)),
      category: 'Product Traceability',
      feedback: 'All requirements met',
    ),
    DocumentItem(
      id: 10,
      title: 'Waste Disposal Contract',
      priority: Priority.medium,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 110)),
      category: 'Waste Management',
      feedback: 'Contract renewed with certified provider',
    ),
    DocumentItem(
      id: 11,
      title: 'Energy Consumption Report',
      priority: Priority.low,
      status: DocumentStatus.pending,
      expiryDate: DateTime.now().add(const Duration(days: 25)),
      category: 'Energy Management',
      feedback: 'Waiting for utility verification',
    ),
    DocumentItem(
      id: 12,
      title: 'IPM Implementation Plan',
      priority: Priority.medium,
      status: DocumentStatus.approved,
      expiryDate: DateTime.now().add(const Duration(days: 155)),
      category: 'Pest Control & IPM',
      feedback: 'Successfully implemented',
    ),
  ];

  SortOption _currentSortOption = SortOption.priority;
  FilterOption? _currentFilterOption;

  // Column flex values to ensure consistent alignment
  static const int nameColumnFlex = 4;
  static const int dateColumnFlex = 3;
  static const int statusColumnFlex = 2;
  static const int categoryColumnFlex = 3;
  static const int feedbackColumnFlex = 3;

  @override
  void initState() {
    super.initState();
    _sortDocuments();

    // Check for documents that need attention
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDocumentsForNotifications();
    });
  }

  void _checkDocumentsForNotifications() {
    final now = DateTime.now();

    for (final doc in _documents) {
      final daysUntilExpiry = doc.expiryDate.difference(now).inDays;

      if (daysUntilExpiry < 0) {
        _showNotification('${doc.title} has expired!', isError: true);
        break; // Only show one notification
      } else if (daysUntilExpiry <= 10 && doc.status != DocumentStatus.rejected) {
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

  void _sortDocuments() {
    setState(() {
      switch (_currentSortOption) {
        case SortOption.priority:
          _documents.sort((a, b) => a.priority.index.compareTo(b.priority.index));
          break;
        case SortOption.status:
          _documents.sort((a, b) => a.status.index.compareTo(b.status.index));
          break;
        case SortOption.expiryDate:
          _documents.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          break;
        case SortOption.title:
          _documents.sort((a, b) => a.title.compareTo(b.title));
          break;
        case SortOption.category:
          _documents.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
    });
  }

  List<DocumentItem> _getFilteredDocuments() {
    if (_currentFilterOption == null) {
      return _documents;
    }

    return _documents.where((doc) {
      switch (_currentFilterOption!) {
        case FilterOption.approved:
          return doc.status == DocumentStatus.approved;
        case FilterOption.rejected:
          return doc.status == DocumentStatus.rejected;
        case FilterOption.pending:
          return doc.status == DocumentStatus.pending;
        case FilterOption.expiringSoon:
          final daysUntilExpiry = doc.expiryDate.difference(DateTime.now()).inDays;
          return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
        case FilterOption.expired:
          return DateTime.now().isAfter(doc.expiryDate);
        case FilterOption.highPriority:
          return doc.priority == Priority.high;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocuments = _getFilteredDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Report'),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _sortDocuments();
              _checkDocumentsForNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report refreshed'),
                  backgroundColor: Color(0xFF28A745),
                ),
              );
            },
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              setState(() {
                _currentSortOption = option;
                _sortDocuments();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.priority,
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem(
                value: SortOption.status,
                child: Text('Sort by Status'),
              ),
              const PopupMenuItem(
                value: SortOption.expiryDate,
                child: Text('Sort by Expiry Date'),
              ),
              const PopupMenuItem(
                value: SortOption.title,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                value: SortOption.category,
                child: Text('Sort by Category'),
              ),
            ],
          ),
          PopupMenuButton<FilterOption?>(
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
                value: FilterOption.approved,
                child: Text('Approved Only'),
              ),
              const PopupMenuItem(
                value: FilterOption.rejected,
                child: Text('Rejected Only'),
              ),
              const PopupMenuItem(
                value: FilterOption.pending,
                child: Text('Pending Only'),
              ),
              const PopupMenuItem(
                value: FilterOption.expiringSoon,
                child: Text('Expiring Soon'),
              ),
              const PopupMenuItem(
                value: FilterOption.expired,
                child: Text('Expired'),
              ),
              const PopupMenuItem(
                value: FilterOption.highPriority,
                child: Text('High Priority'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildReportSummary(),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[200],
            child: Row(
              children: [
                // Document Name column (includes space for priority icon)
                Expanded(
                  flex: nameColumnFlex,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: const Text(
                      'Document Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Expiry Date column
                Expanded(
                  flex: dateColumnFlex,
                  child: const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Status column
                Expanded(
                  flex: statusColumnFlex,
                  child: const Center(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Category column
                Expanded(
                  flex: categoryColumnFlex,
                  child: const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Feedback column
                Expanded(
                  flex: feedbackColumnFlex,
                  child: const Text(
                    'Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredDocuments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: filteredDocuments.length,
              itemBuilder: (context, index) {
                return _buildDocumentRow(filteredDocuments[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add action for adding new document
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add new document'),
              backgroundColor: Color(0xFF28A745),
            ),
          );
        },
        backgroundColor: const Color(0xFF28A745),
        child: const Icon(Icons.add),
      ),
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

  Widget _buildReportSummary() {
    final totalDocuments = _documents.length;
    final approvedCount = _documents.where((doc) => doc.status == DocumentStatus.approved).length;
    final rejectedCount = _documents.where((doc) => doc.status == DocumentStatus.rejected).length;
    final pendingCount = _documents.where((doc) => doc.status == DocumentStatus.pending).length;

    final now = DateTime.now();
    final expiredCount = _documents.where((doc) => doc.expiryDate.isBefore(now)).length;
    final expiringSoonCount = _documents.where((doc) {
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

  Widget _buildDocumentRow(DocumentItem document, int index) {
    final isExpired = DateTime.now().isAfter(document.expiryDate);
    final daysUntilExpiry = document.expiryDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry > 0;

    // Alternating row colors
    final backgroundColor = index % 2 == 0
        ? Colors.white
        : Colors.grey[50];

    return InkWell(
      onTap: () {
        // View document details action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viewing document: ${document.title}'),
            backgroundColor: const Color(0xFF28A745),
          ),
        );
      },
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Priority + Document Name
            Expanded(
              flex: nameColumnFlex,
              child: Row(
                children: [
                  _buildPriorityIcon(document.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Expiry Date
            Expanded(
              flex: dateColumnFlex,
              child: Row(
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
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(document.expiryDate),
                    style: TextStyle(
                      color: isExpired
                          ? Colors.red
                          : isExpiringSoon
                          ? Colors.orange
                          : null,
                      fontWeight: (isExpired || isExpiringSoon)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Status
            Expanded(
              flex: statusColumnFlex,
              child: Center(
                child: _buildStatusBadge(document.status),
              ),
            ),
            // Category
            Expanded(
              flex: categoryColumnFlex,
              child: Text(
                document.category,
                style: TextStyle(
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Feedback
            Expanded(
              flex: feedbackColumnFlex,
              child: Text(
                document.feedback,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIcon(Priority priority) {
    IconData icon;
    Color color;

    switch (priority) {
      case Priority.high:
        icon = Icons.flag;
        color = Colors.red;
        break;
      case Priority.medium:
        icon = Icons.flag;
        color = Colors.orange;
        break;
      case Priority.low:
        icon = Icons.flag;
        color = Colors.blue;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 16,
    );
  }

  Widget _buildStatusBadge(DocumentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case DocumentStatus.approved:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        label = 'Approved';
        break;
      case DocumentStatus.rejected:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        label = 'Rejected';
        break;
      case DocumentStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class DocumentItem {
  final int id;
  final String title;
  final Priority priority;
  final DocumentStatus status;
  final DateTime expiryDate;
  final String category;
  final String feedback;

  DocumentItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.expiryDate,
    required this.category,
    required this.feedback,
  });
}

enum Priority {
  high,
  medium,
  low,
}

enum DocumentStatus {
  approved,
  rejected,
  pending,
}

enum SortOption {
  priority,
  status,
  expiryDate,
  title,
  category,
}

enum FilterOption {
  approved,
  rejected,
  pending,
  expiringSoon,
  expired,
  highPriority,
}