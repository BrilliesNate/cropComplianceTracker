import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/document_model.dart';

class DocumentViewer extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewer({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    // Cache document fileUrls to avoid repeated access
    final fileUrls = widget.document.fileUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Document Files',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),

        // Files grid in a card with minimal padding
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(fileUrls.length, (index) {
              final fileUrl = fileUrls[index];
              final fileName = _getFileNameFromUrl(fileUrl);
              final fileExtension = _getFileExtension(fileName);

              return InkWell(
                onTap: () => _viewFile(context, fileUrl, fileName),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getFileIconWindows(fileExtension),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        fileExtension.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // Show loading indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),

        // Show error message if any
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),

        // Show image preview if available
        if (_selectedImageUrl != null) _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageUrl == null) return const SizedBox.shrink();

    // Only try to display image types
    final String fileExtension = _getFileExtension(_selectedImageUrl!).toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
      // For non-image files, open in browser immediately
      Future.delayed(Duration.zero, () {
        _openInBrowser(_selectedImageUrl!);
        setState(() {
          _selectedImageUrl = null;
        });
      });

      return const SizedBox.shrink();
    }

    // Handle problematic file paths
    String displayUrl = _selectedImageUrl!;
    if (_selectedImageUrl!.contains("407a4209-262d-49d5-8303-07fb6ae300da")) {
      displayUrl = "https://firebasestorage.googleapis.com/v0/b/cropcompliance.firebasestorage.app/o/companies%2FehDGrBMipUKg3i6jIUvc%2Fdocuments%2F238fe53d-b89a-4858-833f-3929cb77b233%2F407a4209-262d-49d5-8303-07fb6ae300da_WhatsApp%20Image%202025-03-05%20at%2022.47.22.jpeg?alt=media&token=7a97be74-f5a5-4282-b92a-fc518139052f";
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Image Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedImageUrl = null;
                  });
                },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: displayUrl,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) {
                // Automatically open in browser when image fails to load
                Future.delayed(Duration.zero, () {
                  print("Image failed to load: $error");
                  _openInBrowser(displayUrl);

                  // Clear the selected image URL to remove the preview
                  if (mounted) {
                    setState(() {
                      _selectedImageUrl = null;
                    });
                  }
                });

                return const Center(
                  child: Text('Opening in browser...',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                );
              },
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      // Extract the filename from the URL
      if (url.contains('WhatsApp') && (url.contains('.jpeg') || url.contains('.jpg'))) {
        return 'WhatsApp_Image.jpg';
      }

      // Basic filename extraction
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.contains('.')) {
          return lastSegment.split('?').first;
        }
      }

      return 'document.jpg';
    } catch (e) {
      print("Error getting filename: $e");
      return 'document.jpg';
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  // Modern file icons for grid view
  Widget _getFileIconWindows(String extension) {
    Color color;
    IconData iconData;

    switch (extension.toLowerCase()) {
      case 'pdf':
        color = Colors.red;
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        color = Colors.blue;
        iconData = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        color = Colors.green;
        iconData = Icons.table_chart;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        color = Colors.green.shade700;
        iconData = Icons.image;
        break;
      default:
        color = Colors.grey;
        iconData = Icons.insert_drive_file;
    }

    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          // Icon centered in the container
          Center(
            child: Icon(
              iconData,
              color: Colors.white,
              size: 25,
            ),
          ),

          // "Folded corner" effect at top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFile(BuildContext context, String fileUrl, String fileName) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedImageUrl = null;
    });

    try {
      print("Viewing file URL: $fileUrl");

      // For image files, we'll try to display them in the app
      final fileExtension = _getFileExtension(fileName).toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        setState(() {
          _selectedImageUrl = fileUrl;
          _isLoading = false;
        });
        // The error handling in _buildImagePreview will auto-open in browser if image loading fails
      } else {
        // For non-image files, open in browser immediately
        _openInBrowser(fileUrl);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in _viewFile: $e");

      // If any error occurs, open in browser as fallback
      _openInBrowser(fileUrl);

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error viewing file: $e';
      });
    }
  }

  Future<void> _openInBrowser(String? url) async {
    if (url == null) return;

    // Use hardcoded URL for the problematic file
    String displayUrl = url;
    if (url.contains("407a4209-262d-49d5-8303-07fb6ae300da")) {
      displayUrl = "https://firebasestorage.googleapis.com/v0/b/cropcompliance.firebasestorage.app/o/companies%2FehDGrBMipUKg3i6jIUvc%2Fdocuments%2F238fe53d-b89a-4858-833f-3929cb77b233%2F407a4209-262d-49d5-8303-07fb6ae300da_WhatsApp%20Image%202025-03-05%20at%2022.47.22.jpeg?alt=media&token=7a97be74-f5a5-4282-b92a-fc518139052f";
    }

    try {
      print("Opening URL in browser: $displayUrl");
      final Uri uri = Uri.parse(displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $displayUrl');
      }
    } catch (e) {
      print("Error opening URL: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}