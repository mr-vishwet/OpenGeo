import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_theme.dart';

/// The OpenGeo globe mark: a blue gradient disc with a white globe icon.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryPressed],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x331A73E8), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Icon(Icons.public, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Rounded icon badge used as the leading element of list rows.
class ModeBadge extends StatelessWidget {
  const ModeBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(R.input),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Star plus "4.6 (2.1k)". Sample data only — [Place.rating] is null for
/// records that came from the API, and this widget renders nothing then.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.place, this.fontSize = 13});

  final Place place;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final label = place.ratingLabel;
    if (label == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 4, color: AppColors.star),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Rounded square stand-in for a place photo: the category icon on a tinted
/// background. No stock photography is invented for real places.
class CategoryArt extends StatelessWidget {
  const CategoryArt({
    super.key,
    required this.place,
    this.size = 64,
    this.radius = R.input,
  });

  final Place place;
  final double size;
  final double radius;

  static IconData iconFor(String category) => switch (category) {
        'park' => Icons.park,
        'cafe' => Icons.local_cafe,
        'historic' => Icons.account_balance,
        'mall' => Icons.storefront,
        _ => Icons.place,
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark ? AppColors.darkSurfaceSunken : AppColors.surfaceAlt;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark ? AppColors.darkOutline : AppColors.outline,
        ),
      ),
      child: Icon(
        iconFor(place.category),
        size: size * 0.42,
        color: dark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }
}

/// Section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(S.lg, S.lg, S.lg, S.sm),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Pill-shaped selectable chip (filter row).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular floating map control.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.dark = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkSurfaceAlt : AppColors.surface;
    final fg = dark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: const Color(0x33000000),
      child: IconButton(
        icon: Icon(icon, size: 20, color: fg),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Small status chip with a coloured dot.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurfaceAlt : AppColors.surface,
        borderRadius: BorderRadius.circular(R.pill),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: color)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A one-line secondary text row (icon + label), used on detail screens.
class MetaRow extends StatelessWidget {
  const MetaRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: S.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
