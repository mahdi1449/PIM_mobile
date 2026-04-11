import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../sports_performance/models/event.dart';
import '../../sports_performance/providers/events_provider.dart';
import '../../sports_performance/screens/reports/event_report_screen.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueReportsHubScreen extends ConsumerStatefulWidget {
  const StaffTechniqueReportsHubScreen({super.key});

  @override
  ConsumerState<StaffTechniqueReportsHubScreen> createState() =>
      _StaffTechniqueReportsHubScreenState();
}

class _StaffTechniqueReportsHubScreenState
    extends ConsumerState<StaffTechniqueReportsHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(eventsProvider(null));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: StaffTechniqueEmptyState(
            icon: Icons.description_outlined,
            title: 'Rapports indisponibles',
            subtitle: error.toString(),
          ),
        ),
        data: (events) {
          final filtered = events.where((event) {
            final haystack =
                '${event.title} ${event.typeLabel} ${event.statusLabel}'
                    .toLowerCase();
            return haystack.contains(_query.toLowerCase());
          }).toList()..sort((a, b) => b.date.compareTo(a.date));
          final completedCount = filtered
              .where((event) => event.status == EventStatus.completed)
              .length;

          return ListView(
            children: [
              StaffTechniqueHeroCard(
                eyebrow: 'Performance Reports',
                title: 'Scouting interne & suivi terrain',
                subtitle:
                    'Retrouve les derniers comptes-rendus, filtre vite et ouvre les analyses detaillees.',
                icon: Icons.analytics_outlined,
                trailing: StaffTechniqueStatusChip(
                  label: '$completedCount completes',
                  color: StaffTechniqueHubTheme.success,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: StaffTechniqueMetricCard(
                      label: 'Rapports',
                      value: '${filtered.length}',
                      icon: Icons.library_books_rounded,
                      caption: 'liste filtree',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StaffTechniqueMetricCard(
                      label: 'Brouillons',
                      value:
                          '${filtered.where((event) => event.status == EventStatus.draft).length}',
                      icon: Icons.edit_note_rounded,
                      accent: StaffTechniqueHubTheme.warning,
                      caption: 'a finaliser',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              StaffTechniqueSearchField(
                controller: _searchController,
                hintText: 'Chercher un suivi par titre, type ou statut...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 22),
              const StaffTechniqueSectionTitle(
                title: 'Recent Scouting Reports',
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const StaffTechniqueEmptyState(
                  icon: Icons.insert_chart_outlined,
                  title: 'Aucun rapport disponible',
                  subtitle:
                      'Les comptes-rendus apparaitront ici une fois crees.',
                )
              else
                ...filtered.map(_buildReportCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Event event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: event.title,
        subtitle:
            '${DateFormat('dd MMM yyyy • HH:mm').format(event.date)}  •  ${event.typeLabel}',
        icon: _typeIcon(event.type),
        trailing: StaffTechniqueStatusChip(
          label: event.statusLabel,
          color: _statusColor(event.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventReportScreen(eventId: event.id),
            ),
          );
        },
      ),
    );
  }

  IconData _typeIcon(EventType type) {
    switch (type) {
      case EventType.testSession:
        return Icons.timer_outlined;
      case EventType.match:
        return Icons.sports_soccer_rounded;
      case EventType.evaluation:
        return Icons.assignment_outlined;
      case EventType.detection:
        return Icons.person_search_outlined;
      case EventType.medical:
        return Icons.medical_services_outlined;
      case EventType.recovery:
        return Icons.self_improvement_outlined;
      case EventType.aiAnalysis:
        return Icons.psychology_outlined;
    }
  }

  Color _statusColor(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return StaffTechniqueHubTheme.textSecondary;
      case EventStatus.inProgress:
        return StaffTechniqueHubTheme.warning;
      case EventStatus.completed:
        return StaffTechniqueHubTheme.success;
    }
  }
}
