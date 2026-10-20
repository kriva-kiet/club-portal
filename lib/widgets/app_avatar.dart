import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A universal, fail-safe Avatar widget that reliably renders:
/// 1. Data URLs (`data:image/...;base64,...`)
/// 2. Raw Base64 strings
/// 3. Network URLs (`http://`, `https://`)
/// 4. Fallback name initials with glowing gradient when image is absent or fails to load.
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final double? borderWidth;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.photoUrl,
    this.name = '',
    this.radius = 20,
    this.borderWidth,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final bWidth = borderWidth ?? 0;
    final bColor = borderColor ?? Colors.transparent;

    Widget content = _buildImageContent(context);

    if (bWidth > 0) {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: bColor, width: bWidth),
        ),
        child: ClipOval(child: content),
      );
    } else {
      content = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildImageContent(BuildContext context) {
    final rawUrl = (photoUrl ?? '').trim();

    if (rawUrl.isEmpty) {
      return _buildFallback();
    }

    // 1. Check for Data URI or Base64 string
    if (rawUrl.startsWith('data:image')) {
      try {
        final commaIndex = rawUrl.indexOf(',');
        final base64Data = commaIndex != -1 ? rawUrl.substring(commaIndex + 1) : rawUrl;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (e) {
        return _buildFallback();
      }
    }

    // 2. Check for pure Base64 (long string without http/https)
    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://') && rawUrl.length > 100) {
      try {
        final bytes = base64Decode(rawUrl);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (e) {
        return _buildFallback();
      }
    }

    // 3. HTTP / HTTPS URL
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return Image.network(
        rawUrl,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surface,
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          );
        },
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final trimmedName = name.trim();
    String initials = '';
    if (trimmedName.isNotEmpty) {
      final parts = trimmedName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              )
            : Icon(
                Icons.person,
                size: radius * 1.1,
                color: Colors.white70,
              ),
      ),
    );
  }
}

/// Helper function to create ImageProvider safely for CircleAvatar or DecorationImage
ImageProvider? getSafeAvatarProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final rawUrl = photoUrl.trim();

  if (rawUrl.startsWith('data:image')) {
    try {
      final commaIndex = rawUrl.indexOf(',');
      final base64Data = commaIndex != -1 ? rawUrl.substring(commaIndex + 1) : rawUrl;
      final Uint8List bytes = base64Decode(base64Data);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://') && rawUrl.length > 100) {
    try {
      final Uint8List bytes = base64Decode(rawUrl);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return NetworkImage(rawUrl);
  }

  return null;
}
