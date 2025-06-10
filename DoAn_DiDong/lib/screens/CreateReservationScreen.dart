import 'package:doan_nhom_cuoiky/models/DonGoiMon.dart';
import 'package:doan_nhom_cuoiky/services/BanService.dart';
import 'package:doan_nhom_cuoiky/services/DonGoiMonService.dart';
import 'package:doan_nhom_cuoiky/services/NotificationService.dart';
import 'package:doan_nhom_cuoiky/utils/QuickAlert.dart';
import 'package:doan_nhom_cuoiky/utils/Toast.dart';
import 'package:flutter/material.dart';
import 'package:doan_nhom_cuoiky/models/Ban.dart';
import 'package:doan_nhom_cuoiky/models/ChiTietGoiMon.dart';
import 'package:doan_nhom_cuoiky/models/DonDatCho.dart';
import 'package:doan_nhom_cuoiky/models/PhieuTamUng.dart';
import 'package:doan_nhom_cuoiky/screens/SelectDishesScreen.dart';
import 'package:intl/intl.dart';

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateReservationScreenState createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _customerContactController =
      TextEditingController();
  final TextEditingController _advancePaymentController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final BanService _banService = BanService();
  final DonGoiMonService _donGoiMon = DonGoiMonService();

  Ban? _selectedTable;
  List<ChiTietGoiMon> _selectedDishes = [];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    _updateAdvancePayment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timeController.text.isEmpty && _selectedTime != null) {
      _timeController.text = _selectedTime!.format(context);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneNumberController.dispose();
    _customerContactController.dispose();
    _advancePaymentController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _updateDateTimeControllers() {
    if (_selectedDate != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    } else {
      _dateController.text = '';
    }

    if (_selectedTime != null) {
      _timeController.text = _selectedTime!.format(context);
    } else {
      _timeController.text = '';
    }
    _selectedTable = null;
  }

  void _updateAdvancePayment() {
    double advancePayment;
    if (_selectedDishes.isEmpty) {
      advancePayment = 100000.0;
    } else {
      double totalOrderAmount = 0.0;
      for (var dishDetail in _selectedDishes) {
        totalOrderAmount += dishDetail.tinhTien as double;
      }
      advancePayment = totalOrderAmount * 0.40 + 100000.0;
    }
    _advancePaymentController.text = advancePayment.toStringAsFixed(0);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDateTimeControllers();
      });
    }
  }

  Future<void> _selectDishes() async {
    final List<ChiTietGoiMon>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SelectDishesScreen(initialSelectedDishes: _selectedDishes),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDishes = result;
        _updateAdvancePayment();
      });
      ToastUtils.showInfo("Đã chọn ${result.length} món ăn.");
    }
  }

  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedTable == null) {
      ToastUtils.showError("Vui lòng chọn bàn trước khi đặt món ăn.");
      return;
    }

    QuickAlertService.showAlertLoading(context, "Đang thực hiện");

    try {
      final DateTime now = DateTime.now();
      final DateTime reservationDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final bool isToday =
          _selectedDate!.year == now.year &&
          _selectedDate!.month == now.month &&
          _selectedDate!.day == now.day;

      if (isToday && _selectedTable!.trangThai != "Trống") {
        Navigator.pop(context);
        QuickAlertService.showAlertWarning(
          context,
          "Bàn ${_selectedTable!.ma} đang ở trạng thái ${_selectedTable!.trangThai}, không thể đặt cho hôm nay.",
        );
        await Future.delayed(const Duration(seconds: 2));
        return;
      }

      final bool isWithinNextHour =
          reservationDateTime.isAfter(now) &&
          reservationDateTime.difference(now).inMinutes <= 60;

      double advancePayment =
          double.tryParse(_advancePaymentController.text) ?? 0.0;

      DonDatCho newDonDatCho = DonDatCho(
        tenKhachHang: _customerNameController.text,
        soDienThoai: _phoneNumberController.text,
        ghiChu: _customerContactController.text,
        ngayDat: reservationDateTime,
      );

      PhieuTamUng? newPhieuTamUng;
      if (advancePayment > 0) {
        newPhieuTamUng = PhieuTamUng(
          soTien: advancePayment,
          ngayLap: DateTime.now(),
        );
      }

      DonGoiMon newDonGoiMon = DonGoiMon(
        ngayLap: DateTime.now(),
        ngayGioDenDuKien: reservationDateTime,
        trangThai: "Đã đặt",
        ghiChu: "",
        maBan: _selectedTable,
      );

      await _donGoiMon.addReservation(
        newDonGoiMon,
        _selectedDishes,
        newDonDatCho,
        newPhieuTamUng,
        isWithinNextHour,
      );

      await NotificationService().scheduleReservationNotification(newDonDatCho);

      if (_selectedTable?.ma != null && isWithinNextHour) {
        await _banService.updateBanStatus(_selectedTable!.ma!, "Đã đặt");
        setState(() {
          _selectedTable!.trangThai = "Đã đặt";
        });
      }

      Navigator.pop(context);
      QuickAlertService.showAlertSuccess(context, "Đặt bàn thành công");
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      QuickAlertService.showAlertFailure(context, "Đặt bàn thất bại: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isConfirmButtonAlwaysEnabled =
        _selectedTable != null &&
        _selectedDate != null &&
        _selectedTime != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo phiếu đặt')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Thông tin khách hàng',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Tên khách hàng'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _customerContactController,
                decoration: const InputDecoration(labelText: 'Liên hệ khách'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Thông tin đặt bàn',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              InkWell(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày đến',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Vui lòng chọn ngày đến' : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ đến',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Vui lòng chọn giờ đến' : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Ban>>(
                stream: _banService.getAvailableTables(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  final allTables = snapshot.data ?? [];

                  final bool isToday =
                      _selectedDate!.year == DateTime.now().year &&
                      _selectedDate!.month == DateTime.now().month &&
                      _selectedDate!.day == DateTime.now().day;

                  List<Ban> displayTables = [];

                  if (isToday) {
                    displayTables =
                        allTables
                            .where(
                              (ban) =>
                                  ban.trangThai == "Trống" && ban.ma != null,
                            )
                            .toList();
                  } else {
                    displayTables =
                        allTables.where((ban) => ban.ma != null).map((ban) {
                          return Ban(
                            ma: ban.ma,
                            sucChua: ban.sucChua,
                            viTri: ban.viTri,
                            trangThai: "Trống",
                          );
                        }).toList();
                  }

                  if (_selectedTable != null) {
                    try {
                      final matchingTable = displayTables.firstWhere(
                        (ban) => ban.ma == _selectedTable!.ma,
                      );
                      _selectedTable = matchingTable;
                    } catch (e) {
                      _selectedTable = null;
                    }
                  }

                  if (displayTables.isEmpty) {
                    return const Text('Không có bàn nào phù hợp để đặt.');
                  }

                  return DropdownButtonFormField<Ban>(
                    decoration: const InputDecoration(labelText: 'Bàn'),
                    value: _selectedTable,
                    items:
                        displayTables.map((ban) {
                          return DropdownMenuItem<Ban>(
                            value: ban,
                            child: Text("Vị trí: ${ban.viTri ?? 'N/A'}"),
                          );
                        }).toList(),
                    onChanged: (Ban? newValue) {
                      setState(() {
                        _selectedTable = newValue;
                      });
                    },
                    validator:
                        (value) => value == null ? 'Vui lòng chọn bàn' : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _selectDishes,
                child: const Text('Chọn món ăn'),
              ),
              if (_selectedDishes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Món đã chọn:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._selectedDishes.map(
                      (ctgm) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '${ctgm.getMonAn?.getTen ?? 'Món không tên'} x ${ctgm.getSoLuong ?? 0}',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                controller: _advancePaymentController,
                decoration: const InputDecoration(labelText: 'Tiền tạm ứng'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Vui lòng nhập số tiền hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    isConfirmButtonAlwaysEnabled ? _createReservation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isConfirmButtonAlwaysEnabled ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
