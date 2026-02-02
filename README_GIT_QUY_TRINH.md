# 📌 QUY TRÌNH GIT CHO TEAM (FLUTTER + .NET API)

## 1. Mục tiêu
- Tránh conflict khi nhiều người cùng code
- Dễ kiểm soát code, dễ review
- Không ai push nhầm lên `main`

## 2. Cấu trúc branch
```
main        → code ổn định, có thể release
develop     → code đang phát triển chung
feature/*   → branch cá nhân cho từng chức năng
```

### Quy tắc bắt buộc
- ❌ KHÔNG push trực tiếp lên `main`
- ❌ KHÔNG merge khi chưa review
- ✅ Mọi thay đổi phải thông qua Pull Request (PR)

## 3. Cấu trúc project (thực tế)
```
Mobile-Flutter/
├── frontend/          # Flutter
├── backend/           # .NET API
└── README.md
```

## 4. Hướng dẫn chạy project (sau khi clone)
### 4.1. Yêu cầu môi trường
- .NET SDK (khuyến nghị 8+)
- Flutter SDK (stable)
- PostgreSQL

### 4.2. Backend (.NET API)
1) Cấu hình DB trong `backend/appsettings.json` (nếu cần):
```json
"DefaultConnection": "Host=localhost;Port=5432;Database=fridge_db;Username=postgres;Password=123456"
```

2) Cài dotnet-ef (nếu chưa có):
```bash
dotnet tool install -g dotnet-ef
```

3) Chạy migration tạo DB:
```bash
cd backend
dotnet ef database update
```

4) Chạy API:
```bash
dotnet run
```
API chạy tại: `http://localhost:5074`  
Swagger: `http://localhost:5074/swagger`

### 4.3. Frontend (Flutter)
1) Cài packages:
```bash
cd frontend
flutter pub get
```

2) Chạy app:
```bash
flutter run -d chrome
```

> Base URL mặc định ở `frontend/lib/core/api/api_client.dart` là `http://localhost:5074`.

## 5. Quy trình làm việc (Git Bash)

### 5.1. Lấy code mới nhất
```bash
git checkout develop
git pull origin develop
```

### 5.2. Tạo branch mới
```bash
git checkout -b feature/ten-chuc-nang
```

### 5.3. Commit code
```bash
git add .
git commit -m "feat: mo ta chuc nang"
```

### 5.4. Push branch
```bash
git push origin feature/ten-chuc-nang
```

## 6. Pull Request
- Tạo PR từ `feature/*` → `develop`
- Ít nhất 1 người review
- Không có conflict

## 7. Tránh conflict
- 1 file chính → 1 người phụ trách
- File chung phải báo trước khi sửa
- Không force push

## 8. Xử lý conflict
```bash
git status
git add .
git commit -m "fix: resolve conflict"
```

## 9. Kết luận
Quy trình này giúp team làm việc ổn định, chuyên nghiệp và giảm conflict tối đa.
