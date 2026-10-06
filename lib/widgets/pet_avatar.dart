import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../models/pet_profile.dart';

/// Round initial badge for a pet. Colour is stable per pet type.
class PetAvatar extends StatelessWidget {
  final PetProfile? pet;
  final double size;

  const PetAvatar({super.key, required this.pet, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final isCatLike = pet?.type == 'Cat' || pet?.type == 'Rabbit';
    final bg = isCatLike ? const Color(0xFFEFE7FD) : AppColors.primaryLight;
    final fg = isCatLike ? const Color(0xFF6D35D8) : AppColors.primaryDark;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: pet == null
          ? Icon(Icons.pets_rounded, size: size * 0.5, color: fg)
          : Text(
              pet!.initial,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}
