import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/firestore/workout_log_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dark_mockup_palette.dart';
import '../../models/workout_log.dart';

double _totalVolume(WorkoutLog log) {
  return log.exercises.fold<double>(
    0,
    (sum, e) => sum + (e.actualSets ?? 0) * (e.actualReps ?? 0) * (e.actualWeight ?? 0),
  );
}

class SplitDayHistoryScreen extends StatelessWidget {
  const SplitDayHistoryScreen({
    super.key,
    required this.workoutLogRepo,
    required this.splitDayId,
    required this.splitDayLabel,
  });

  final WorkoutLogRepository workoutLogRepo;
  final String splitDayId;
  final String splitDayLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkMockupPalette.background,
      appBar: AppBar(
        backgroundColor: DarkMockupPalette.background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(splitDayLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: workoutLogRepo.watchCompletedLogsForSplitDay(splitDayId),
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <WorkoutLog>[];
          // Chart reads oldest → newest, left to right; `logs` itself stays
          // newest-first below since that's the more useful reading order
          // for the entry list.
          final oldestFirst = logs.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (oldestFirst.length >= 2) ...[
                const Text('Progression', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                  decoration: BoxDecoration(color: DarkMockupPalette.card, borderRadius: BorderRadius.circular(14)),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < oldestFirst.length; i++) FlSpot(i.toDouble(), _totalVolume(oldestFirst[i])),
                          ],
                          isCurved: true,
                          color: DarkMockupPalette.accent,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: DarkMockupPalette.accent.withValues(alpha: 0.12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              const Text('History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: AppSpacing.md),
              for (final log in logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    decoration: BoxDecoration(color: DarkMockupPalette.card, borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      key: Key('history_entry_${log.date}'),
                      title: Text(log.date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        log.exercises.map((e) => '${e.name}: ${e.actualWeight ?? "-"}kg x ${e.actualReps ?? "-"}').join(', '),
                        style: const TextStyle(color: DarkMockupPalette.mutedText),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
