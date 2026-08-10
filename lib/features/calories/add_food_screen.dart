import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/nutrition/food_search_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/food_entry.dart';
import '../../models/food_log.dart';

enum _AddFoodMode { manual, search }

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({
    super.key,
    required this.foodLogRepo,
    required this.foodSearchRepo,
    required this.date,
    required this.mealType,
  });

  final FoodLogRepository foodLogRepo;
  final FoodSearchRepository foodSearchRepo;
  final String date;
  final MealType mealType;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  _AddFoodMode _mode = _AddFoodMode.manual;

  final _searchController = TextEditingController();
  List<FoodSearchResult> _searchResults = const [];
  FoodSearchResult? _selectedResult;
  final _quantityController = TextEditingController(text: '100');
  String? _searchError;

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');

  List<FoodEntry> _recentEntries = const [];

  /// True while a save is in flight, to prevent a double-tap from firing a
  /// second concurrent read-modify-write against the day's Firestore doc.
  bool _saving = false;

  /// Feedback shown for invalid input or a save failure. Kept as a single
  /// field (rather than per-mode) since manual/search are mutually
  /// exclusive via `_mode`.
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await widget.foodLogRepo.getRecentEntries(DateTime.now().toUtc());
    if (mounted) setState(() => _recentEntries = recent);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searchError = null);
    try {
      final results = await widget.foodSearchRepo.search(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchError = 'Search failed. You can switch to manual entry below.');
    }
  }

  Future<void> _saveEntry(FoodEntry entry) async {
    // Guard against a second tap firing a concurrent read-modify-write
    // before the first save completes.
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    // Capture the app-root ScaffoldMessenger before any pop, so a failure
    // that surfaces after this screen has already been popped can still
    // show feedback on the screen the user lands back on.
    final messenger = ScaffoldMessenger.of(context);
    final foodLogRepo = widget.foodLogRepo;
    final date = widget.date;
    final mealType = widget.mealType;

    // Clears the in-flight flag once the *actual* write settles (not just
    // once it's been kicked off) so the save button — and the double-submit
    // guard above — stay engaged for the real duration of the save, even
    // though we don't block popping on it below.
    void clearSaving() {
      if (mounted) setState(() => _saving = false);
    }

    try {
      final log = await foodLogRepo.getForDate(date);
      final writeFuture = foodLogRepo.saveLog(log.withEntryAdded(mealType, entry));

      // Offline-first: Firestore's local cache already makes this write
      // durable, so don't block popping the screen on the network
      // round-trip to the server (awaiting it here would leave the user
      // stuck on this screen indefinitely while offline). A genuine
      // failure (e.g. permission-denied) is not swallowed though — it's
      // still caught and surfaced via the messenger captured above.
      unawaited(writeFuture.then((_) {
        clearSaving();
      }).catchError((Object e) {
        messenger.showSnackBar(SnackBar(content: Text('Failed to save entry: $e')));
        clearSaving();
      }));

      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = 'Failed to save entry: $e');
      clearSaving();
    }
  }

  void _fillManualFrom(FoodEntry entry) {
    setState(() {
      _mode = _AddFoodMode.manual;
      _nameController.text = entry.name;
      _caloriesController.text = entry.calories.toString();
      _proteinController.text = entry.protein.toString();
      _carbsController.text = entry.carbs.toString();
      _fatController.text = entry.fat.toString();
    });
  }

  Future<void> _saveManual() async {
    final name = _nameController.text.trim();
    final calories = double.tryParse(_caloriesController.text);
    if (name.isEmpty || calories == null) {
      setState(() => _saveError = 'Enter a food name and a valid calorie amount.');
      return;
    }
    await _saveEntry(FoodEntry(
      name: name,
      calories: calories,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      quantity: null,
      unit: null,
      source: FoodEntrySource.manual,
      loggedAt: DateTime.now().toUtc(),
    ));
  }

  Future<void> _saveFromSearch() async {
    final result = _selectedResult;
    final quantity = double.tryParse(_quantityController.text);
    if (result == null || quantity == null) {
      setState(() => _saveError = 'Select a result and enter a valid quantity.');
      return;
    }
    await _saveEntry(result.scaledEntry(quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: [
            Row(
              children: [
                TextButton(
                  key: const Key('add_food_mode_manual'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.manual),
                  child: const Text('Manual'),
                ),
                TextButton(
                  key: const Key('add_food_mode_search'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.search),
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_recentEntries.isNotEmpty) ...[
              const Text('Recently logged', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final entry in _recentEntries)
                    ActionChip(
                      key: Key('recent_entry_${entry.name}'),
                      label: Text(entry.name),
                      onPressed: () => _fillManualFrom(entry),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_saveError != null) Text(_saveError!, key: const Key('save_error_text'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_mode == _AddFoodMode.manual) ...[
              TextField(key: const Key('manual_name_field'), controller: _nameController, decoration: const InputDecoration(labelText: 'Food name')),
              TextField(key: const Key('manual_calories_field'), controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_protein_field'), controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_carbs_field'), controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_fat_field'), controller: _fatController, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number),
              ElevatedButton(key: const Key('manual_save_button'), onPressed: _saving ? null : _saveManual, child: const Text('Save')),
            ] else ...[
              TextField(key: const Key('search_query_field'), controller: _searchController, decoration: const InputDecoration(labelText: 'Search food')),
              ElevatedButton(key: const Key('search_run_button'), onPressed: _runSearch, child: const Text('Search')),
              if (_searchError != null) ...[
                Text(_searchError!, key: const Key('search_error_text'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                TextButton(
                  key: const Key('search_switch_to_manual'),
                  onPressed: () => setState(() => _mode = _AddFoodMode.manual),
                  child: const Text('Switch to manual entry'),
                ),
              ],
              for (final result in _searchResults)
                ListTile(
                  key: Key('search_result_${result.name}'),
                  title: Text(result.name),
                  subtitle: Text('${result.caloriesPer100g.round()} kcal / 100g'),
                  selected: _selectedResult == result,
                  onTap: () => setState(() => _selectedResult = result),
                ),
              if (_selectedResult != null) ...[
                TextField(key: const Key('search_quantity_field'), controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity (g)'), keyboardType: TextInputType.number),
                ElevatedButton(key: const Key('search_save_button'), onPressed: _saving ? null : _saveFromSearch, child: const Text('Save')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
