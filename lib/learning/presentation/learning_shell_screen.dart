import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../theme/learning_colors.dart';
import 'screens/learning_courses_screen.dart';
import 'screens/learning_dashboard_screen.dart';
import 'screens/learning_profile_screen.dart';
import 'widgets/learning_top_bar.dart';

class LearningShellScreen extends StatefulWidget {
  const LearningShellScreen({super.key, required this.session});

  final SessionModel session;

  @override
  State<LearningShellScreen> createState() => _LearningShellScreenState();
}

class _LearningShellScreenState extends State<LearningShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerId = widget.session.userId;

    final learningTheme = theme.copyWith(
      scaffoldBackgroundColor: LearningColors.surface,
      colorScheme: theme.colorScheme.copyWith(
        primary: LearningColors.lime,
        secondary: LearningColors.limeDark,
        surface: LearningColors.card,
      ),
    );

    final pages = [
      LearningDashboardScreen(session: widget.session, playerId: playerId),
      LearningCoursesScreen(session: widget.session, playerId: playerId),
      LearningProfileScreen(session: widget.session, playerId: playerId),
    ];

    return Theme(
      data: learningTheme,
      child: Scaffold(
        appBar: LearningTopBar(
          title: 'ODIN',
          showBack: false,
          avatarLetter: (widget.session.firstName?.isNotEmpty == true
              ? widget.session.firstName![0]
              : (widget.session.email.isNotEmpty
                    ? widget.session.email[0]
                    : 'O')),
        ),
        body: pages[_index],
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: LearningColors.card,
              border: Border(top: BorderSide(color: LearningColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
                _navItem(1, Icons.school_outlined, 'Courses'),
                _navItem(2, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _index == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _index = index),
      child: SizedBox(
        width: 106,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? LearningColors.limeDark
                  : LearningColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? LearningColors.limeDark
                    : LearningColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
