import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCollectionService<T> {
  FirestoreCollectionService({
    required this.collection,
    required this.fromMap,
    required this.toMap,
  });

  final CollectionReference<Map<String, dynamic>> collection;
  final T Function(Map<String, dynamic> data) fromMap;   // Map -> objek
  final Map<String, dynamic> Function(T item) toMap;     // objek -> Map

  /// Stream: otomatis memancarkan daftar baru tiap data Firestore berubah.
  Stream<List<T>> watchAll({String? orderBy, bool descending = false}) {
    Query<Map<String, dynamic>> q = collection;
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    return q.snapshots().map((s) => s.docs.map((d) => fromMap(d.data())).toList());
  }

  Future<void> set(String id, T item) => collection.doc(id).set(toMap(item));
  Future<void> add(T item) => collection.add(toMap(item));
  Future<void> delete(String id) => collection.doc(id).delete();
}