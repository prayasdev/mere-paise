import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/category_item.dart';
import '../providers/ledger_providers.dart';
import 'category_edit_dialog.dart';
import 'category_reassign_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _selectedCategoryKind = 'expense'; // 'expense' or 'income'
  bool _isReorderMode = false;
  bool _showArchivedCategories = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final allCategories = ref.watch(categoriesProvider);

    final expenseCategories = allCategories.where((c) => c.kind == 'expense').toList();
    final incomeCategories = allCategories.where((c) => c.kind == 'income').toList();

    final activeFilteredCategories = allCategories
        .where((c) => c.kind == _selectedCategoryKind && !c.archived)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final archivedFilteredCategories = allCategories
        .where((c) => c.kind == _selectedCategoryKind && c.archived)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CATEGORIES', style: AppTypography.headingLarge(context: context)),
            Text(
              'LEDGER CLASSIFICATIONS & ORDERING',
              style: AppTypography.labelGothic(context: context, fontSize: 10),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Selector: Expense vs Income
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryKind = 'expense';
                        _isReorderMode = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedCategoryKind == 'expense'
                            ? AppColors.elevated(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: _selectedCategoryKind == 'expense'
                              ? AppColors.brass
                              : AppColors.border(context),
                          width: _selectedCategoryKind == 'expense' ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.oxblood,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EXPENSE (${expenseCategories.length})',
                            style: AppTypography.labelGothic(
                              color: _selectedCategoryKind == 'expense'
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryKind = 'income';
                        _isReorderMode = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedCategoryKind == 'income'
                            ? AppColors.elevated(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: _selectedCategoryKind == 'income'
                              ? AppColors.brass
                              : AppColors.border(context),
                          width: _selectedCategoryKind == 'income' ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.verdigris,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'INCOME (${incomeCategories.length})',
                            style: AppTypography.labelGothic(
                              color: _selectedCategoryKind == 'income'
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions row: "+ Add Category" and "Reorder mode"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isReorderMode ? 'Drag categories to reorder:' : 'Active Categories (${activeFilteredCategories.length}):',
                  style: AppTypography.bodyMedium(context: context),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () {
                        setState(() => _isReorderMode = !_isReorderMode);
                      },
                      icon: Icon(
                        _isReorderMode ? Icons.done : Icons.sort,
                        size: 16,
                        color: AppColors.brass,
                      ),
                      label: Text(
                        _isReorderMode ? 'Done' : 'Reorder',
                        style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brass,
                        foregroundColor: isDark ? AppColors.obsidian : AppColors.vellumInk,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        CategoryEditDialog.show(context, initialKind: _selectedCategoryKind);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'New',
                        style: AppTypography.labelGothic(
                          color: isDark ? AppColors.obsidian : AppColors.vellumInk,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Category list
            if (activeFilteredCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No active $_selectedCategoryKind categories.',
                    style: AppTypography.bodyMedium(context: context),
                  ),
                ),
              )
            else if (_isReorderMode)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeFilteredCategories.length,
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  ref.read(categoriesProvider.notifier).reorder(
                        _selectedCategoryKind,
                        oldIndex,
                        newIndex,
                      );
                },
                itemBuilder: (ctx, idx) {
                  final cat = activeFilteredCategories[idx];
                  return _buildReorderTile(cat, context);
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeFilteredCategories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (ctx, idx) {
                  final cat = activeFilteredCategories[idx];
                  return _buildCategoryItemRow(cat, context, ref);
                },
              ),

            // Collapsible Archived Categories
            if (archivedFilteredCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  setState(() => _showArchivedCategories = !_showArchivedCategories);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Archived Categories (${archivedFilteredCategories.length})',
                        style: AppTypography.bodyMedium(color: AppColors.textTertiary(context)),
                      ),
                      Icon(
                        _showArchivedCategories ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.textSecondary(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showArchivedCategories)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: archivedFilteredCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (ctx, idx) {
                    final cat = archivedFilteredCategories[idx];
                    return _buildCategoryItemRow(cat, context, ref, isArchived: true);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItemRow(
    CategoryItem cat,
    BuildContext context,
    WidgetRef ref, {
    bool isArchived = false,
  }) {
    final color = AppColors.getColorByToken(cat.colorToken);

    return Container(
      key: ValueKey(cat.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isArchived ? AppColors.surface(context).withValues(alpha: 0.5) : AppColors.elevated(context),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isArchived ? AppColors.borderSubtle(context) : AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(
              CategoryIcons.getIcon(cat.iconName),
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: AppTypography.bodyLarge(
                    color: isArchived ? AppColors.textTertiary(context) : AppColors.textPrimary(context),
                  ),
                ),
                if (isArchived)
                  Text(
                    'Archived (hidden from quick add)',
                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary(context),
            tooltip: 'Edit',
            onPressed: () => CategoryEditDialog.show(context, existing: cat),
          ),
          IconButton(
            icon: Icon(
              cat.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
              size: 18,
            ),
            color: AppColors.textSecondary(context),
            tooltip: cat.archived ? 'Unarchive' : 'Archive',
            onPressed: () {
              ref.read(categoriesProvider.notifier).archiveCategory(cat.id, !cat.archived);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.expense(context)),
            tooltip: 'Delete',
            onPressed: () {
              CategoryReassignDialog.show(context, categoryToDelete: cat);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReorderTile(CategoryItem cat, BuildContext context) {
    final color = AppColors.getColorByToken(cat.colorToken);

    return Container(
      key: ValueKey(cat.id),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(CategoryIcons.getIcon(cat.iconName), size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cat.name,
              style: AppTypography.bodyLarge(context: context),
            ),
          ),
          Icon(Icons.drag_handle, size: 20, color: AppColors.textSecondary(context)),
        ],
      ),
    );
  }
}

