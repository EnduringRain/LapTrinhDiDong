import 'package:doan_nhom_cuoiky/models/DonDatCho.dart';
import 'package:flutter/foundation.dart';
import '../services/DonDatChoService.dart';

class DonDatChoProvider extends ChangeNotifier {
  List<DonDatCho> _donDatChoList = [];
  final DonDatChoService _donDatChoService = DonDatChoService();

  List<DonDatCho> get donDatChoList => _donDatChoList;

  DonDatChoProvider() {
    _loadDonDatCho();
  }

  Future<void> _loadDonDatCho() async {
    _donDatChoList = await _donDatChoService.getDonDatCho();
    notifyListeners();
  }

  Future<void> addDonDatCho(DonDatCho donDatCho) async {
    await _donDatChoService.addDonDatCho(donDatCho);
    await _loadDonDatCho();
  }

  Future<void> deleteDonDatCho(String id) async {
    await _donDatChoService.deleteDonDatCho(id);
    await _loadDonDatCho();
  }

  Future<void> updateDonDatCho(DonDatCho donDatCho) async {
    await _donDatChoService.updateDonDatCho(donDatCho);
    await _loadDonDatCho();
  }
}