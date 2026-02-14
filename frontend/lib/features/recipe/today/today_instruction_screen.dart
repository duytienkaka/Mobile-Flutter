import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/api_client.dart';
import 'today_service.dart';
import 'today_instruction_step_screen.dart';

class TodayInstructionScreen extends StatefulWidget {
  final TodayRecipe recipe;

  const TodayInstructionScreen({super.key, required this.recipe});

  @override
  State<TodayInstructionScreen> createState() => _TodayInstructionScreenState();
}

class _TodayInstructionScreenState extends State<TodayInstructionScreen> {
  bool _loading = false;
  String? _error;
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
              _buildDecorBanner(context),
              const SizedBox(height: 16),
              Text(recipe.name, style: AppTextStyles.title),
              const SizedBox(height: 12),
              _buildToolsCard(),
              const SizedBox(height: 16),
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
      _error = null;
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
      setState(() => _error = err.toString());
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
      final message = _error?.replaceFirst('Exception: ', '');
      final fallback = _buildFallbackSteps(recipe);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message, style: AppTextStyles.caption),
            const SizedBox(height: 8),
          ],
          _buildStepsList(fallback),
        ],
      );
    }

    final steps = _summarySteps.isNotEmpty ? _summarySteps : _detailedSteps;
    return _buildStepsList(steps);
  }

  Widget _buildDecorBanner(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.local_dining,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('Hướng dẫn nấu'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handyman_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bếp, dao, thớt, chảo, thìa',
              style: AppTextStyles.caption,
            ),
          ),
        ],
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
          steps: detailed,
          initialIndex: 0,
        ),
      ),
    );
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
