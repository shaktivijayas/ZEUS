enum FoodEntrySource {
  manual('manual'),
  openFoodFacts('openfoodfacts');

  const FoodEntrySource(this.value);

  final String value;

  static FoodEntrySource fromValue(String value) {
    return FoodEntrySource.values.firstWhere((s) => s.value == value);
  }
}

/// A single logged food item. [calories]/[protein]/[carbs]/[fat] are always
/// the total for this entry, never a per-100g figure — for [FoodEntrySource.openFoodFacts]
/// entries they're computed by scaling a search result's per-100g data by
/// [quantity] grams at save time; for [FoodEntrySource.manual] entries the
/// user types the totals directly and [quantity]/[unit] stay null since
/// there's no per-100g baseline to scale from.
class FoodEntry {
  const FoodEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.quantity,
    required this.unit,
    required this.source,
    required this.loggedAt,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? quantity;
  final String? unit;
  final FoodEntrySource source;
  final DateTime loggedAt;

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      source: FoodEntrySource.fromValue(map['source'] as String),
      loggedAt: DateTime.parse(map['loggedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity': quantity,
        'unit': unit,
        'source': source.value,
        'loggedAt': loggedAt.toIso8601String(),
      };
}
