import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/food_entry.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  /// Scales this result's per-100g nutrition figures by [quantityGrams] into
  /// a saveable [FoodEntry] with totals, per the spec's "entries store
  /// totals, never per-100g figures" rule.
  FoodEntry scaledEntry(double quantityGrams) {
    return FoodEntry(
      name: name,
      calories: caloriesPer100g * quantityGrams / 100,
      protein: proteinPer100g * quantityGrams / 100,
      carbs: carbsPer100g * quantityGrams / 100,
      fat: fatPer100g * quantityGrams / 100,
      quantity: quantityGrams,
      unit: 'g',
      source: FoodEntrySource.openFoodFacts,
      loggedAt: DateTime.now().toUtc(),
    );
  }
}

class FoodSearchException implements Exception {
  FoodSearchException(this.message);

  final String message;

  @override
  String toString() => 'FoodSearchException: $message';
}

class FoodSearchRepository {
  FoodSearchRepository(this._client, {this.timeout = const Duration(seconds: 10)});

  final http.Client _client;

  /// How long to wait for Open Food Facts to respond before giving up.
  /// Overridable (e.g. in tests) to avoid real network-length waits.
  final Duration timeout;

  static final _endpoint = Uri.parse('https://world.openfoodfacts.org/api/v2/search');

  // Open Food Facts' API usage policy requires a descriptive User-Agent
  // identifying the calling app; requests without one risk throttling/403s.
  static const _headers = {'User-Agent': 'ZEUS/1.0 (Android)'};

  Future<List<FoodSearchResult>> search(String query) async {
    final uri = _endpoint.replace(queryParameters: {
      'search_terms': query,
      'fields': 'product_name,nutriments',
      'page_size': '20',
    });

    http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(timeout);
    } on TimeoutException {
      throw FoodSearchException('Open Food Facts request timed out');
    }
    if (response.statusCode != 200) {
      throw FoodSearchException('Open Food Facts returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final products = body['products'] as List<dynamic>? ?? [];

    return products
        .map((p) => _parseProduct(Map<String, dynamic>.from(p as Map)))
        .whereType<FoodSearchResult>()
        .toList();
  }

  FoodSearchResult? _parseProduct(Map<String, dynamic> product) {
    final name = product['product_name'] as String?;
    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (name == null || name.trim().isEmpty || nutriments == null) return null;

    final calories = nutriments['energy-kcal_100g'];
    final protein = nutriments['proteins_100g'];
    final carbs = nutriments['carbohydrates_100g'];
    final fat = nutriments['fat_100g'];
    if (calories is! num || protein is! num || carbs is! num || fat is! num) return null;

    return FoodSearchResult(
      name: name,
      caloriesPer100g: calories.toDouble(),
      proteinPer100g: protein.toDouble(),
      carbsPer100g: carbs.toDouble(),
      fatPer100g: fat.toDouble(),
    );
  }
}
