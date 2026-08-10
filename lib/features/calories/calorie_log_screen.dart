import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/app_user.dart';
import '../../models/food_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _mealLabels = {
  MealType.breakfast: 'Breakfast',
  MealType.lunch: 'Lunch',
  MealType.dinner: 'Dinner',
  MealType.snacks: 'Snacks',
};

class CalorieLogScreen extends StatefulWidget {
  CalorieLogScreen({
    super.key,
    required this.foodLogRepo,
    required this.userRepo,
    DateTime? initialDate,
  }) : initialDate = initialDate ?? DateTime.now().toUtc();

  final FoodLogRepository foodLogRepo;
  final UserRepository userRepo;
  final DateTime initialDate;

  @override
  State<CalorieLogScreen> createState() => _CalorieLogScreenState();
}

class _CalorieLogScreenState extends State<CalorieLogScreen> {
  late DateTime _date = widget.initialDate;

  void _shiftDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(_date);
    return Scaffold(
      appBar: AppBar(
        title: Text(dateKey),
        // Both day-navigation controls live in `actions` (not `leading`) so
        // `leading` is left free for GoRouter/Navigator's default back
        // button — this screen is pushed from Home via context.push.
        actions: [
          IconButton(
            key: const Key('calorie_log_prev_day'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shiftDay(-1),
          ),
          IconButton(
            key: const Key('calorie_log_next_day'),
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shiftDay(1),
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, userSnapshot) {
          final calorieGoal = userSnapshot.data?.calorieGoal;
          return StreamBuilder<FoodLog>(
            stream: widget.foodLogRepo.watchForDate(dateKey),
            builder: (context, logSnapshot) {
              final log = logSnapshot.data ?? FoodLog.empty(dateKey);

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (calorieGoal == null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: ${log.totalCalories.round()} kcal'),
                        TextButton(
                          key: const Key('calorie_log_set_goal_button'),
                          onPressed: () => context.push('/profile/calorie-goal'),
                          child: const Text('Set your goal'),
                        ),
                      ],
                    )
                  else
                    Text('${log.totalCalories.round()} / $calorieGoal kcal',
                        style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  for (final mealType in MealType.values) ...[
                    Row(
                      children: [
                        Text(_mealLabels[mealType]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${log.meals[mealType]!.fold<double>(0, (sum, e) => sum + e.calories).round()} kcal'),
                        IconButton(
                          key: Key('add_food_${mealType.value}'),
                          icon: const Icon(Icons.add),
                          onPressed: () => context.push('/calories/$dateKey/add/${mealType.value}'),
                        ),
                      ],
                    ),
                    for (final entry in log.meals[mealType]!)
                      ListTile(
                        key: Key('food_entry_${mealType.value}_${entry.name}'),
                        title: Text(entry.name),
                        subtitle: Text('${entry.calories.round()} kcal'),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
