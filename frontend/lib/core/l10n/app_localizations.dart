import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, String> _en = {
    'Cài đặt': 'Settings',
    'Hồ sơ người dùng': 'Profile',
    'Chỉnh sửa hồ sơ': 'Edit profile',
    'Sửa hồ sơ': 'Edit profile',
    'Đổi tên': 'Change name',
    'Tuỳ chọn': 'Preferences',
    'Chế độ tối': 'Dark mode',
    'Ngôn ngữ': 'Language',
    'Thông báo': 'Notifications',
    'Bật': 'On',
    'Tắt': 'Off',
    'Thông tin': 'Information',
    'Chính sách bảo mật': 'Privacy policy',
    'Điều khoản dịch vụ': 'Terms of service',
    'Đăng xuất': 'Sign out',
    'Bạn chắc chắn muốn đăng xuất?': 'Are you sure you want to sign out?',
    'Lưu': 'Save',
    'Đổi mật khẩu thành công': 'Password changed successfully',
    'Vui lòng điền đầy đủ thông tin': 'Please fill in all fields',
    'Mật khẩu mới không được trùng mật khẩu hiện tại':
        'New password must be different from current password',
    'Mật khẩu mới tối thiểu 6 ký tự': 'New password must be at least 6 characters',
    'Mật khẩu xác nhận không khớp': 'Password confirmation does not match',
    'Đổi mật khẩu': 'Change password',
    'Mật khẩu hiện tại': 'Current password',
    'Mật khẩu mới': 'New password',
    'Xác nhận mật khẩu mới': 'Confirm new password',
    'Cập nhật': 'Update',
    'Chọn ngôn ngữ': 'Choose language',
    'Tiếng Việt': 'Vietnamese',
    'English': 'English',
    'Đã cập nhật ngôn ngữ': 'Language updated',
    'Đã bật thông báo': 'Notifications enabled',
    'Đã tắt thông báo': 'Notifications disabled',
    'Đã bật chế độ tối': 'Dark mode enabled',
    'Đã tắt chế độ tối': 'Dark mode disabled',
    'Người dùng': 'User',
    'Đang tải...': 'Loading...',
    'Tính năng đang phát triển': 'Feature in progress',
    'Món bạn có thể nấu': 'Recipes you can make',
    'Sắp hết hạn': 'Expiring soon',
    'Đã hết hạn': 'Expired',
    'Mẹo bảo quản thực phẩm (Daily Tips)': 'Food storage tips (Daily Tips)',
    'Bảo quản rau xanh': 'Store leafy greens',
    'Rau cần độ ẩm, bọc trong khăn giấy ẩm để giữ tươi lâu.':
      'Leafy greens need moisture. Wrap with a damp paper towel to stay fresh longer.',
    'Giữ thịt tươi lâu': 'Keep meat fresh longer',
    'Chia nhỏ thịt trước khi cấp đông để dễ dùng.':
      'Portion meat before freezing for easier use.',
    'Xin chào': 'Hello',
    'Chào mừng trở lại': 'Welcome back',
    'Kho thực phẩm': 'Pantry',
    'Màn hình kho thực phẩm': 'Pantry screen',
    'Danh sách mua sắm': 'Shopping list',
    'Cần mua': 'To buy',
    'Thủ công': 'Manual',
    'Đã hoàn thành': 'Completed',
    'món': 'items',
    'Danh sách trống': 'List is empty',
    'Nhấn dấu + để thêm món thủ công vào danh sách.':
      'Tap + to add a manual item to the list.',
    'Chưa có danh sách': 'No lists yet',
    'Nhấn dấu + để tạo danh sách mua sắm.':
      'Tap + to create a shopping list.',
    'Tạo danh sách': 'Create list',
    'Tên danh sách': 'List name',
    'Chọn ngày': 'Choose date',
    'Tạo': 'Create',
    'Thêm món': 'Add item',
    'Tên món': 'Item name',
    'Số lượng': 'Quantity',
    'Đơn vị': 'Unit',
    'Thêm': 'Add',
    'Công thức': 'Recipes',
    'Hôm nay ăn gì?': "What's for today?",
    'Nguyên liệu\nđã đủ': 'Ingredients\nready',
    'Nguyên liệu\n gần đủ': 'Ingredients\nnear ready',
    'Món ăn\n dinh dưỡng': 'Nutrition\nmeals',
    'Đổi món': 'Shuffle',
    'Nấu món này': 'Cook this dish',
    'Bắt đầu nấu': 'Make this recipe',
    'Bước': 'Step',
    'Bước trước': 'Previous step',
    'Bước tiếp theo': 'Next step',
    'Hoàn tất': 'Finish',
    'Nấu món này?': 'Cook this dish?',
    'Bạn có muốn nấu món này không?': 'Do you want to cook this dish?',
    'Thêm tất cả': 'Add all',
    'Thêm vào mua sắm': 'Add to shopping',
    'Xác nhận nấu': 'Confirm cooking',
    'Huỷ': 'Cancel',
    'Nguyên liệu': 'Ingredients',
    'Nguyên liệu thiếu': 'Missing ingredients',
    'Thiếu nguyên liệu sẽ được thêm vào danh sách mua sắm.':
      'Missing ingredients will be added to your shopping list.',
    'Đã thêm nguyên liệu thiếu vào danh sách mua sắm.':
      'Missing ingredients were added to your shopping list.',
    'Hướng dẫn nấu': 'Cooking instructions',
    'Hướng dẫn nấu sẽ được cập nhật sau.':
      'Cooking instructions will be updated soon.',
    'Kế hoạch bữa ăn': 'Meal plan',
    'Món gợi ý': 'Suggested dish',
    'Được nhiều người nấu': 'Popular with home cooks',
    'Dễ': 'Easy',
    'Màn hình thông báo': 'Notification screen',
    'Đã thêm kế hoạch.': 'Plan added.',
    'Đã lưu lịch sử nấu ăn.': 'Cooking history saved.',
    'Xoá kế hoạch': 'Delete plan',
    'Bạn chắc chắn muốn xoá món này?': 'Are you sure you want to delete this dish?',
    'Xoá': 'Delete',
    'Chưa có kế hoạch': 'No plans yet',
    'Thêm món ăn cho ngày này để bắt đầu.': 'Add dishes for this day to get started.',
    'Lịch kế hoạch': 'Meal schedule',
    'Theo ngày': 'By day',
    'Theo tuần': 'By week',
    'suất': 'servings',
    'Vui lòng nhập tên món ăn.': 'Please enter the dish name.',
    'Sửa kế hoạch': 'Edit plan',
    'Thêm kế hoạch': 'Add plan',
    'Ngày': 'Date',
    'Bữa ăn': 'Meal',
    'Tên món ăn': 'Dish name',
    'Ví dụ: Cơm gà': 'Example: Chicken rice',
    'Số suất': 'Servings',
    'Ghi chú': 'Notes',
    'Ghi chú thêm nếu cần': 'Add a note if needed',
    'Lưu thay đổi': 'Save changes',
    'Kế hoạch': 'Planner',
    'Đăng nhập': 'Sign in',
    'Đăng ký': 'Sign up',
    'Chào mừng bạn quay trở lại!': 'Welcome back!',
    'Tạo tài khoản mới để bắt đầu': 'Create a new account to get started',
    'Email': 'Email',
    'Số điện thoại': 'Phone number',
    'Password': 'Password',
    'Họ và tên': 'Full name',
    'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật':
        'I agree to the terms of service and privacy policy',
    'Đã có tài khoản? Đăng nhập ngay': 'Already have an account? Sign in',
    'Chưa có tài khoản? Đăng ký ngay': "Don't have an account? Sign up",
    'Cần điền đầy đủ thông tin': 'Please fill in all fields',
    'Số điện thoại không đúng định dạng': 'Invalid phone number format',
    'Tài khoản hoặc mật khẩu không đúng.': 'Incorrect email or password.',
    'Xác thực OTP': 'OTP Verification',
    'Mã xác thực đã được gửi đến số điện thoại':
        'Verification code has been sent to',
    'Mã hết hạn sau': 'Code expires in',
    'Xác nhận': 'Confirm',
    'Không nhận được mã? Liên hệ hỗ trợ':
        "Didn't receive the code? Contact support",
    'Quay lại': 'Back',
    'Nhập họ và tên': 'Enter full name',
    'Tên không được để trống': 'Name cannot be empty',
    'Đã cập nhật hồ sơ': 'Profile updated',
    'Tìm kiếm': 'Search',
    'Vui lòng cấp quyền thông báo trong cài đặt':
      'Please enable notifications permission in settings',
    'Bạn đã từ chối quyền thông báo': 'You denied notifications permission',
    'Chụp ảnh': 'Take photo',
    'Chọn từ thư viện': 'Choose from library',
    'Dùng ảnh này?': 'Use this photo?',
    'Không': 'Cancel',
    'Sử dụng': 'Use',
    'Đã cập nhật ảnh đại diện': 'Avatar updated',
  };

  String t(String key) {
    if (locale.languageCode == 'en') {
      return _en[key] ?? key;
    }
    return key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationX on BuildContext {
  String tr(String key) => AppLocalizations.of(this).t(key);
}
