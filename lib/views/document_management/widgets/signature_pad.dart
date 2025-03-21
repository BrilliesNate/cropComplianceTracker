import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class SignaturePad extends StatefulWidget {
  final Function(File) onSave;

  const SignaturePad({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  final GlobalKey _signatureKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: RepaintBoundary(
              key: _signatureKey,
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              onPressed: _clear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: _isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('Save'),
              onPressed: _isSaving || _points.isEmpty ? null : _save,
            ),
          ],
        ),
      ],
    );
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _save() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final boundary = _signatureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // also need to fix getTemporaryDirectory

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      widget.onSave(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}