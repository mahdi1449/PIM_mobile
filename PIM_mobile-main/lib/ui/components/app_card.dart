import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.icon,
    this.title,
    this.subtitle,
    this.onTap,
    this.padding,
    this.accentColor,
    this.trailing,
  }) : assert(
         child != null || (icon != null && title != null),
         'Provide either child or both icon and title.',
       );

  final Widget? child;
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Color? accentColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? scheme.primary;
    final dividerColor = Theme.of(context).dividerColor;
    final content =
        child ??
        _StandardCardContent(
          icon: icon!,
          title: title!,
          subtitle: subtitle,
          accentColor: accent,
          trailing: trailing,
        );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: isDark ? 18 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class _StandardCardContent extends StatelessWidget {
  const _StandardCardContent({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.42),
            ),
      ],
    );
  }
}
