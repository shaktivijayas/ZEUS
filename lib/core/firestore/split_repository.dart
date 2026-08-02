import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/split_day.dart';

class SplitRepository {
  SplitRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('splitDays');

  Stream<List<SplitDay>> watchSplitDays() {
    return _collection.orderBy('order').snapshots().map(
          (snap) => snap.docs.map((doc) => SplitDay.fromMap(doc.id, doc.data())).toList(),
        );
  }

  Future<void> saveSplitDay(SplitDay day) async {
    await _collection.doc(day.id).set(day.toMap());
  }

  Future<void> deleteSplitDay(String dayId) async {
    await _collection.doc(dayId).delete();
  }
}
