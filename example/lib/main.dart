import 'package:flutter/material.dart';
import 'package:photo_shader_example/use_cases/image_case.dart';
import 'package:photo_shader_example/use_cases/pixelation_case.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.all(24),
            color: Colors.grey.shade100,
            child: ShaderPickerPage(),
          ),
        ),
      ),
    );
  }
}

class ShaderPickerPage extends StatelessWidget {
  const ShaderPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 16,
      spacing: 16,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ImageiOSCase()));
          },
          child: Container(
            color: Colors.grey.shade300,
            height: 100, width: 100,
            alignment: Alignment.center,
            child: Text('iOS'),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ImageCase()));
          },
          child: Container(
            color: Colors.grey.shade300,
            height: 100, width: 100,
            alignment: Alignment.center,
            child: Text('Image'),
          ),
        ),
      ],
    );
  }
}



