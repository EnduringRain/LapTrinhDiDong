import 'package:flutter/material.dart';
import 'package:doan_nhom_cuoiky/models/NhanVien.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ignore: camel_case_types
class Info_Screen extends StatefulWidget {
  final NhanVien? nhanVien;

  const Info_Screen({super.key, required this.nhanVien});

  @override
  // ignore: library_private_types_in_public_api
  _Info_ScreenState createState() => _Info_ScreenState();
}

// ignore: camel_case_types
class _Info_ScreenState extends State<Info_Screen> {
  final _tenNVController = TextEditingController();
  final _cccdController = TextEditingController();
  final _maController = TextEditingController();
  final _sdtController = TextEditingController();
  final _ngayVLController = TextEditingController();
  final _tkController = TextEditingController();
  final _mkController = TextEditingController();
  final _chucVuController = TextEditingController();

  bool _obscureText = true;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        widget.nhanVien?.anh = pickedFile.path;
      });
    }
  }

  // Define a color scheme
  final Color _primaryColor = const Color(0xFFFFD700);
  final Color _accentColor = const Color(0xFFE65100);
  final Color _backgroundColor = const Color(0xFFF8F8F8);
  final Color _textColor = const Color(0xFF212121);
  final Color _subtitleColor = Colors.grey[600]!;

  @override
  void initState() {
    super.initState();
    _LoadDataIntoInfo();
  }

  @override
  void dispose() {
    _tenNVController.dispose();
    _cccdController.dispose();
    _maController.dispose();
    _sdtController.dispose();
    _ngayVLController.dispose();
    _tkController.dispose();
    _mkController.dispose();
    _chucVuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thông tin nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth * 0.05),
            child: Column(
              children: [
                _buildProfileHeader(),
                SizedBox(height: constraints.maxHeight * 0.03),
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),

      backgroundColor: _backgroundColor,
    );
  }

  Widget _buildProfileHeader() {
    ImageProvider<Object> avatarImage;
    if (widget.nhanVien?.anh != null && widget.nhanVien!.anh!.isNotEmpty) {
      avatarImage = NetworkImage(widget.nhanVien!.anh!);
    } else {
      avatarImage = const NetworkImage(
        'https://via.placeholder.com/150/000000/FFFFFF?text=',
      ); // A transparent placeholder
    }
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primaryColor, _accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    widget.nhanVien?.anh != null &&
                            widget.nhanVien!.anh!.isNotEmpty
                        ? Image(image: avatarImage, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, size: 20, color: _primaryColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          _tenNVController.text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        Text(
          'Mã NV: ${_maController.text}',
          style: TextStyle(fontSize: 16, color: _subtitleColor),
        ),
        if (_tkController.text.isNotEmpty)
          Text(
            'Tài khoản: ${_tkController.text}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _accentColor),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('CCCD', _cccdController.text),
            Divider(height: 20, color: Colors.grey[200]),
            _buildInfoRow('Số điện thoại', _sdtController.text),
            Divider(height: 20, color: Colors.grey[200]),
            _buildPasswordRow('Mật khẩu', _mkController.text),
            Divider(height: 20, color: Colors.grey[200]),
            _buildInfoRow('Chức vụ', _chucVuController.text),

            Divider(height: 20, color: Colors.grey[200]),
            _buildInfoRow(
              'Ngày vào làm',
              _ngayVLController.text.isNotEmpty
                  ? _ngayVLController.text
                  : 'Chưa cập nhật',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _subtitleColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _subtitleColor,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _obscureText ? '••••••••' : value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: _primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  void _LoadDataIntoInfo() {
    _tenNVController.text = widget.nhanVien?.ten ?? '';
    _cccdController.text = widget.nhanVien?.CCCD ?? '';
    _maController.text = widget.nhanVien?.ma ?? '';
    _sdtController.text = widget.nhanVien?.SDT ?? '';
    _ngayVLController.text =
        widget.nhanVien?.ngayVL != null
            ? ' ${DateFormat('dd/MM/yyyy').format(widget.nhanVien!.ngayVL!.toDate())}'
            : 'Chưa cập nhật';
    _tkController.text = widget.nhanVien?.tk ?? '';
    _mkController.text = widget.nhanVien?.mk ?? '';
    _chucVuController.text = widget.nhanVien?.vaiTro?.ten! ?? '';
  }
}
