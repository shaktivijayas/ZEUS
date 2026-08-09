import 'package:flutter/material.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/nutrition/food_search_repository.dart';
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
    final log = await widget.foodLogRepo.getForDate(widget.date);
    await widget.foodLogRepo.saveLog(log.withEntryAdded(widget.mealType, entry));
    if (mounted) Navigator.of(context).maybePop();
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
    final calories = double.tryParse(_caloriesController.text);
    if (_nameController.text.trim().isEmpty || calories == null) return;
    await _saveEntry(FoodEntry(
      name: _nameController.text.trim(),
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
    if (result == null || quantity == null) return;
    await _saveEntry(result.scaledEntry(quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                spacing: 8,
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
            const SizedBox(height: 16),
            if (_mode == _AddFoodMode.manual) ...[
              TextField(key: const Key('manual_name_field'), controller: _nameController, decoration: const InputDecoration(labelText: 'Food name')),
              TextField(key: const Key('manual_calories_field'), controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_protein_field'), controller: _proteinController, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_carbs_field'), controller: _carbsController, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(key: const Key('manual_fat_field'), controller: _fatController, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number),
              ElevatedButton(key: const Key('manual_save_button'), onPressed: _saveManual, child: const Text('Save')),
            ] else ...[
              TextField(key: const Key('search_query_field'), controller: _searchController, decoration: const InputDecoration(labelText: 'Search food')),
              ElevatedButton(key: const Key('search_run_button'), onPressed: _runSearch, child: const Text('Search')),
              if (_searchError != null) ...[
                Text(_searchError!, key: const Key('search_error_text')),
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
                ElevatedButton(key: const Key('search_save_button'), onPressed: _saveFromSearch, child: const Text('Save')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
