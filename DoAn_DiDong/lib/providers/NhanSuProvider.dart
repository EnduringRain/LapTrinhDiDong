import 'package:doan_nhom_cuoiky/models/NhanVien.dart';
import 'package:doan_nhom_cuoiky/services/NhanSuService.dart';
import 'package:flutter/foundation.dart';

class NhanSuProvider extends ChangeNotifier {
  List<NhanVien> _nhanSu = [];
  final NhanSuService _nhanSuService = NhanSuService();

  NhanSuProvider() {
    _loadNhanSu();
  }

  Future<void> _loadNhanSu() async {
    _nhanSu = await _nhanSuService.getNhanSu();
    notifyListeners();
  }

  List<NhanVien> get nhanSu => _nhanSu;

  Future<void> addNhanVien(NhanVien nhanVien) async {
    await _nhanSuService.addNhanSu(nhanVien);
    await _loadNhanSu();
  }

  Future<void> updateNhanVien(NhanVien nhanVien) async {
    await _nhanSuService.updateNhanSu(nhanVien);
    await _loadNhanSu();
  }

  Future<void> deleteNhanVien(NhanVien nv) async {
    await _nhanSuService.deleteNhanSu(nv);
    await _loadNhanSu();
  }

  Future<bool> checkNhanVienExists(String ma) async {
    return _nhanSu.any((nv) => nv.ma == ma);
  }

String getMaNhanVien() {
  try {
    if (_nhanSu.isNotEmpty) {
      int maxNumber = 0;
      for (NhanVien nv in _nhanSu) {
        if (nv.ma != null) {
          String so = nv.ma!.replaceAll(RegExp(r'\D'), '');
          if (so.isNotEmpty) {
            int currentNumber = int.parse(so);
            if (currentNumber > maxNumber) {
              maxNumber = currentNumber;
            }
          }
        }
      }
      
      int nextNumber = maxNumber + 1;
      return 'NV${nextNumber.toString().padLeft(3, '0')}';
    } else {
      return 'NV001';
    }
  } catch (e) {
    return 'NV001';
  }
}
}
