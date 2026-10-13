import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:photo_shader/photo_shader.dart';

class ImageiOSCase extends StatefulWidget {
  const ImageiOSCase({super.key});

  @override
  State<ImageiOSCase> createState() => _ImageiOSCaseState();
}

class _ImageiOSCaseState extends State<ImageiOSCase> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load('assets/images/test_image_2.jpg');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iOS'),
      ),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (_image == null) {
            return Center(child: CircularProgressIndicator());
          }

          return ShaderBuilder(
            assetKey: ShaderPath.externalUsageShaderSimplePath,
            (context, shader, child) {
              return CustomPaint(
                painter: ImageShaderPainter(
                  shader: shader,
                  image: _image!,
                ),
                child: SizedBox(
                  width: _image!.width.toDouble(),
                  height: _image!.height.toDouble(),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class ImageShaderPainter extends CustomPainter {
  ImageShaderPainter({
    required this.shader,
    required this.image,
  });

  final ui.FragmentShader shader;
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    shader.setImageSampler(0, image);
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, 1.5);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
