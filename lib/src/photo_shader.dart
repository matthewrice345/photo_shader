import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:photo_shader/src/constants/shader_path.dart';
import 'package:photo_shader/src/photo_painter.dart';
import 'package:photo_shader/src/models/photo_style.dart';

typedef FragmentPath = String;

class PhotoShader extends StatefulWidget {
  const PhotoShader({
    super.key,
    required this.style,
    required this.imageProvider,
    required this.image,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.fit = BoxFit.contain,
    this.onImageRendered,
  }) : assert(imageProvider != null || image != null, 'Either imageProvider or image must be provided');

  const PhotoShader.provider({
    super.key,
    required this.style,
    required ImageProvider this.imageProvider,
    Duration? fadeDuration,
    this.fit = BoxFit.contain,
    this.onImageRendered,
  }) : image = null, fadeDuration = fadeDuration ?? const Duration(milliseconds: 500);

  const PhotoShader.image({
    super.key,
    required this.style,
    required ui.Image this.image,
    Duration? fadeDuration,
    this.fit = BoxFit.contain,
    this.onImageRendered,
  }) : imageProvider = null, fadeDuration = fadeDuration ?? const Duration(milliseconds: 500);

  final PhotoStyle style;
  final ImageProvider? imageProvider;
  final ui.Image? image;
  final Duration fadeDuration;
  final BoxFit fit;
  final VoidCallback? onImageRendered;

  @override
  State<PhotoShader> createState() => _PhotoShaderState();
}

class _PhotoShaderState extends State<PhotoShader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Completer<ui.Image> _imageCompleter;
  ui.Image? _image;
  bool _canAnimate = true;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    _imageCompleter = Completer<ui.Image>();

    _controller = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (_image == null) {
      _loadImage();
    } else {
      _imageCompleter.complete(_image);
      _fadeInImage();
    }
  }

  @override
  void didUpdateWidget(covariant PhotoShader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != null && widget.imageProvider != oldWidget.imageProvider) {
      // rebuild the image
      _canAnimate = true;
      _loadImage();
    }
  }

  void _loadImage() {
    if (_imageCompleter.isCompleted) {
      _imageCompleter = Completer<ui.Image>();
    }
    final oldStream = _imageStream;
    final oldListener = _imageStreamListener;
    if (oldStream != null && oldListener != null) {
      oldStream.removeListener(oldListener);
    }
    _imageStream = widget.imageProvider!.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener((ImageInfo info, bool _) {
      if (!mounted) {
        return;
      }
      if (!_imageCompleter.isCompleted) {
        _imageCompleter.complete(info.image);
      }
      if (_image == null) {
        _image = info.image;
        _fadeInImage();
      } else {
        _image = info.image;
        _fadeInImage();
      }
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _fadeInImage() {
    // only go forward if we are not already there.
    if(_canAnimate) {
      _canAnimate = false;
      _controller.forward();
      widget.onImageRendered?.call();
    }
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return FadeTransition(
        opacity: _curvedAnimation,
        child: _PhotoShaderBuilder(
          image: _image!,
          style: widget.style,
          fit: widget.fit,
        ),
      );
    }

    return FutureBuilder<ui.Image>(
      future: _imageCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FadeTransition(
            opacity: _curvedAnimation,
            child: _PhotoShaderBuilder(
              image: snapshot.data!,
              style: widget.style,
              fit: widget.fit,
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}

class _PhotoShaderBuilder extends StatelessWidget {
  const _PhotoShaderBuilder({required this.image, required this.style, required this.fit});

  final ui.Image image;
  final PhotoStyle style;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // An unedited photo needs no fragment shader. Keep the normal image path
    // available for fast compositing while dragging and zooming in the editor.
    if (style == PhotoStyle.noEffects()) {
      return SizedBox.expand(
        child: RawImage(image: image, fit: fit, filterQuality: FilterQuality.medium),
      );
    }
    return ShaderBuilder(
      assetKey: ShaderPath.externalUsageShaderPath,
      (context, shader, _) => _FilteredPhoto(shader: shader, image: image, style: style, fit: fit),
    );
  }
}

/// Applies the photo shader once at the bitmap's own resolution and displays the
/// result as a regular image.
///
/// Sampling the full-size bitmap directly in the fragment shader takes a single
/// texel per screen pixel with no mipmaps, so a large photo shown small looks
/// grainy/aliased until the user zooms in. Baking the effect into an image and
/// drawing it with [RawImage] lets the engine filter (mipmap) the downscale.
class _FilteredPhoto extends StatefulWidget {
  const _FilteredPhoto({required this.shader, required this.image, required this.style, required this.fit});

  final ui.FragmentShader shader;
  final ui.Image image;
  final PhotoStyle style;
  final BoxFit fit;

  @override
  State<_FilteredPhoto> createState() => _FilteredPhotoState();
}

class _FilteredPhotoState extends State<_FilteredPhoto> {
  /// Keeps the offscreen texture bounded for unusually large source bitmaps.
  static const _maxBakeEdge = 4096;

  ui.Image? _baked;

  @override
  void initState() {
    super.initState();
    _bake();
  }

  @override
  void didUpdateWidget(covariant _FilteredPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image || oldWidget.style != widget.style || oldWidget.shader != widget.shader) {
      _bake();
    }
  }

  void _bake() {
    final image = widget.image;
    final longest = image.width > image.height ? image.width : image.height;
    final scale = longest > _maxBakeEdge ? _maxBakeEdge / longest : 1.0;
    final width = (image.width * scale).round().clamp(1, _maxBakeEdge);
    final height = (image.height * scale).round().clamp(1, _maxBakeEdge);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    PhotoPainter(
      shader: widget.shader,
      image: image,
      style: widget.style,
      fit: BoxFit.fill,
    ).paint(canvas, Size(width.toDouble(), height.toDouble()));
    final picture = recorder.endRecording();
    final baked = picture.toImageSync(width, height);
    picture.dispose();

    _baked?.dispose();
    _baked = baked;
  }

  @override
  void dispose() {
    _baked?.dispose();
    _baked = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: RawImage(image: _baked, fit: widget.fit, filterQuality: FilterQuality.medium),
    );
  }
}
