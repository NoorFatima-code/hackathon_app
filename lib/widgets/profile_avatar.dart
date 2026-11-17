import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoData,
    this.radius = 36,
  });

  final String name;
  final String? photoData;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoData != null && photoData!.isNotEmpty;
    final displayName = name.trim();
    return Semantics(
      image: true,
      label: 'Profile photo for $displayName',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        foregroundColor: AppColors.primary,
        backgroundImage: hasPhoto
            ? MemoryImage(base64Decode(photoData!))
            : null,
        child: hasPhoto
            ? null
            : displayName.isEmpty
            ? Icon(Icons.person_outline, size: radius)
            : Text(
                displayName[0].toUpperCase(),
                style: TextStyle(
                  fontSize: radius * 0.85,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
