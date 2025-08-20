import 'dart:typed_data';

import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageTextOverlayDemo(),
    );
  }
}

class ImageTextOverlayDemo extends StatefulWidget {
  const ImageTextOverlayDemo({super.key});

  @override
  State<ImageTextOverlayDemo> createState() => _ImageTextOverlayDemoState();
}

class _ImageTextOverlayDemoState extends State<ImageTextOverlayDemo> {
  final TextEditingController _textController = TextEditingController();
  String? _addedText;
  Uint8List? _processedImage;

  /// For draggable image position
  double _imageX = 100;
  double _imageY = 200;

  /// For draggable text position + scaling
  double _textX = 50;
  double _textY = 50;
  double _textScale = 1.0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndRemoveBg() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();

      // Remove background
      final Uint8List? result = await removeBackground(imageBytes: bytes);

      if (result != null) {
        setState(() {
          _processedImage = result;
          _imageX = 100;
          _imageY = 200;
        });
      }
    }
  }

  void _addText() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter some text")),
      );
      return;
    }
    setState(() {
      _addedText = _textController.text.trim();
      _textScale = 1.0; // reset scale on new text
      _textX = 50; // reset position
      _textY = 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// ====== Editor Box ======
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SizedBox(
                height: 400, // fixed height
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    /// Static background image
                    Image.asset(
                      "assets/background.jpg",
                      fit: BoxFit.cover,
                    ),

                    /// Movable & Scalable Text (BEHIND image)
                    /// Movable & Scalable Text (BEHIND image)
                    if (_addedText != null)
                      Positioned(
                        left: _textX,
                        top: _textY,
                        child: GestureDetector(
                          onScaleUpdate: (details) {
                            setState(() {
                              // Move (translation)
                              _textX += details.focalPointDelta.dx;
                              _textY += details.focalPointDelta.dy;

                              // Scale (pinch zoom)
                              _textScale =
                                  (_textScale * details.scale).clamp(0.5, 3.0);
                            });
                          },
                          child: Transform.scale(
                            scale: _textScale,
                            child: Opacity(
                              opacity: 0.8,
                              child: Text(
                                _addedText!,
                                style: const TextStyle(
                                  fontSize: 60,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    /// Movable image (on TOP of text)
                    if (_processedImage != null)
                      Positioned(
                        left: _imageX,
                        top: _imageY,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _imageX += details.delta.dx;
                              _imageY += details.delta.dy;
                            });
                          },
                          child: Image.memory(
                            _processedImage!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// ====== Controls (below editor) ======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Enter text here",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _pickAndRemoveBg,
                      child: const Text("Pick & Remove BG"),
                    ),
                    ElevatedButton(
                      onPressed: _addText,
                      child: const Text("Add Text"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
