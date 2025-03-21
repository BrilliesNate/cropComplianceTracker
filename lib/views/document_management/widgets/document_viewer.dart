import 'package:flutter/material.dart';
import '../../../models/document_model.dart';

class DocumentViewer extends StatelessWidget {
  final DocumentModel document;

  const DocumentViewer({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uploaded Files',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: document.fileUrls.length,
              itemBuilder: (context, index) {
                final fileUrl = document.fileUrls[index];
                final fileName = _getFileNameFromUrl(fileUrl);
                final fileExtension = _getFileExtension(fileName);

                return Card(
                  elevation: 0,
                  color: Colors.grey.shade100,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _getFileIcon(fileExtension),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(fileExtension.toUpperCase()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: 'View',
                          onPressed: () {
                            _viewFile(context, fileUrl, fileName);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download',
                          onPressed: () {
                            _downloadFile(context, fileUrl, fileName);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last.split('?').first;
    }
    return 'File';
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  Widget _getFileIcon(String extension) {
    IconData iconData;
    Color color;

    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(
        iconData,
        color: color,
      ),
    );
  }

  void _viewFile(BuildContext context, String fileUrl, String fileName) {
    // In a real app, you would open a WebView or a PDF viewer
    // For now, we'll just show a dialog with the file URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View $fileName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('File would be displayed here in a real app.'),
            const SizedBox(height: 16),
            Text(
              'URL: $fileUrl',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(BuildContext context, String fileUrl, String fileName) {
    // In a real app, you would implement file download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
      ),
    );
  }
}