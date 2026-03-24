# Mobile-Flutter

Ứng dụng quản lý tủ lạnh thông minh (mobile + web) với backend ASP.NET Core + PostgreSQL và frontend Flutter. Người dùng có thể đăng nhập bằng email/password hoặc OTP (email/phone), quản lý nguyên liệu, lập kế hoạch bữa ăn, danh sách mua sắm và nhận thông báo.

## Features
- Authentication: đăng ký & đăng nhập bằng email/password và mã OTP qua email/số điện thoại.
- Ingredient management: thêm/sửa/xóa nguyên liệu, phân loại, kiểm tra hạn sử dụng với cảnh báo.
- Recipe & meal planning: tìm công thức, gợi ý bữa ăn, tạo và quản lý kế hoạch ăn uống.
- Shopping list: tạo và cập nhật danh sách mua hàng tự động từ kế hoạch/ngoại lệ.
- Notification & history: thông báo nguyên liệu sắp hết/hết hạn và lịch sử sử dụng/đi chợ.

## Technologies
- Backend: ASP.NET Core (C#), Entity Framework Core, PostgreSQL, JWT, Swagger.
- Frontend: Flutter (mobile/web), HTTP API client, state management.
- Additional: Dockerfile cho backend, cron service kiểm tra nguyên liệu hết hạn.

## Installation
1. Clone code:
```bash
git clone <repo-url>
cd Mobile-Flutter-main
```

2. Backend
- Cài .NET SDK 8+ và PostgreSQL.
- Sửa `backend/appsettings.json`:
```json
"DefaultConnection": "Host=localhost;Port=5432;Database=fridge_db;Username=postgres;Password=YOUR_PASSWORD"
```
- Chạy migration và start API:
```bash
cd backend
dotnet tool install -g dotnet-ef
dotnet ef database update
dotnet run
```
- Kiểm tra Swagger: `http://localhost:5074/swagger`

3. Frontend
- Cài Flutter SDK (stable).
- Cài deps và chạy:
```bash
cd frontend
flutter pub get
flutter run -d chrome
```
- API base URL mặc định: `http://localhost:5074` trong `frontend/lib/core/api/api_client.dart`.

## Author
Dương Văn Việt
Phạm Đức Duy Tiến
Vương Đức Tuấn

