import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Ban.dart'; // Đảm bảo đường dẫn này đúng với vị trí của file Ban.dart

class BanService {
  final CollectionReference _banCollection = FirebaseFirestore.instance.collection('Ban');

  Stream<List<Ban>> getBansStream() {
    return _banCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Ban.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Ban>> getAvailableTables() {
    return _banCollection
        .where('trangThai', isEqualTo: 'Trống')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Ban.fromMap(doc.data() as Map<String, dynamic>)).toList());
  }


  Future<List<Ban>> getBanList() async {
    try {
      QuerySnapshot snapshot = await _banCollection.get();
      return snapshot.docs.map((doc) {
        return Ban.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addBan(Ban ban) async {
    try {
      await _banCollection.doc(ban.ma).set(ban.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBan(Ban ban) async {
    try {
      await _banCollection.doc(ban.ma).update(ban.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBan(String banId) async {
    try {
      await _banCollection.doc(banId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<Ban?> getBanById(String banId) async {
    try {
      DocumentSnapshot doc = await _banCollection.doc(banId).get();
      if (doc.exists) {
        return Ban.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Ban>> getBanByTrangThai(String trangThai) async {
    try {
      QuerySnapshot snapshot = await _banCollection
          .where('trangThai', isEqualTo: trangThai)
          .get();
      return snapshot.docs.map((doc) => Ban.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Ban>> getBanBySucChuaMin(int sucChuaMin) async {
    try {
      QuerySnapshot snapshot = await _banCollection
          .where('sucChua', isGreaterThanOrEqualTo: sucChuaMin)
          .get();
      return snapshot.docs.map((doc) => Ban.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> checkTableAvailability(String? banMa, DateTime reservationDateTime) async {
    if (banMa == null) return false;

    final Duration buffer = Duration(hours: 3);
    final DateTime conflictStartTime = reservationDateTime.subtract(buffer);
    final DateTime conflictEndTime = reservationDateTime.add(buffer);
    try {
      QuerySnapshot conflictingReservations = await FirebaseFirestore.instance
          .collection('DonGoiMon')
          .where('MaBan.ma', isEqualTo: banMa)
          .where('TrangThai', isNotEqualTo: 'Hủy')
          .where('NgayGioDenDuKien', isLessThanOrEqualTo: Timestamp.fromDate(conflictEndTime))
          .where('NgayGioDenDuKien', isGreaterThanOrEqualTo: Timestamp.fromDate(conflictStartTime))
          .get();

      if (conflictingReservations.docs.isNotEmpty) {
        for (var doc in conflictingReservations.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final conflictingTime = (data['NgayGioDenDuKien'] as Timestamp).toDate();
          if (conflictingTime.isBefore(reservationDateTime) || conflictingTime.isAfter(reservationDateTime.add(buffer))) {
          } else {
            return false;
          }
        }
        return false;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }
}