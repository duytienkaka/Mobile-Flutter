import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/top_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/api_client.dart';
import 'today_service.dart';
import 'today_instruction_step_screen.dart';

class TodayInstructionScreen extends StatefulWidget {
  final TodayRecipe recipe;
  final int servings;

  const TodayInstructionScreen({
    super.key,
    required this.recipe,
    this.servings = 1,
  });

  @override
  State<TodayInstructionScreen> createState() => _TodayInstructionScreenState();
}

class _TodayInstructionScreenState extends State<TodayInstructionScreen> {
  bool _loading = false;
  List<String> _summarySteps = [];
  List<String> _detailedSteps = [];

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('Hướng dẫn nấu')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoGuideCard(context),
              const SizedBox(height: 14),
              Text(recipe.name, style: AppTextStyles.title),
              const SizedBox(height: 12),
              const SizedBox(height: 4),
              Text('Manual', style: AppTextStyles.subtitle),
              const SizedBox(height: 10),
              _buildStepsSection(recipe),
              if (_summarySteps.isNotEmpty || _detailedSteps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openFirstStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(context.tr('Bước tiếp theo')),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(context.tr('Nguyên liệu'), style: AppTextStyles.subtitle),
              const SizedBox(height: 10),
              _buildIngredientList(recipe.ingredients),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadInstructions() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });

    try {
      final res = await ApiClient.post(
        '/recipes/instructions',
        {
          'recipeName': widget.recipe.name,
          'ingredients': widget.recipe.ingredients.map((e) => e.name).toList(),
          'stepCount': 4,
        },
        auth: true,
      );
      if (res.statusCode != 200) {
        throw Exception(_extractError(res));
      }

      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        final summaryRaw = data['summarySteps'];
        final detailedRaw = data['detailedSteps'];
        final summarySteps = summaryRaw is List
            ? summaryRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
            : <String>[];
        final detailedSteps = detailedRaw is List
            ? detailedRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
            : <String>[];
        setState(() {
          _summarySteps = summarySteps;
          _detailedSteps = detailedSteps;
        });
      }
    } catch (err) {
      final errorMsg = err.toString().replaceFirst('Exception: ', '');
      if (mounted && errorMsg.isNotEmpty) {
        // ignore: use_build_context_synchronously
        showTopSnackBar(context, errorMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildStepsSection(TodayRecipe recipe) {
    final hasSteps = _summarySteps.isNotEmpty || _detailedSteps.isNotEmpty;
    if (_loading && !hasSteps) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasSteps) {
      final fallback = _buildFallbackSteps(recipe);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepsList(fallback),
        ],
      );
    }

    final steps = _summarySteps.isNotEmpty ? _summarySteps : _detailedSteps;
    return _buildStepsList(steps);
  }

  Widget _buildVideoGuideCard(BuildContext context) {
    return InkWell(
      onTap: _openVideoGuide,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.smart_display_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('Xem video hướng dẫn'),
                    style: AppTextStyles.subtitle,
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(List<String> steps) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final text = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: AppTextStyles.body),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIngredientList(List<TodayIngredient> items) {
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: AppTextStyles.body),
                  ),
                  Text(
                    _formatQuantity(item),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatQuantity(TodayIngredient item) {
    final qty = item.quantity.toStringAsFixed(
      item.quantity == item.quantity.roundToDouble() ? 0 : 1,
    );
    if (item.unit.trim().isEmpty) return qty;
    return '$qty ${item.unit}';
  }

  List<String> _buildFallbackSteps(TodayRecipe recipe) {
    final name = recipe.name.trim();
    final ingredients = recipe.ingredients.map((e) => e.name).toList();
    final main = ingredients.isNotEmpty ? ingredients.first : 'nguyên liệu';
    return [
      'Rửa và sơ chế $main. Chuẩn bị đầy đủ các nguyên liệu còn lại.',
      'Ướp hoặc trộn gia vị cơ bản để món ăn đậm đà hơn.',
      'Chế biến theo phương pháp phù hợp (xào, nấu, hấp) cho $name.',
      'Nêm nếm lại, trình bày ra đĩa và thưởng thức khi nóng.'
    ];
  }

  void _openFirstStep() {
    final detailed = _detailedSteps.isNotEmpty ? _detailedSteps : _summarySteps;
    if (detailed.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TodayInstructionStepScreen(
          recipeName: widget.recipe.name,
          servings: widget.servings,
          steps: detailed,
          initialIndex: 0,
        ),
      ),
    );
  }

  Future<void> _openVideoGuide() async {
    final recipeName = widget.recipe.name.trim();
    final query = recipeName.isEmpty
        ? 'hướng dẫn nấu ăn tại nhà chi tiết'
        : 'cách làm $recipeName công thức $recipeName hướng dẫn nấu ăn chi tiết';
    final uri = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent(query)}',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      showTopSnackBar(
        context,
        context.tr('Không thể mở video lúc này.'),
        isError: true,
      );
    }
  }

  String _extractError(dynamic res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) {
        final message = (data['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {}
    switch (res.statusCode) {
      case 401:
        return 'Vui lòng đăng nhập lại.';
      case 400:
        return 'Dữ liệu không hợp lệ.';
      default:
        return 'Không thể tải hướng dẫn.';
    }
  }
}
