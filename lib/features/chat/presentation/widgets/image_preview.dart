/// Full-screen image preview with pinch-to-zoom and swipe-to-dismiss.
///
/// Used when tapping images in message bubbles or file attachments.
/// Supports hero animation transitions and gesture-based dismissal.
library;


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Opens a full-screen image preview overlay.
///
/// Supports both network URLs and local bytes. Uses [Hero] animation
/// when a [heroTag] is provided.
void showImagePreview(
  BuildContext context, {
  String? imageUrl,
  Uint8List? imageBytes,
  String? heroTag,
  String? title,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      transitionDuration: SanbaoAnimations.durationNormal,
      reverseTransitionDuration: SanbaoAnimations.durationFast,
      pageBuilder: (context, animation, secondaryAnimation) =>
          _ImagePreviewOverlay(
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        heroTag: heroTag,
        title: title,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: SanbaoAnimations.smoothCurve,
          ),
          child: child,
        ),
    ),
  );
}

class _ImagePreviewOverlay extends StatefulWidget {
  const _ImagePreviewOverlay({
    this.imageUrl,
    this.imageBytes,
    this.heroTag,
    this.title,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? heroTag;
  final String? title;

  @override
  State<_ImagePreviewOverlay> createState() => _ImagePreviewOverlayState();
}

class _ImagePreviewOverlayState extends State<_ImagePreviewOverlay>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  late final AnimationController _dismissController;

  double _dragOffset = 0;
  double _dragOpacity = 1.0;
  bool _isDragging = false;

  static const double _dismissThreshold = 120;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );

    // Hide status bar for immersive viewing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _dismissController.dispose();
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    // Only allow drag-to-dismiss when not zoomed in
    if (_isZoomedIn) return;
    setState(() => _isDragging = true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta.dy;
      _dragOpacity = (1.0 - (_dragOffset.abs() / 400)).clamp(0.3, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    if (_dragOffset.abs() > _dismissThreshold ||
        details.velocity.pixelsPerSecond.dy.abs() > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _dragOpacity = 1.0;
        _isDragging = false;
      });
    }
  }

  bool get _isZoomedIn {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    return scale > 1.05;
  }

  void _onDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final Matrix4 newMatrix;

    if (currentScale > 1.5) {
      // Zoom out to fit
      newMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x
      // ignore: deprecated_member_use
      newMatrix = Matrix4.identity()..scale(2.5, 2.5);
    }

    _transformationController.value = newMatrix;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background tap to close
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: AnimatedOpacity(
                duration: SanbaoAnimations.durationFast,
                opacity: _dragOpacity,
                child: Container(color: Colors.black87),
              ),
            ),

            // Image
            AnimatedOpacity(
              duration: const Duration(milliseconds: 50),
              opacity: _dragOpacity,
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Center(
                  child: GestureDetector(
                    onDoubleTap: _onDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      clipBehavior: Clip.none,
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
            ),

            // Top bar with close button and title
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: SanbaoAnimations.durationFast,
                opacity: _isDragging ? 0.0 : 1.0,
                child: _buildTopBar(context),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildImage() {
    Widget imageWidget;

    if (widget.imageBytes != null) {
      imageWidget = Image.memory(
        widget.imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (widget.imageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: SanbaoColors.accent,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      );
    } else {
      imageWidget = _buildErrorPlaceholder();
    }

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildErrorPlaceholder() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_rounded,
          size: 48,
          color: SanbaoColors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Не удалось загрузить изображение',
          style: TextStyle(
            color: SanbaoColors.textMuted.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );

  Widget _buildTopBar(BuildContext context) => Container(
      padding: EdgeInsets.only(
        top: context.topPadding + 8,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),

          // Title
          if (widget.title != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
}
