import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/food_entry.dart';
import '../../models/food_log.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class FoodLogRepository {
  FoodLogRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('foodLogs');

  Future<FoodLog> getForDate(String date) async {
    final snap = await _collection.doc(date).get();
    if (!snap.exists) return FoodLog.empty(date);
    return FoodLog.fromMap(date, snap.data()!);
  }

  Stream<FoodLog> watchForDate(String date) {
    return _collection.doc(date).snapshots().map((snap) {
      if (!snap.exists) return FoodLog.empty(date);
      return FoodLog.fromMap(date, snap.data()!);
    });
  }

  Future<void> saveLog(FoodLog log) async {
    await _collection.doc(log.date).set(log.toMap());
  }

  /// The user's own most recently logged entries across the last
  /// [lookbackDays] days (today inclusive), newest first, deduplicated by
  /// name, capped at [limit]. Powers the Add Food screen's "recently
  /// logged" quick-add — no separate food-catalog collection needed.
  Future<List<FoodEntry>> getRecentEntries(DateTime today, {int lookbackDays = 7, int limit = 10}) async {
    final startKey = _dateKey(today.subtract(Duration(days: lookbackDays - 1)));
    final endKey = _dateKey(today);
    final snap = await _collection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
        .get();

    final logs = snap.docs.map((doc) => FoodLog.fromMap(doc.id, doc.data())).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final seen = <String>{};
    final recent = <FoodEntry>[];
    for (final log in logs) {
      final allEntries = [
        ...log.meals[MealType.breakfast]!,
        ...log.meals[MealType.lunch]!,
        ...log.meals[MealType.dinner]!,
        ...log.meals[MealType.snacks]!,
      ]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final entry in allEntries) {
        if (recent.length >= limit) return recent;
        if (seen.add(entry.name)) recent.add(entry);
      }
    }
    return recent;
  }
}
