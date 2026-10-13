import 'package:flutter/material.dart';
import 'package:photo_shader/photo_shader.dart';

class ImageCase extends StatefulWidget {
  const ImageCase({super.key});

  @override
  State<ImageCase> createState() => _ImageCaseState();
}

class _ImageCaseState extends State<ImageCase> {

  PhotoStyle imageStyle = PhotoStyle.noEffects();

  AssetImage image = AssetImage('assets/images/test_image.jpg');

  void setHue(double value) {
    setState(() {
      imageStyle = imageStyle.copyWith(hue: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Case'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: PhotoShader.provider(
                  style: imageStyle,
                  imageProvider: image,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: () {
                    if(imageStyle.hue == 1) {
                      setHue(0.5);
                    } else {
                      setHue(1);
                    }
                  }, child: Text('Rebuild Shader (hue)')),
                  ElevatedButton(onPressed: () {
                    if(image.assetName == 'assets/images/test_image.jpg') {
                      setState(() {
                        image = AssetImage('assets/images/test_image_2.jpg');
                      });
                    } else {
                      setState(() {
                        image = AssetImage('assets/images/test_image.jpg');
                      });
                    }
                  }, child: Text('Change Image')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
