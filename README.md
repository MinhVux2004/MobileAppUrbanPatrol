# urban_patrol_btl

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
1. Citizen (Người dân)
Nhiệm vụ:
Đăng nhập / đăng ký.
Chụp ảnh hiện trường.
Gửi báo cáo kèm GPS và mô tả.
Xem lại trạng thái báo cáo.
2. Worker (Công nhân / Nhân viên xử lý)
Nhiệm vụ:
Nhận sự cố đã được admin phân công.
Xử lý sự cố tại hiện trường.
Cập nhật trạng thái: assigned → in_progress → pending_review.
Gửi ảnh nghiệm thu hoàn thành để admin duyệt.
3. Admin (Quản trị / Trung tâm điều hành)
Nhiệm vụ:
Xem toàn bộ sự cố.
Phân công công nhân xử lý.
Duyệt nghiệm thu khi worker hoàn thành.
Đóng sự cố sau khi xác nhận xong.
4. Luồng dữ liệu / collections trong Firestore
users
Lưu tài khoản và có thể chứa trường role như worker (có trong code admin phân công).
reports
Nơi citizen gửi báo cáo ban đầu.
incidents
Nơi quản lý sự cố cho worker/admin xử lý.
Có các trạng thái: reported, assigned, in_progress, pending_review, closed.