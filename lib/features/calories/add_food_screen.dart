import 'dart:async';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/firestore/food_log_repository.dart';
import '../../core/nutrition/food_search_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/apple_fitness_palette.dart';
import '../../models/food_entry.dart';
import '../../models/food_log.dart';

enum _AddFoodMode { manual, search }

/// Apple's real SF Pro can't be licensed/bundled for Android, so Inter — the
/// closest freely-licensed geometric sans and the community's standard
/// SF Pro stand-in on non-Apple platforms — is used for this screen's
/// Apple-styled headings and labels instead of the app-wide Roboto type
/// scale (AppTypography).
TextStyle _appleFont({required double fontSize, required FontWeight fontWeight, required Color color, double? letterSpacing}) {
  return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing);
}

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
      backgroundColor: ApplePalette.background,
      appBar: AppBar(
        backgroundColor: ApplePalette.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: ApplePalette.exerciseGreen, size: 28),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Add Food',
          style: _appleFont(fontSize: 20, fontWeight: FontWeight.bold, color: ApplePalette.primaryText, letterSpacing: -0.4),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: [
            _ModeSegmentedControl(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
            if (_recentEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Recently logged', style: _appleFont(fontSize: 15, fontWeight: FontWeight.w600, color: ApplePalette.primaryText)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in _recentEntries)
                    GestureDetector(
                      key: Key('recent_entry_${entry.name}'),
                      onTap: () => _fillManualFrom(entry),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(color: ApplePalette.divider, borderRadius: BorderRadius.circular(20)),
                        child: Text(entry.name, style: _appleFont(fontSize: 14, fontWeight: FontWeight.w500, color: ApplePalette.primaryText)),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  _saveError!,
                  key: const Key('save_error_text'),
                  style: _appleFont(fontSize: 14, fontWeight: FontWeight.w500, color: ApplePalette.moveRed),
                ),
              ),
            if (_mode == _AddFoodMode.manual) ...[
              _FormCard(children: [
                _FormRow(label: 'Food name', child: TextField(
                  key: const Key('manual_name_field'),
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(),
                )),
                _FormRow(label: 'Calories', child: TextField(
                  key: const Key('manual_calories_field'),
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(),
                )),
                _FormRow(label: 'Protein (g)', child: TextField(
                  key: const Key('manual_protein_field'),
                  controller: _proteinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(),
                )),
                _FormRow(label: 'Carbs (g)', child: TextField(
                  key: const Key('manual_carbs_field'),
                  controller: _carbsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(),
                )),
                _FormRow(label: 'Fat (g)', isLast: true, child: TextField(
                  key: const Key('manual_fat_field'),
                  controller: _fatController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(),
                )),
              ]),
              const SizedBox(height: AppSpacing.lg),
              _PillButton(
                buttonKey: const Key('manual_save_button'),
                label: 'Save',
                onPressed: _saving ? null : _saveManual,
              ),
            ] else ...[
              _FormCard(children: [
                _FormRow(label: 'Search', isLast: true, child: TextField(
                  key: const Key('search_query_field'),
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                  decoration: _rowInputDecoration(hintText: 'Food name'),
                )),
              ]),
              const SizedBox(height: AppSpacing.md),
              _PillButton(buttonKey: const Key('search_run_button'), label: 'Search', onPressed: _runSearch),
              if (_searchError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    _searchError!,
                    key: const Key('search_error_text'),
                    style: _appleFont(fontSize: 14, fontWeight: FontWeight.w500, color: ApplePalette.moveRed),
                  ),
                ),
                GestureDetector(
                  key: const Key('search_switch_to_manual'),
                  onTap: () => setState(() => _mode = _AddFoodMode.manual),
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Switch to manual entry',
                      style: _appleFont(fontSize: 15, fontWeight: FontWeight.w600, color: ApplePalette.exerciseGreen),
                    ),
                  ),
                ),
              ],
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _FormCard(children: [
                  for (var i = 0; i < _searchResults.length; i++)
                    _SearchResultRow(
                      key: Key('search_result_${_searchResults[i].name}'),
                      result: _searchResults[i],
                      selected: _selectedResult == _searchResults[i],
                      isLast: i == _searchResults.length - 1,
                      onTap: () => setState(() => _selectedResult = _searchResults[i]),
                    ),
                ]),
              ],
              if (_selectedResult != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _FormCard(children: [
                  _FormRow(label: 'Quantity (g)', isLast: true, child: TextField(
                    key: const Key('search_quantity_field'),
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText),
                    decoration: _rowInputDecoration(),
                  )),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _PillButton(
                  buttonKey: const Key('search_save_button'),
                  label: 'Save',
                  onPressed: _saving ? null : _saveFromSearch,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// The app-wide InputDecorationTheme (see AppTheme) sets enabledBorder/
// focusedBorder/errorBorder directly, which each win over a bare `border:`
// override on a per-field InputDecoration — every border variant has to be
// nulled out explicitly, or the legacy light-theme outline still shows up
// on this black form.
InputDecoration _rowInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.dateGray),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );
}

/// The unified iOS-style grouped-list container — a single rounded card
/// holding a column of label/value rows, hairline-divided between them.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: ApplePalette.card, borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child, this.isLast = false});

  final String label;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Text(label, style: _appleFont(fontSize: 15, fontWeight: FontWeight.w400, color: ApplePalette.primaryText)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
            ],
          ),
        ),
        if (!isLast) Padding(padding: const EdgeInsets.only(left: AppSpacing.md), child: Container(height: 1, color: ApplePalette.divider.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({super.key, required this.result, required this.selected, required this.isLast, required this.onTap});

  final FoodSearchResult result;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: selected ? ApplePalette.exerciseGreen.withValues(alpha: 0.12) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name, style: _appleFont(fontSize: 15, fontWeight: FontWeight.w500, color: ApplePalette.primaryText)),
                      const SizedBox(height: 2),
                      Text('${result.caloriesPer100g.round()} kcal / 100g', style: _appleFont(fontSize: 13, fontWeight: FontWeight.w400, color: ApplePalette.dateGray)),
                    ],
                  ),
                ),
                if (selected) const Icon(CupertinoIcons.checkmark_circle_fill, color: ApplePalette.exerciseGreen, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) Padding(padding: const EdgeInsets.only(left: AppSpacing.md), child: Container(height: 1, color: ApplePalette.divider.withValues(alpha: 0.6))),
      ],
    );
  }
}

/// Native iOS segmented control: a rounded pill track with a smooth,
/// floating capsule behind whichever segment is active.
class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({required this.mode, required this.onChanged});

  final _AddFoodMode mode;
  final ValueChanged<_AddFoodMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: ApplePalette.card, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: _segment(context, 'Manual', _AddFoodMode.manual, const Key('add_food_mode_manual'))),
          Expanded(child: _segment(context, 'Search', _AddFoodMode.search, const Key('add_food_mode_search'))),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, _AddFoodMode value, Key key) {
    final active = mode == value;
    return GestureDetector(
      key: key,
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEBEBF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: _appleFont(fontSize: 14, fontWeight: FontWeight.w600, color: active ? Colors.black : ApplePalette.dateGray),
        ),
      ),
    );
  }
}

/// The premium iOS-style pill action button — fully rounded, comfortable
/// vertical padding, floating with clean side margins.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.buttonKey, required this.label, required this.onPressed});

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ApplePalette.exerciseGreen,
          disabledBackgroundColor: ApplePalette.exerciseGreen.withValues(alpha: 0.4),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 0,
        ),
        child: Text(label, style: _appleFont(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
      ),
    );
  }
}
