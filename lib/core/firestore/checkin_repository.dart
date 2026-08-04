import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/check_in.dart';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class CheckInRepository {
  CheckInRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('checkIns');

  FirebaseFirestore get firestoreInstance => _firestore;

  DocumentReference<Map<String, dynamic>> docRefFor(String date) => _collection.doc(date);

  Future<CheckIn?> getCheckIn(String date) async {
    final snap = await _collection.doc(date).get();
    if (!snap.exists) return null;
    return CheckIn.fromMap(date, snap.data()!);
  }

  Future<void> writeCheckIn(CheckIn checkIn) async {
    await _collection.doc(checkIn.date).set(checkIn.toMap());
  }

  Future<void> writeCheckIns(List<CheckIn> checkIns) async {
    final batch = _firestore.batch();
    for (final checkIn in checkIns) {
      batch.set(_collection.doc(checkIn.date), checkIn.toMap());
    }
    await batch.commit();
  }

  /// Most recent date with any checkIns doc at or before [today], or null
  /// if none exist. Clamping to <= today matters: a future-dated doc (e.g.
  /// a rest day pre-marked ahead of time via the calendar) must never be
  /// treated as "last activity," or the gap-walk's cursor would start
  /// after today and its loop would never execute again.
  Future<DateTime?> getLastActivityDate(DateTime today) async {
    final todayKey = _dateKey(today);
    final snap = await _collection
        .where(FieldPath.documentId, isLessThanOrEqualTo: todayKey)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final parts = snap.docs.first.id.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  /// Docs strictly between [startExclusive] and [endExclusive], keyed by date string.
  Future<Map<String, CheckIn>> getCheckInsInRange(DateTime startExclusive, DateTime endExclusive) async {
    final startKey = _dateKey(startExclusive);
    final endKey = _dateKey(endExclusive);
    final snap = await _collection
        .where(FieldPath.documentId, isGreaterThan: startKey)
        .where(FieldPath.documentId, isLessThan: endKey)
        .get();
    return {for (final doc in snap.docs) doc.id: CheckIn.fromMap(doc.id, doc.data())};
  }

  Stream<List<CheckIn>> watchCheckInsForMonth(int year, int month) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return _collection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$prefix-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$prefix-31')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CheckIn.fromMap(doc.id, doc.data())).toList());
  }
}
