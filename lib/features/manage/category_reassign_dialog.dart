import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/category_item.dart';
import '../providers/ledger_providers.dart';

class CategoryReassignDialog extends ConsumerStatefulWidget {
  final CategoryItem categoryToDelete;

  const CategoryReassignDialog({super.key, required this.categoryToDelete});

  static Future<bool?> show(BuildContext context, {required CategoryItem categoryToDelete}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CategoryReassignDialog(categoryToDelete: categoryToDelete),
    );
  }

  @override
  ConsumerState<CategoryReassignDialog> createState() => _CategoryReassignDialogState();
}

class _CategoryReassignDialogState extends ConsumerState<CategoryReassignDialog> {
  CategoryItem? _selectedReplacement;

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoriesProvider);
    final availableReplacements = allCategories
        .where((c) => c.kind == widget.categoryToDelete.kind && c.id != widget.categoryToDelete.id && !c.archived)
        .toList();

    _selectedReplacement ??= availableReplacements.isNotEmpty ? availableReplacements.first : null;

    final txns = ref.watch(transactionsProvider);
    final usageCount = txns.where((t) => t.categoryId == widget.categoryToDelete.id).length;

    return AlertDialog(
      title: Text('Delete Category', style: AppTypography.headingMedium(context: context)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.categoryToDelete.name} is used in $usageCount entry(ies). The app never silently erases financial records.',
              style: AppTypography.bodyMedium(context: context),
            ),
            const SizedBox(height: 16),
            if (availableReplacements.isNotEmpty) ...[
              Text(
                'MOVE ENTRIES TO:',
                style: AppTypography.labelGothic(context: context),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.elevated(context),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryItem>(
                    isExpanded: true,
                    dropdownColor: AppColors.elevated(context),
                    value: _selectedReplacement,
                    items: availableReplacements.map((cat) {
                      return DropdownMenuItem<CategoryItem>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              CategoryIcons.getIcon(cat.iconName),
                              size: 16,
                              color: AppColors.getColorByToken(cat.colorToken),
                            ),
                            const SizedBox(width: 8),
                            Text(cat.name, style: AppTypography.bodyMedium(context: context)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedReplacement = val),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'No alternative ${widget.categoryToDelete.kind} categories exist. You can archive this category instead to hide it from selection.',
                style: AppTypography.bodySmall(context: context),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: AppTypography.labelGothic(context: context)),
        ),
        TextButton(
          onPressed: () async {
            // Archive instead
            await ref.read(categoriesProvider.notifier).archiveCategory(widget.categoryToDelete.id, true);
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
          child: Text('Archive Instead', style: AppTypography.labelGothic(color: AppColors.brass)),
        ),
        if (availableReplacements.isNotEmpty && _selectedReplacement != null)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oxblood),
            onPressed: () async {
              await ref.read(categoriesProvider.notifier).deleteCategoryWithReassignment(
                    categoryIdToDelete: widget.categoryToDelete.id,
                    replacementCategoryId: _selectedReplacement!.id,
                    widgetRef: ref,
                  );
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Reassign & Delete'),
          ),
      ],
    );
  }
}
