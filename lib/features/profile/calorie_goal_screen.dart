import 'package:flutter/material.dart';
import '../../core/firestore/user_repository.dart';
import '../../core/nutrition/tdee_calculator.dart';
import '../../models/app_user.dart';
import '../../models/tdee_profile.dart';

class CalorieGoalScreen extends StatefulWidget {
  const CalorieGoalScreen({super.key, required this.userRepo});

  final UserRepository userRepo;

  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  CalorieGoalDirection _goal = CalorieGoalDirection.maintain;
  bool _seeded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _seedFrom(TdeeProfile profile) {
    _weightController.text = profile.weightKg.toString();
    _heightController.text = profile.heightCm.toString();
    _ageController.text = profile.age.toString();
    _sex = profile.sex;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    if (weight == null || height == null || age == null) return;

    final profile = TdeeProfile(
      weightKg: weight,
      heightCm: height,
      age: age,
      sex: _sex,
      activityLevel: _activityLevel,
      goal: _goal,
    );
    final result = calculateTdeeGoal(profile);
    await widget.userRepo.updateCalorieGoal(
      calorieGoal: result.calorieGoal,
      macroGoals: result.macroGoals,
      tdeeProfile: profile,
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _chipRow<T>(String keyPrefix, List<T> values, T selected, String Function(T) label, void Function(T) onSelect) {
    return Wrap(
      spacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            key: Key('${keyPrefix}_${label(value)}'),
            label: Text(label(value)),
            selected: value == selected,
            onSelected: (_) => setState(() => onSelect(value)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Goal')),
      body: StreamBuilder<AppUser?>(
        stream: widget.userRepo.watchUser(),
        builder: (context, snapshot) {
          final existing = snapshot.data?.tdeeProfile;
          if (!_seeded && existing != null) {
            _seedFrom(existing);
            _seeded = true;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                TextField(
                  key: const Key('tdee_weight_field'),
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  key: const Key('tdee_height_field'),
                  controller: _heightController,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  key: const Key('tdee_age_field'),
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                const Text('Sex'),
                _chipRow('tdee_sex', Sex.values, _sex, (s) => s.value, (s) => _sex = s),
                const SizedBox(height: 8),
                const Text('Activity level'),
                _chipRow('tdee_activity', ActivityLevel.values, _activityLevel, (a) => a.value, (a) => _activityLevel = a),
                const SizedBox(height: 8),
                const Text('Goal'),
                _chipRow('tdee_goal', CalorieGoalDirection.values, _goal, (g) => g.value, (g) => _goal = g),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('tdee_save_button'),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
