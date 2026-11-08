# TaskManager — Flutter Frontend (Case Study 2)

Ứng dụng Flutter Quản lý và Giao công việc nhóm kết nối với Node.js/Express REST API.

## Cấu hình địa chỉ Backend API
Mặc định trong `lib/utils/constants.dart`:
- Android Emulator: `http://10.0.2.2:3000/api`
- Web / Windows / iOS Simulator: `http://localhost:3000/api`
Có thể đổi trực tiếp qua biến `--dart-define=API_BASE_URL=http://localhost:3000/api`.
