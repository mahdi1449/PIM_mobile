import 'package:flutter/material.dart';

import '../../utils/role_mapper.dart';

class StaffTechniqueHubTheme {
  StaffTechniqueHubTheme._();

  static const Color background = Color(0xFFF7FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF1F5F7);
  static const Color surfaceMuted = Color(0xFFE4ECEF);
  static const Color primary = Color(0xFF00677E);
  static const Color primaryStrong = Color(0xFF005263);
  static const Color primarySoft = Color(0xFFB6ECFF);
  static const Color secondary = Color(0xFF0F8EAA);
  static const Color textPrimary = Color(0xFF182024);
  static const Color textSecondary = Color(0xFF617177);
  static const Color border = Color(0xFFD8E2E6);
  static const Color success = Color(0xFF169B62);
  static const Color warning = Color(0xFFFF9F43);
  static const Color danger = Color(0xFFE05263);

  static bool isEnabledForRole(String? role) {
    if (role == null) {
      return false;
    }
    return RoleMapper.normalize(role) == RoleMapper.staffTechnique;
  }

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FBFC), Color(0xFFF1F5F7)],
  );

  static List<BoxShadow> get softShadow => const [
    BoxShadow(color: Color(0x14003D49), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static BoxDecoration glassDecoration({Color? color}) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: 0.84),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border),
      boxShadow: softShadow,
    );
  }

  static BoxDecoration cardDecoration({
    Color color = surface,
    Color borderColor = border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: softShadow,
    );
  }
}

class StaffTechniquePageBackground extends StatelessWidget {
  const StaffTechniquePageBackground({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: StaffTechniqueHubTheme.pageGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -30,
            child: _GlowOrb(
              size: 240,
              color: StaffTechniqueHubTheme.primarySoft.withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            top: 90,
            left: -80,
            child: _GlowOrb(
              size: 200,
              color: StaffTechniqueHubTheme.secondary.withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffTechniqueHeroCard extends StatelessWidget {
  const StaffTechniqueHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StaffTechniqueHubTheme.primary,
            StaffTechniqueHubTheme.secondary,
          ],
        ),
        boxShadow: StaffTechniqueHubTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing ??
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
        ],
      ),
    );
  }
}

class StaffTechniqueMetricCard extends StatelessWidget {
  const StaffTechniqueMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = StaffTechniqueHubTheme.primary,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: StaffTechniqueHubTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: StaffTechniqueHubTheme.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: StaffTechniqueHubTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StaffTechniqueHubTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StaffTechniqueSectionTitle extends StatelessWidget {
  const StaffTechniqueSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: StaffTechniqueHubTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: StaffTechniqueHubTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class StaffTechniqueSearchField extends StatelessWidget {
  const StaffTechniqueSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StaffTechniqueHubTheme.glassDecoration(
        color: StaffTechniqueHubTheme.surface,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(
            Icons.manage_search_rounded,
            color: StaffTechniqueHubTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class StaffTechniqueActionCard extends StatelessWidget {
  const StaffTechniqueActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: StaffTechniqueHubTheme.cardDecoration(),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: StaffTechniqueHubTheme.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: StaffTechniqueHubTheme.primaryStrong),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: StaffTechniqueHubTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StaffTechniqueHubTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: StaffTechniqueHubTheme.primary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffTechniqueStatusChip extends StatelessWidget {
  const StaffTechniqueStatusChip({
    super.key,
    required this.label,
    this.color = StaffTechniqueHubTheme.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class StaffTechniqueEmptyState extends StatelessWidget {
  const StaffTechniqueEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: StaffTechniqueHubTheme.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: StaffTechniqueHubTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: StaffTechniqueHubTheme.primaryStrong,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: StaffTechniqueHubTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: StaffTechniqueHubTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
