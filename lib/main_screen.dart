import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Thêm import FirebaseAuth
import 'views/citizen/citizen_report_screen.dart';
import 'views/citizen/report_list_screen.dart';
import 'map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CitizenReportScreen(), // Tab 0: Gửi phản ánh
    ReportListScreen(),    // Tab 1: Danh sách báo cáo
    MapScreen(),           // Tab 2: Bản đồ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm AppBar chung cho các tab để có chỗ đặt nút Đăng xuất
      appBar: AppBar(
        title: const Text('UrbanPatrol - Quản lý sự cố'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              // Hiển thị hộp thoại xác nhận trước khi đăng xuất
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Thực hiện đăng xuất khỏi Firebase
                await FirebaseAuth.instance.signOut();
                // Nhờ có StreamBuilder ở main.dart, ứng dụng sẽ tự động chuyển về LoginScreen ngay lập tức!
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Gửi phản ánh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Danh sách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
        ],
      ),
    );
  }
}