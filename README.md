# Mobile-Flutter (Backend + Flutter)

Tài liệu này giúp đồng đội clone code và chạy được ngay.

## 1) Yêu cầu môi trường
- .NET SDK (khuyến nghị 8+)
- Flutter SDK (stable)
- PostgreSQL (cài đặt và chạy service)

## 2) Clone repo
```bash
git clone <repo-url>
cd Mobile-Flutter
```

## 3) Backend (ASP.NET Core + PostgreSQL)
### 3.1 Cấu hình DB
Mở file `backend/appsettings.json` và chỉnh `ConnectionStrings:DefaultConnection` nếu cần:
```json
"DefaultConnection": "Host=localhost;Port=5432;Database=fridge_db;Username=postgres;Password=123456"
```

### 3.2 Cài dotnet-ef (nếu chưa có)
```bash
dotnet tool install -g dotnet-ef
```

### 3.3 Chạy migration tạo DB
```bash
cd backend
dotnet ef database update
```

### 3.4 Chạy API
```bash
dotnet run
```
API chạy mặc định tại: `http://localhost:5074`

Swagger: `http://localhost:5074/swagger`

## 4) Frontend (Flutter)
### 4.1 Cài packages
```bash
cd frontend
flutter pub get
```

### 4.2 Chạy app
- Web:
```bash
flutter run -d chrome
```

> Base URL đang là `http://localhost:5074` trong `frontend/lib/core/api/api_client.dart`.

## 5) Ghi chú nhanh
- Nếu login/register lỗi do DB: kiểm tra PostgreSQL đang chạy và connection string đúng.
- OTP ở môi trường dev được in ra ở console backend.
- CORS đã mở cho môi trường dev để Flutter web gọi API.

## 6) Thứ tự khởi chạy nhanh
1. Start PostgreSQL
2. `cd backend` → `dotnet ef database update` → `dotnet run`
3. `cd frontend` → `flutter pub get` → `flutter run -d chrome`
