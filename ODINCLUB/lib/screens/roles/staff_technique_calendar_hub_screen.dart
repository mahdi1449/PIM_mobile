import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../sports_performance/models/event.dart';
import '../../sports_performance/providers/events_provider.dart';
import '../../sports_performance/screens/create_event/create_event_screen.dart';
import '../../sports_performance/screens/event_detail/event_detail_screen.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueCalendarHubScreen extends ConsumerStatefulWidget {
  const StaffTechniqueCalendarHubScreen({super.key});

  @override
  ConsumerState<StaffTechniqueCalendarHubScreen> createState() =>
      _StaffTechniqueCalendarHubScreenState();
}

class _StaffTechniqueCalendarHubScreenState
    extends ConsumerState<StaffTechniqueCalendarHubScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider(null));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
        backgroundColor: StaffTechniqueHubTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvel evenement'),
      ),
      body: StaffTechniquePageBackground(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 96 + bottomInset),
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: StaffTechniqueEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Calendrier indisponible',
              subtitle: error.toString(),
            ),
          ),
          data: (events) {
            final todayEvents = _eventsForDay(_selectedDay, events);
            return ListView(
              children: [
                StaffTechniqueHeroCard(
                  eyebrow: 'Training Planner',
                  title: DateFormat('MMMM yyyy').format(_focusedDay),
                  subtitle:
                      'Lis rapidement la charge du jour, les matchs et les sessions a venir.',
                  icon: Icons.calendar_month_rounded,
                  trailing: StaffTechniqueStatusChip(
                    label: '${todayEvents.length} auj.',
                    color: StaffTechniqueHubTheme.secondary,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Evenements',
                        value: '${events.length}',
                        icon: Icons.event_available_rounded,
                        caption: 'sur la periode visible',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Selection',
                        value: DateFormat('dd MMM').format(_selectedDay),
                        icon: Icons.today_rounded,
                        accent: StaffTechniqueHubTheme.secondary,
                        caption: '${todayEvents.length} rendez-vous',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: StaffTechniqueHubTheme.cardDecoration(),
                  child: TableCalendar<Event>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2032, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => _eventsForDay(day, events),
                    headerVisible: false,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onPageChanged: (focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: const BoxDecoration(
                        color: StaffTechniqueHubTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: StaffTechniqueHubTheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: StaffTechniqueHubTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                StaffTechniqueSectionTitle(
                  title:
                      'Planning du ${DateFormat('dd MMMM').format(_selectedDay)}',
                ),
                const SizedBox(height: 12),
                if (todayEvents.isEmpty)
                  const StaffTechniqueEmptyState(
                    icon: Icons.event_note_rounded,
                    title: 'Aucun suivi ce jour-la',
                    subtitle:
                        'Ajoute une seance ou un match pour remplir cette plage.',
                  )
                else
                  ...todayEvents.map(_buildEventCard),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Event> _eventsForDay(DateTime day, List<Event> allEvents) {
    return allEvents.where((event) => isSameDay(event.date, day)).toList();
  }

  Widget _buildEventCard(Event event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: event.title,
        subtitle:
            '${DateFormat('HH:mm').format(event.date)}  •  ${event.location}  •  ${event.typeLabel}',
        icon: _eventIcon(event.type),
        trailing: StaffTechniqueStatusChip(
          label: event.statusLabel,
          color: _statusColor(event.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
      ),
    );
  }

  IconData _eventIcon(EventType type) {
    switch (type) {
      case EventType.testSession:
        return Icons.fitness_center_rounded;
      case EventType.match:
        return Icons.sports_soccer_rounded;
      case EventType.evaluation:
        return Icons.assessment_rounded;
      case EventType.detection:
        return Icons.person_search_rounded;
      case EventType.medical:
        return Icons.medical_services_outlined;
      case EventType.recovery:
        return Icons.self_improvement_rounded;
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
