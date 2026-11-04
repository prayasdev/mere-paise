import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../models/category_item.dart';
import '../providers/ledger_providers.dart';

class CategoryEditDialog extends ConsumerStatefulWidget {
  final CategoryItem? existing;
  final String initialKind;

  const CategoryEditDialog({super.key, this.existing, this.initialKind = 'expense'});

  static Future<CategoryItem?> show(BuildContext context, {CategoryItem? existing, String initialKind = 'expense'}) {
    return showDialog<CategoryItem>(
      context: context,
      builder: (ctx) => CategoryEditDialog(existing: existing, initialKind: initialKind),
    );
  }

  @override
  ConsumerState<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends ConsumerState<CategoryEditDialog> {
  late final TextEditingController _nameController;
  late String _kind;
  late String _selectedIcon;
  late String _selectedColorToken;

  static const List<String> colorTokens = [
    'rust', 'ochre', 'moss', 'slate', 'plum', 'teal',
    'charcoal', 'amber', 'navy', 'sage', 'clay', 'sand',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _kind = widget.existing?.kind ?? widget.initialKind;
    _selectedIcon = widget.existing?.iconName ?? 'shopping_cart';
    _selectedColorToken = widget.existing?.colorToken ?? 'moss';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final categoriesNotifier = ref.read(categoriesProvider.notifier);

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: name,
        kind: _kind,
        iconName: _selectedIcon,
        colorToken: _selectedColorToken,
      );
      await categoriesNotifier.updateCategory(updated);
      if (mounted) Navigator.pop(context, updated);
    } else {
      final created = await categoriesNotifier.addCategory(
        name: name,
        kind: _kind,
        iconName: _selectedIcon,
        colorToken: _selectedColorToken,
      );
      if (mounted) Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing != null ? 'Edit Category' : 'New Category',
        style: AppTypography.headingMedium(context: context),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'CATEGORY NAME',
                  hintText: 'e.g. Books, Tea, Streaming',
                ),
                style: AppTypography.bodyMedium(context: context),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Kind Selector (if new)
              if (widget.existing == null) ...[
                Text('TYPE', style: AppTypography.labelGothic(context: context)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _kind = 'expense'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kind == 'expense' ? AppColors.oxblood : AppColors.elevated(context),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: _kind == 'expense' ? AppColors.oxbloodLit : AppColors.border(context),
                            ),
                          ),
                          child: Text(
                            'Expense',
                            style: AppTypography.bodySmall(
                              color: _kind == 'expense' ? AppColors.bone : AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _kind = 'income'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _kind == 'income' ? AppColors.verdigris : AppColors.elevated(context),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: _kind == 'income' ? AppColors.verdigrisLit : AppColors.border(context),
                            ),
                          ),
                          child: Text(
                            'Income',
                            style: AppTypography.bodySmall(
                              color: _kind == 'income' ? AppColors.bone : AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Color Token Selector
              Text('PALETTE COLOR', style: AppTypography.labelGothic(context: context)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colorTokens.map((token) {
                  final color = AppColors.getColorByToken(token);
                  final isSelected = _selectedColorToken == token;
                  return InkWell(
                    onTap: () => setState(() => _selectedColorToken = token),
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: isSelected ? AppColors.brass : AppColors.border(context),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Icon Selector
              Text('LINE ICON', style: AppTypography.labelGothic(context: context)),
              const SizedBox(height: 6),
              SizedBox(
                height: 140,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: CategoryIcons.icons.length,
                  itemBuilder: (context, index) {
                    final entry = CategoryIcons.icons.entries.elementAt(index);
                    final isSelected = _selectedIcon == entry.key;

                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = entry.key),
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.elevated(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isSelected ? AppColors.brass : AppColors.border(context),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          size: 18,
                          color: isSelected ? AppColors.brass : AppColors.textSecondary(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppTypography.labelGothic(context: context)),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

