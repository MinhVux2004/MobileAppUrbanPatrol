import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Biến lưu trữ thông tin người dùng để hiển thị và cập nhật trực tiếp trên UI
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Hàm tải dữ liệu người dùng từ Firestore hoặc Auth
  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData = {
            'name': currentUser.displayName ?? 'Chưa cập nhật tên',
            'email': currentUser.email ?? 'Chưa cập nhật',
            'phone': currentUser.phoneNumber ?? 'Chưa cập nhật',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Hàm mở hộp thoại cập nhật số điện thoại
  void _showEditPhoneDialog() {
    final TextEditingController phoneController =
        TextEditingController(text: _userData['phone'] == 'Chưa cập nhật' ? '' : _userData['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật số điện thoại'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Nhập số điện thoại mới',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4358EE)),
            onPressed: () async {
              String newPhone = phoneController.text.trim();
              if (newPhone.isEmpty) return;

              User? currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                // Cập nhật lên Cloud Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({'phone': newPhone});

                // Cập nhật lại giao diện ngay lập tức
                setState(() {
                  _userData['phone'] = newPhone;
                });
              }

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật số điện thoại thành công!')),
              );
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4358EE)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4358EE).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF4358EE),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData['name'] ?? 'Chưa cập nhật tên',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Email', _userData['email'] ?? 'Chưa cập nhật', null),
                        const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
                        // Hàng Số điện thoại có kèm nút chỉnh sửa (icon cây bút)
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Số điện thoại',
                          _userData['phone'] ?? 'Chưa cập nhật',
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Color(0xFF4358EE)),
                            onPressed: _showEditPhoneDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Widget? trailing) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEFF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4358EE), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}