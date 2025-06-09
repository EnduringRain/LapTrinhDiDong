// ignore: file_names
import 'package:doan_nhom_cuoiky/providers/BanProvider.dart';
import 'package:doan_nhom_cuoiky/providers/DonGoiMonProvider.dart';
import 'package:doan_nhom_cuoiky/utils/QuickAlert.dart';
import 'package:flutter/material.dart';
import 'package:doan_nhom_cuoiky/models/MonAn.dart';
import 'package:doan_nhom_cuoiky/models/DonGoiMon.dart';
import 'package:doan_nhom_cuoiky/models/Ban.dart';
import 'package:doan_nhom_cuoiky/models/ChiTietGoiMon.dart';
import 'package:doan_nhom_cuoiky/providers/ChiTietDonGoiMonProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class ChiTietGoiMonScreen extends StatefulWidget {
  final Map<MonAn, int> cartItems;
  final Ban selectedBan;

  const ChiTietGoiMonScreen({
    super.key,
    required this.cartItems,
    required this.selectedBan,
  });

  @override
  State<ChiTietGoiMonScreen> createState() => _ChiTietGoiMonScreenState();
}

class _ChiTietGoiMonScreenState extends State<ChiTietGoiMonScreen> {
  late Map<MonAn, int> _localCartItems;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localCartItems = Map.from(widget.cartItems);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _increaseQuantity(MonAn monAn) {
    setState(() {
      _localCartItems.update(monAn, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decreaseQuantity(MonAn monAn) {
    setState(() {
      if (_localCartItems.containsKey(monAn)) {
        if (_localCartItems[monAn]! > 1) {
          _localCartItems[monAn] = _localCartItems[monAn]! - 1;
        } else {
          _localCartItems.remove(monAn);
        }
      }
    });
  }

  double get _calculateGrandTotal {
    double total = 0.0;
    _localCartItems.forEach((monAn, quantity) {
      total += (monAn.getGiaBan ?? 0.0) * quantity;
    });
    return total;
  }

  Future<void> _confirmOrder() async {
    if (_localCartItems.isEmpty) {
      QuickAlertService.showAlertWarning(context, "Vui lòng chọn món");
      await Future.delayed(const Duration(seconds: 2));
      return;
    }
    QuickAlertService.showAlertLoading(
      context,
      "Đang tiến hành. Vui lòng đợi trong giây lát",
    );
    final chiTietProvider = Provider.of<ChiTietDonGoiMonProvider>(
      context,
      listen: false,
    );
    final donGoiMonProvider = Provider.of<DonGoiMonProvider>(
      context,
      listen: false,
    );
    final banProvider = Provider.of<BanProvider>(context, listen: false);
    DonGoiMon? donGoiMonToUse;

    try {
      donGoiMonToUse = await donGoiMonProvider.getNewDocumentId(
        widget.selectedBan.ma!,
      );
    } catch (e) {
      donGoiMonToUse = null;
    }

    Ban updatedBan = Ban(
      ma: widget.selectedBan.ma,
      viTri: widget.selectedBan.viTri,
      sucChua: widget.selectedBan.sucChua,
      trangThai: "Đang phục vụ",
    );

    await banProvider.updateBan(updatedBan);

    if (donGoiMonToUse == null) {
      String donGoiMonId = "D${DateTime.now().microsecondsSinceEpoch}";
      donGoiMonToUse = DonGoiMon(
        ma: donGoiMonId,
        ngayLap: Timestamp.now().toDate(),
        trangThai: "Đang phục vụ",
        ghiChu: _notesController.text.trim(),
        maBan: updatedBan,
      );

      try {
        await donGoiMonProvider.addDonGoiMon(donGoiMonToUse);
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        QuickAlertService.showAlertFailure(context, "Lỗi khi tạo đơn gọi món");
        return;
      }
    }

    if (donGoiMonToUse.ma == null) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      QuickAlertService.showAlertFailure(context, "Lỗi khi tạo đơn gọi món");
      return;
    }

    // Lấy danh sách chi tiết đơn gọi món hiện tại
    List<ChiTietGoiMon> dsChiTietDGM = chiTietProvider.getChiTietById(
      donGoiMonToUse.ma!,
    );

    try {
      if (dsChiTietDGM.isEmpty) {
        for (var entry in _localCartItems.entries) {
          MonAn monAn = entry.key;
          int soLuong = entry.value;

          String chiTietId =
              'CTGM_${donGoiMonToUse.ma}_${monAn.getMa}_${DateTime.now().microsecondsSinceEpoch}';

          ChiTietGoiMon chiTiet = ChiTietGoiMon(
            ma: chiTietId,
            monAn: monAn,
            soLuong: soLuong,
            maDonGoiMon: donGoiMonToUse,
          );

          await chiTietProvider.addChiTietDonGoiMon(chiTiet);
        }
      } else {
        Map<String, bool> processedItems = {};

        for (ChiTietGoiMon ctgm in dsChiTietDGM) {
          String monAnMa = (ctgm.getMonAn as MonAn).getMa ?? '';
          for (var entry in _localCartItems.entries) {
            if (monAnMa == (entry.key.getMa ?? '')) {
              ctgm.soLuong = (ctgm.getSoLuong ?? 0) + entry.value;
              await chiTietProvider.updateChiTietDonGoiMon(ctgm);
              processedItems[entry.key.getMa ?? ''] = true;
              break;
            }
          }
        }

        for (var entry in _localCartItems.entries) {
          if (processedItems[entry.key.getMa ?? ''] != true) {
            String chiTietId =
                'CTGM_${donGoiMonToUse.ma}_${entry.key.getMa}_${DateTime.now().microsecondsSinceEpoch}';

            ChiTietGoiMon chiTiet = ChiTietGoiMon(
              ma: chiTietId,
              monAn: entry.key,
              soLuong: entry.value,
              maDonGoiMon: donGoiMonToUse,
            );

            await chiTietProvider.addChiTietDonGoiMon(chiTiet);
          }
        }
      }

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      QuickAlertService.showAlertSuccess(context, "Đặt món thành công");
      await Future.delayed(const Duration(seconds: 2));
      _localCartItems.clear();
      Navigator.pop(context);
      Navigator.pop(context);

    } catch (e) {
      Navigator.pop(context);
      QuickAlertService.showAlertFailure(context, "Lỗi khi đặt món $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _localCartItems);
          },
        ),
        title: Text('Chi tiết gọi món - ${widget.selectedBan.ma}'),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _localCartItems.isEmpty
                    ? const Center(
                      child: Text(
                        'Giỏ hàng trống!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _localCartItems.length,
                      itemBuilder: (context, index) {
                        final monAn = _localCartItems.keys.elementAt(index);
                        final quantity = _localCartItems[monAn]!;
                        final itemTotal = (monAn.getGiaBan ?? 0.0) * quantity;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    monAn.getTen,

                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'SL: $quantity',
                                    style: const TextStyle(fontSize: 15.0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${monAn.getGiaBan?.toStringAsFixed(0)} VNĐ',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${itemTotal.toStringAsFixed(0)} VNĐ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: Colors.blue.shade700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _decreaseQuantity(monAn),
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _increaseQuantity(monAn),
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú (ví dụ: ít cay, nhiều đá...)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12.0),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_calculateGrandTotal.toStringAsFixed(0)} VNĐ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
