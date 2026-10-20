import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final int maxBytes;

  const ImageCropDialog({
    super.key,
    required this.imageBytes,
    this.maxBytes = 700 * 1024, // 700 KB max
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isProcessing = false;

  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _cropAndSave() async {
    if (_decodedImage == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final matrix = _transformationController.value;
      const viewportSize = 260.0;
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

      // The base image is fit inside 260x260
      final double baseScale;
      final double baseOffsetX;
      final double baseOffsetY;

      if (imgW > imgH) {
        baseScale = viewportSize / imgH;
        baseOffsetX = (viewportSize - imgW * baseScale) / 2;
        baseOffsetY = 0;
      } else {
        baseScale = viewportSize / imgW;
        baseOffsetX = 0;
        baseOffsetY = (viewportSize - imgH * baseScale) / 2;
      }

      // Inverted matrix to find source rect in image coordinates
      final inv = Matrix4.inverted(matrix);
      // Corners of the viewport (0,0) to (viewportSize, viewportSize)
      final topLeft = MatrixUtils.transformPoint(inv, const Offset(0, 0));
      final bottomRight = MatrixUtils.transformPoint(inv, const Offset(viewportSize, viewportSize));

      // Map from layout space to original image space
      final srcLeft = ((topLeft.dx - baseOffsetX) / baseScale).clamp(0.0, imgW);
      final srcTop = ((topLeft.dy - baseOffsetY) / baseScale).clamp(0.0, imgH);
      final srcRight = ((bottomRight.dx - baseOffsetX) / baseScale).clamp(0.0, imgW);
      final srcBottom = ((bottomRight.dy - baseOffsetY) / baseScale).clamp(0.0, imgH);

      final cropSide = (srcRight - srcLeft).clamp(1.0, imgW);
      final srcRect = Rect.fromLTWH(srcLeft, srcTop, cropSide, cropSide);

      // We render to an output size (512x512) to keep crisp resolution while staying comfortably under 700KB
      const targetResolution = 512;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;

      final dstRect = Rect.fromLTWH(0, 0, targetResolution.toDouble(), targetResolution.toDouble());
      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, paint);

      final picture = recorder.endRecording();
      final croppedImg = await picture.toImage(targetResolution, targetResolution);

      final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not encode image');

      var outputBytes = byteData.buffer.asUint8List();

      // If output is > maxBytes (700KB), downscale to guarantee limit
      if (outputBytes.lengthInBytes > widget.maxBytes) {
        const smallerRes = 360;
        final rec2 = ui.PictureRecorder();
        final can2 = Canvas(rec2);
        can2.drawImageRect(
          _decodedImage!,
          srcRect,
          Rect.fromLTWH(0, 0, smallerRes.toDouble(), smallerRes.toDouble()),
          paint,
        );
        final pic2 = rec2.endRecording();
        final cropped2 = await pic2.toImage(smallerRes, smallerRes);
        final bd2 = await cropped2.toByteData(format: ui.ImageByteFormat.png);
        if (bd2 != null) {
          outputBytes = bd2.buffer.asUint8List();
        }
      }

      if (mounted) {
        Navigator.of(context).pop(outputBytes);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cropBoxSize = 260.0;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.crop_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Crop Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Drag, pinch to zoom, or pan to position your profile avatar inside the circle.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Cropping Area
            Center(
              child: Container(
                width: cropBoxSize,
                height: cropBoxSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            boundaryMargin: const EdgeInsets.all(160),
                            child: SizedBox(
                              width: cropBoxSize,
                              height: cropBoxSize,
                              child: Center(
                                child: RawImage(
                                  image: _decodedImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Circle overlay mask with grid & border
                          IgnorePointer(
                            child: CustomPaint(
                              size: const Size(cropBoxSize, cropBoxSize),
                              painter: _CircularCropOverlayPainter(
                                primaryColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Optimized size: max 700 KB (Circular / Square)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isProcessing) ? null : _cropAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Crop & Apply',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularCropOverlayPainter extends CustomPainter {
  final Color primaryColor;

  _CircularCropOverlayPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Dim background outside the circle
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final overlayPath = Path.combine(PathOperation.difference, bgPath, circlePath);
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, dimPaint);

    // Subtle grid lines inside crop circle
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final oneThird = radius * 2 / 3;
    final topX = center.dx - radius;
    final topY = center.dy - radius;

    canvas.save();
    canvas.clipPath(circlePath);
    // Vertical grid lines
    canvas.drawLine(
      Offset(topX + oneThird, topY),
      Offset(topX + oneThird, topY + radius * 2),
      gridPaint,
    );
    canvas.drawLine(
      Offset(topX + oneThird * 2, topY),
      Offset(topX + oneThird * 2, topY + radius * 2),
      gridPaint,
    );
    // Horizontal grid lines
    canvas.drawLine(
      Offset(topX, topY + oneThird),
      Offset(topX + radius * 2, topY + oneThird),
      gridPaint,
    );
    canvas.drawLine(
      Offset(topX, topY + oneThird * 2),
      Offset(topX + radius * 2, topY + oneThird * 2),
      gridPaint,
    );
    canvas.restore();

    // Circle Outline Glow/Border
    final borderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularCropOverlayPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor;
  }
}
