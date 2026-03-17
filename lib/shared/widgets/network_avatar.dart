import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({
    super.key,
    required this.imageUrl,
    this.size = 56,
    this.borderColor,
    this.borderWidth = 2,
    this.overlayIcon,
    this.shape = BoxShape.circle,
  });

  final String imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final IconData? overlayIcon;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final avatar = CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _fallbackAvatar(context),
      placeholder: (_, __) => _fallbackAvatar(context),
    );

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: shape,
            border: Border.all(
                color: borderColor ?? Colors.white, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(child: avatar),
        ),
        if (overlayIcon != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: size * 0.18,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(overlayIcon, size: size * 0.18, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _fallbackAvatar(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
        ),
        child: Icon(Icons.storefront_rounded,
            color: Theme.of(context).colorScheme.primary),
      );
}
