// File: lib/services/MonAnService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doan_nhom_cuoiky/models/MonAn.dart';

import '../models/ThucDon.dart'; // Đảm bảo MonAn có toMap() và fromMap()

class MonAnService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _monAnCollection = FirebaseFirestore.instance.collection('MonAn');

  Stream<List<MonAn>> getAllMonAn() {
    return _firestore.collection('MonAn').snapshots().map((snapshot) =>
    snapshot.docs.map((doc) => MonAn.fromMap(doc.data())).toList());
  }

  Future<List<MonAn>> getMonAnByThucDon(String maThucDon) async {
    try {
      QuerySnapshot snapshot = await _monAnCollection
          .where('ThucDon.ma', isEqualTo: maThucDon)
          .get();
      return snapshot.docs
          .map((doc) => MonAn.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error getting MonAn by ThucDon: $e");
      return [];
    }
  }

  Future<List<ThucDon>> getAllThucDonCategories() async {
    try {
      QuerySnapshot snapshot = await _monAnCollection.get();
      Set<ThucDon> uniqueThucDon = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('ThucDon') && data['ThucDon'] != null) {
          uniqueThucDon.add(ThucDon.fromMap(data['ThucDon'] as Map<String, dynamic>));
        }
      }
      return uniqueThucDon.toList();
    } catch (e) {
      return [];
    }
  }
}