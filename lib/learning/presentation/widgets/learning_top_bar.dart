import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';

class LearningTopBar extends StatelessWidget implements PreferredSizeWidget {
  const LearningTopBar({
    super.key,
    this.title = 'ODIN',
    this.showBack = true,
    this.onNotifications,
    this.avatarLetter,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onNotifications;
  final String? avatarLetter;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: LearningColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: showBack && canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: LearningColors.text,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: LearningColors.text,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          color: LearningColors.text,
          onPressed: onNotifications ?? () {},
          tooltip: 'Notifications',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: LearningColors.lime.withValues(alpha: 0.18),
            child: Text(
              (avatarLetter?.isNotEmpty == true ? avatarLetter! : 'O')
                  .substring(0, 1)
                  .toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: LearningColors.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
