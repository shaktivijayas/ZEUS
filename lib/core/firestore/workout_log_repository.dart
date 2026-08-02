import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise_log.dart';
import '../../models/workout_log.dart';

class WorkoutLogRepository {
  WorkoutLogRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('workoutLogs');

  Future<WorkoutLog?> getForDate(String date) async {
    final snap = await _collection.where('date', isEqualTo: date).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return WorkoutLog.fromMap(doc.id, doc.data());
  }

  Future<String> createDraft(WorkoutLog log) async {
    final ref = await _collection.add(log.toMap());
    return ref.id;
  }

  Future<void> updateLog(WorkoutLog log) async {
    await _collection.doc(log.id).set(log.toMap());
  }

  Future<void> completeLog(String logId, List<ExerciseLog> finalExercises) async {
    await _collection.doc(logId).update({
      'status': WorkoutLogStatus.completed.value,
      'exercises': finalExercises.map((e) => e.toMap()).toList(),
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Stream<List<WorkoutLog>> watchCompletedLogsForSplitDay(String splitDayId) {
    return _collection
        .where('splitDayId', isEqualTo: splitDayId)
        .where('status', isEqualTo: WorkoutLogStatus.completed.value)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => WorkoutLog.fromMap(doc.id, doc.data())).toList());
  }
}
