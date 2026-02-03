import 'package:flutter/material.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final sections = isEn ? _privacyEn : _privacyVi;

    return _InfoScaffold(
      title: context.tr('Chính sách bảo mật'),
      sections: sections,
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final sections = isEn ? _termsEn : _termsVi;

    return _InfoScaffold(
      title: context.tr('Điều khoản dịch vụ'),
      sections: sections,
    );
  }
}

class _InfoScaffold extends StatelessWidget {
  final String title;
  final List<_InfoSection> sections;

  const _InfoScaffold({
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final footer = isEn ? _footerEn : _footerVi;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              Text(section.title, style: AppTextStyles.subtitle),
              const SizedBox(height: 6),
              Text(section.body, style: AppTextStyles.body),
              const SizedBox(height: 16),
            ],
            Text(footer, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _InfoSection {
  final String title;
  final String body;

  const _InfoSection(this.title, this.body);
}

const _privacyVi = [
  _InfoSection(
    'Giới thiệu',
    'Chính sách bảo mật này mô tả cách chúng tôi thu thập, sử dụng và bảo vệ thông tin khi bạn sử dụng ứng dụng. Bằng việc sử dụng ứng dụng, bạn đồng ý với các thực hành được mô tả tại đây.',
  ),
  _InfoSection(
    'Thông tin chúng tôi thu thập',
    'Chúng tôi có thể thu thập: (1) thông tin tài khoản như họ tên, email, số điện thoại và hình đại diện; (2) dữ liệu sử dụng cơ bản như thao tác trong ứng dụng, thời gian truy cập, lựa chọn ngôn ngữ; (3) thông tin thiết bị ở mức tối thiểu để hỗ trợ đăng nhập, đồng bộ và xử lý lỗi.',
  ),
  _InfoSection(
    'Thông tin bạn cung cấp',
    'Khi bạn tạo tài khoản hoặc cập nhật hồ sơ, bạn tự nguyện cung cấp thông tin cá nhân. Bạn có thể chỉnh sửa hoặc xóa một số thông tin trực tiếp trong ứng dụng.',
  ),
  _InfoSection(
    'Cách chúng tôi sử dụng dữ liệu',
    'Chúng tôi dùng dữ liệu để xác thực người dùng, đồng bộ dữ liệu đa thiết bị, cá nhân hóa trải nghiệm, hiển thị nội dung phù hợp và hỗ trợ khách hàng. Dữ liệu cũng có thể được dùng để cải thiện chất lượng dịch vụ và bảo trì hệ thống.',
  ),
  _InfoSection(
    'Cơ sở pháp lý',
    'Chúng tôi xử lý dữ liệu dựa trên sự đồng ý của bạn, nhu cầu thực hiện hợp đồng dịch vụ, và các nghĩa vụ pháp lý liên quan (nếu có).',
  ),
  _InfoSection(
    'Chia sẻ dữ liệu',
    'Chúng tôi không bán dữ liệu cá nhân. Dữ liệu chỉ được chia sẻ với nhà cung cấp dịch vụ cần thiết để vận hành (ví dụ: lưu trữ, gửi thông báo) hoặc theo yêu cầu pháp luật. Các bên này phải tuân thủ nghĩa vụ bảo mật tương đương.',
  ),
  _InfoSection(
    'Lưu trữ và bảo mật',
    'Chúng tôi áp dụng các biện pháp bảo mật hợp lý để bảo vệ dữ liệu khỏi truy cập trái phép, mất mát hoặc thay đổi. Tuy nhiên, không có hệ thống nào an toàn tuyệt đối; vì vậy chúng tôi không thể đảm bảo an toàn 100%.',
  ),
  _InfoSection(
    'Thời gian lưu trữ',
    'Chúng tôi lưu trữ dữ liệu trong thời gian cần thiết để cung cấp dịch vụ hoặc theo yêu cầu pháp luật. Khi bạn yêu cầu xóa tài khoản, dữ liệu sẽ được xử lý theo quy định và khả năng kỹ thuật.',
  ),
  _InfoSection(
    'Quyền của bạn',
    'Bạn có quyền truy cập, chỉnh sửa hoặc xóa thông tin cá nhân; rút lại sự đồng ý; yêu cầu hạn chế hoặc phản đối việc xử lý dữ liệu trong một số trường hợp.',
  ),
  _InfoSection(
    'Thông báo và thay đổi',
    'Chúng tôi có thể cập nhật chính sách bảo mật theo thời gian. Mọi thay đổi quan trọng sẽ được thông báo trong ứng dụng hoặc theo cách phù hợp.',
  ),
  _InfoSection(
    'Liên hệ',
    'Nếu bạn có câu hỏi về chính sách bảo mật, vui lòng liên hệ bộ phận hỗ trợ để được giải đáp.',
  ),
];

const _privacyEn = [
  _InfoSection(
    'Introduction',
    'This Privacy Policy describes how we collect, use, and protect information when you use the app. By using the app, you agree to the practices described here.',
  ),
  _InfoSection(
    'Information we collect',
    'We may collect: (1) account details such as name, email, phone number, and avatar; (2) basic usage data such as in-app actions, access time, and language selection; (3) minimal device information to support sign-in, syncing, and troubleshooting.',
  ),
  _InfoSection(
    'Information you provide',
    'When you create an account or update your profile, you voluntarily provide personal data. You can edit or remove certain information within the app.',
  ),
  _InfoSection(
    'How we use data',
    'We use data to authenticate users, sync data across devices, personalize the experience, display relevant content, and provide customer support. We also use data to improve service quality and maintain system reliability.',
  ),
  _InfoSection(
    'Legal basis',
    'We process data based on your consent, the need to perform our service contract, and any applicable legal obligations.',
  ),
  _InfoSection(
    'Data sharing',
    'We do not sell personal data. Data is shared only with service providers required to operate the app (e.g., storage, notifications) or as required by law. These providers must follow equivalent security obligations.',
  ),
  _InfoSection(
    'Storage and security',
    'We apply reasonable security measures to protect data from unauthorized access, loss, or alteration. However, no system is fully secure, and we cannot guarantee absolute security.',
  ),
  _InfoSection(
    'Retention',
    'We retain data as long as necessary to provide the service or comply with legal requirements. When you request account deletion, data will be handled according to policy and technical feasibility.',
  ),
  _InfoSection(
    'Your rights',
    'You have rights to access, correct, or delete personal data; withdraw consent; and request restriction or objection in certain cases.',
  ),
  _InfoSection(
    'Updates',
    'We may update this Privacy Policy over time. Material changes will be communicated in-app or through appropriate channels.',
  ),
  _InfoSection(
    'Contact',
    'If you have questions about this Privacy Policy, please contact support for assistance.',
  ),
];

const _termsVi = [
  _InfoSection(
    'Chấp nhận điều khoản',
    'Bằng việc truy cập và sử dụng ứng dụng, bạn xác nhận đã đọc, hiểu và đồng ý với các điều khoản dịch vụ này.',
  ),
  _InfoSection(
    'Điều kiện sử dụng',
    'Bạn cần cung cấp thông tin chính xác khi đăng ký và duy trì tính cập nhật của hồ sơ để đảm bảo trải nghiệm tốt nhất.',
  ),
  _InfoSection(
    'Tài khoản và bảo mật',
    'Bạn chịu trách nhiệm bảo mật thông tin đăng nhập và mọi hoạt động phát sinh trên tài khoản. Nếu phát hiện truy cập trái phép, bạn cần thông báo ngay cho chúng tôi.',
  ),
  _InfoSection(
    'Hành vi bị cấm',
    'Bạn không được sử dụng ứng dụng để thực hiện hành vi trái pháp luật, xâm phạm quyền của người khác, phát tán nội dung độc hại hoặc can thiệp vào hệ thống.',
  ),
  _InfoSection(
    'Nội dung và dữ liệu',
    'Bạn chịu trách nhiệm đối với nội dung do mình cung cấp. Chúng tôi có quyền gỡ bỏ nội dung vi phạm mà không cần báo trước.',
  ),
  _InfoSection(
    'Tính năng và thay đổi',
    'Chúng tôi có thể cập nhật, điều chỉnh hoặc ngừng một phần tính năng để cải thiện dịch vụ. Các thay đổi quan trọng sẽ được thông báo.',
  ),
  _InfoSection(
    'Dịch vụ bên thứ ba',
    'Một số tính năng có thể liên quan đến dịch vụ của bên thứ ba. Việc sử dụng các dịch vụ đó có thể chịu sự điều chỉnh của điều khoản riêng.',
  ),
  _InfoSection(
    'Giới hạn trách nhiệm',
    'Chúng tôi không chịu trách nhiệm cho thiệt hại gián tiếp, ngẫu nhiên hoặc hệ quả phát sinh từ việc sử dụng hoặc không thể sử dụng ứng dụng.',
  ),
  _InfoSection(
    'Chấm dứt sử dụng',
    'Chúng tôi có thể tạm ngưng hoặc chấm dứt quyền truy cập nếu bạn vi phạm điều khoản. Bạn có thể ngừng sử dụng và yêu cầu xóa tài khoản bất kỳ lúc nào.',
  ),
  _InfoSection(
    'Luật áp dụng',
    'Các điều khoản này được điều chỉnh bởi pháp luật hiện hành. Mọi tranh chấp sẽ được giải quyết theo quy định pháp luật.',
  ),
  _InfoSection(
    'Cập nhật điều khoản',
    'Chúng tôi có thể cập nhật điều khoản theo thời gian. Việc tiếp tục sử dụng ứng dụng sau khi cập nhật đồng nghĩa với việc chấp nhận các thay đổi.',
  ),
];

const _termsEn = [
  _InfoSection(
    'Acceptance of terms',
    'By accessing and using the app, you confirm that you have read, understood, and agreed to these Terms of Service.',
  ),
  _InfoSection(
    'Eligibility and information',
    'You must provide accurate information during registration and keep your profile updated for the best experience.',
  ),
  _InfoSection(
    'Account and security',
    'You are responsible for protecting your login credentials and all activities under your account. Notify us immediately if you suspect unauthorized access.',
  ),
  _InfoSection(
    'Prohibited behavior',
    'You must not use the app for unlawful purposes, violate others’ rights, distribute harmful content, or interfere with system operations.',
  ),
  _InfoSection(
    'User content',
    'You are responsible for content you submit. We may remove content that violates policies without prior notice.',
  ),
  _InfoSection(
    'Features and changes',
    'We may update, modify, or discontinue parts of the service to improve quality. Material changes will be communicated.',
  ),
  _InfoSection(
    'Third-party services',
    'Some features may rely on third-party services. Their separate terms may apply to your use of those services.',
  ),
  _InfoSection(
    'Limitation of liability',
    'We are not liable for indirect, incidental, or consequential damages arising from use or inability to use the app.',
  ),
  _InfoSection(
    'Termination',
    'We may suspend or terminate access if you breach these terms. You may stop using the app and request account deletion at any time.',
  ),
  _InfoSection(
    'Governing law',
    'These terms are governed by applicable law. Any disputes will be resolved in accordance with legal procedures.',
  ),
  _InfoSection(
    'Updates to terms',
    'We may update these terms over time. Continued use after updates means you accept the changes.',
  ),
];

const _footerVi = 'Cập nhật lần cuối: 3/2/2026';
const _footerEn = 'Last updated: February 3, 2026';
