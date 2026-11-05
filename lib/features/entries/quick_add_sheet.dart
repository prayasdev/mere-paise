import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gothic_divider.dart';
import '../models/category_item.dart';
import '../models/tag_item.dart';
import '../models/transaction_entry.dart';
import '../providers/ledger_providers.dart';
import '../manage/category_edit_dialog.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  final TransactionEntry? initialEntry; // If editing an existing entry

  const QuickAddSheet({super.key, this.initialEntry});

  static Future<void> show(BuildContext context, {TransactionEntry? initialEntry}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickAddSheet(initialEntry: initialEntry),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late String _type; // 'expense' or 'income'
  String _amountBuffer = '';
  CategoryItem? _selectedCategory;
  DateTime _occurredAt = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _selectedTagNames = [];
  bool _isDetailsExpanded = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _type = entry.type;
      _amountBuffer = CurrencyFormatter.paiseToInputString(entry.amountPaise);
      _occurredAt = entry.occurredAt;
      _noteController.text = entry.note;
      _isDetailsExpanded = entry.note.isNotEmpty || entry.tagIds.isNotEmpty;
    } else {
      _type = 'expense';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory == null) {
      final categories = ref.read(categoriesProvider);
      final repo = ref.read(ledgerRepositoryProvider);

      if (widget.initialEntry != null) {
        _selectedCategory = categories.cast<CategoryItem?>().firstWhere(
          (c) => c?.id == widget.initialEntry!.categoryId,
          orElse: () => null,
        );
        // Load tags
        final allTags = ref.read(tagsProvider);
        for (final tagId in widget.initialEntry!.tagIds) {
          final found = allTags.cast<TagItem?>().firstWhere((t) => t?.id == tagId, orElse: () => null);
          if (found != null && !_selectedTagNames.contains(found.name)) {
            _selectedTagNames.add(found.name);
          }
        }
      }

      if (_selectedCategory == null) {
        final lastCatId = repo.getLastUsedCategory(_type);
        if (lastCatId != null) {
          _selectedCategory = categories.cast<CategoryItem?>().firstWhere(
            (c) => c != null && c.id == lastCatId && c.kind == _type && !c.archived,
            orElse: () => null,
          );
        }
        _selectedCategory ??= categories.cast<CategoryItem?>().firstWhere(
          (c) => c != null && c.kind == _type && !c.archived,
          orElse: () => null,
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    setState(() {
      if (value == 'BACK') {
        if (_amountBuffer.isNotEmpty) {
          _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1);
        }
      } else if (value == '.') {
        if (!_amountBuffer.contains('.')) {
          if (_amountBuffer.isEmpty) {
            _amountBuffer = '0.';
          } else {
            _amountBuffer += '.';
          }
        }
      } else {
        // Enforce 2 decimal places max
        if (_amountBuffer.contains('.')) {
          final decimals = _amountBuffer.split('.')[1];
          if (decimals.length >= 2) return;
        }
        // Max 9 digits
        if (_amountBuffer.replaceAll('.', '').length >= 9) return;
        _amountBuffer += value;
      }
    });
  }

  void _switchType(String newType) {
    if (_type == newType) return;
    setState(() {
      _errorMessage = null;
      _type = newType;
      final categories = ref.read(categoriesProvider);
      final repo = ref.read(ledgerRepositoryProvider);
      final lastCatId = repo.getLastUsedCategory(newType);

      _selectedCategory = categories.cast<CategoryItem?>().firstWhere(
        (c) => c != null && c.id == lastCatId && c.kind == newType && !c.archived,
        orElse: () => categories.cast<CategoryItem?>().firstWhere(
          (c) => c != null && c.kind == newType && !c.archived,
          orElse: () => null,
        ),
      );
    });
  }

  Future<void> _handleSave({bool addAnother = false}) async {
    final paise = CurrencyFormatter.parseToPaise(_amountBuffer);
    if (paise <= 0) {
      setState(() {
        _errorMessage = 'Please enter an amount greater than zero.';
      });
      LedgerHaptics.doubleTick();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a category.';
      });
      LedgerHaptics.doubleTick();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    final repo = ref.read(ledgerRepositoryProvider);
    final tagsNotifier = ref.read(tagsProvider.notifier);

    // Duplicate check for new entries
    if (widget.initialEntry == null) {
      final isDup = repo.isDuplicateEntry(
        amountPaise: paise,
        categoryId: _selectedCategory!.id,
        occurredAt: _occurredAt,
      );
      if (isDup) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Identical Entry Detected', style: AppTypography.headingMedium()),
            content: Text(
              'An identical $_type entry for ${CurrencyFormatter.formatPaise(paise)} in ${_selectedCategory!.name} was recorded in the last minute. Save anyway?',
              style: AppTypography.bodyMedium(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: AppTypography.labelGothic(color: AppColors.ash)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    // Process tags
    final tagIds = <String>[];
    for (final tagName in _selectedTagNames) {
      final tagItem = await tagsNotifier.getOrCreateTag(tagName);
      tagIds.add(tagItem.id);
    }

    final txnNotifier = ref.read(transactionsProvider.notifier);
    if (widget.initialEntry != null) {
      final updated = widget.initialEntry!.copyWith(
        type: _type,
        amountPaise: paise,
        categoryId: _selectedCategory!.id,
        tagIds: tagIds,
        note: _noteController.text.trim(),
        occurredAt: _occurredAt,
      );
      await txnNotifier.updateEntry(updated);
    } else {
      await txnNotifier.createEntry(
        type: _type,
        amountPaise: paise,
        categoryId: _selectedCategory!.id,
        tagIds: tagIds,
        note: _noteController.text.trim(),
        occurredAt: _occurredAt,
      );
    }

    LedgerHaptics.tick();

    if (addAnother && mounted) {
      setState(() {
        _amountBuffer = '';
        _noteController.clear();
        _selectedTagNames.clear();
        _occurredAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved. Ready for next.')),
      );
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteEntry() async {
    if (widget.initialEntry == null) return;
    final entry = widget.initialEntry!;
    final amountText = CurrencyFormatter.formatPaise(entry.amountPaise);
    final catName = _selectedCategory?.name ?? 'entry';
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border(context)),
        ),
        title: Text('Delete Entry?', style: AppTypography.headingMedium(context: context)),
        content: Text(
          'Are you sure you want to delete this $amountText $catName transaction? You can undo this action within 6 seconds.',
          style: AppTypography.bodyMedium(context: context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTypography.labelGothic(color: AppColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.oxblood,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      LedgerHaptics.doubleTick();
      final txnNotifier = ref.read(transactionsProvider.notifier);
      navigator.pop();

      final deleted = await txnNotifier.softDelete(entry.id);
      if (deleted != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Entry removed ($amountText)'),
            duration: const Duration(seconds: 5),
            persist: false,
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.brass,
              onPressed: () {
                txnNotifier.restore(entry.id);
              },
            ),
          ),
        );
      }
    }
  }

  void _addTag(String rawTag) {
    final clean = rawTag.trim().replaceAll('#', '').toLowerCase();
    if (clean.isNotEmpty && !_selectedTagNames.contains(clean)) {
      setState(() {
        _selectedTagNames.add(clean);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isExpense = _type == 'expense';
    final accentColor = isExpense ? AppColors.expense(context) : AppColors.income(context);
    final headerTint = isExpense ? AppColors.oxblood : AppColors.verdigris;

    final allCategories = ref.watch(categoriesProvider);
    final visibleCategories = allCategories
        .where((c) => c.kind == _type && !c.archived)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final displayAmount = _amountBuffer.isEmpty ? '0' : _amountBuffer;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
          left: BorderSide(color: AppColors.border(context), width: 1),
          right: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tint bar
              Container(height: 3, color: headerTint),

              // Header bar with Title, Delete (if editing), and Close
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialEntry != null ? 'EDIT ENTRY' : 'NEW ENTRY',
                      style: AppTypography.labelGothic(context: context, fontSize: 11),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.initialEntry != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.oxbloodLit, size: 20),
                            tooltip: 'Delete Entry',
                            visualDensity: VisualDensity.compact,
                            onPressed: _confirmDeleteEntry,
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textSecondary(context), size: 20),
                          tooltip: 'Close',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Prominent Error Banner on top (above keypad & inputs)
              if (_errorMessage != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.oxblood.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.oxbloodLit, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppColors.oxbloodLit),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall(color: AppColors.oxbloodLit).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _errorMessage = null),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, size: 16, color: AppColors.oxbloodLit),
                        ),
                      ),
                    ],
                  ),
                ),

              // Segmented Out / In Switch
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton(
                        context: context,
                        label: 'SPENT',
                        isSelected: isExpense,
                        activeColor: AppColors.oxblood,
                        onTap: () => _switchType('expense'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSegmentButton(
                        context: context,
                        label: 'RECEIVED',
                        isSelected: !isExpense,
                        activeColor: AppColors.verdigris,
                        onTap: () => _switchType('income'),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: isDark ? AppColors.obsidian : AppColors.bg(context),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isExpense ? '− ₹ ' : '+ ₹ ',
                      style: AppTypography.amountLarge(color: accentColor),
                    ),
                    Expanded(
                      child: Text(
                        displayAmount,
                        style: AppTypography.amountKeypad(context: context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_amountBuffer.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary(context), size: 20),
                        onPressed: () => setState(() {
                          _amountBuffer = '';
                          _errorMessage = null;
                        }),
                      ),
                  ],
                ),
              ),

              const GothicDivider(padding: EdgeInsets.zero),

              // Categories Chips Horizontal Row
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: visibleCategories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == visibleCategories.length) {
                      // "+ New" chip
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.border(context)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () async {
                          final newCat = await CategoryEditDialog.show(context, initialKind: _type);
                          if (newCat != null && mounted) {
                            setState(() => _selectedCategory = newCat);
                          }
                        },
                        icon: const Icon(Icons.add, size: 14, color: AppColors.brass),
                        label: Text('New', style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 11)),
                      );
                    }

                    final cat = visibleCategories[index];
                    final isSelected = _selectedCategory?.id == cat.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _errorMessage = null;
                        });
                        LedgerHaptics.tick();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.elevated(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.brass : AppColors.border(context),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.brass.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CategoryIcons.getIcon(cat.iconName),
                              size: 14,
                              color: isSelected ? AppColors.brass : AppColors.getColorByToken(cat.colorToken),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: AppTypography.bodySmall(
                                color: isSelected ? AppColors.brass : AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Prominent Quick Date Selector
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: Row(
                  children: [
                    _buildDateOption(
                      context: context,
                      label: 'TODAY',
                      isSelected: _isToday(_occurredAt),
                      onTap: () {
                        LedgerHaptics.tick();
                        setState(() {
                          final now = DateTime.now();
                          _occurredAt = DateTime(now.year, now.month, now.day, _occurredAt.hour, _occurredAt.minute);
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    _buildDateOption(
                      context: context,
                      label: 'YESTERDAY',
                      isSelected: _isYesterday(_occurredAt),
                      onTap: () {
                        LedgerHaptics.tick();
                        setState(() {
                          final yday = DateTime.now().subtract(const Duration(days: 1));
                          _occurredAt = DateTime(yday.year, yday.month, yday.day, _occurredAt.hour, _occurredAt.minute);
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildDateOption(
                        context: context,
                        label: _isToday(_occurredAt) || _isYesterday(_occurredAt)
                            ? 'CALENDAR'
                            : LedgerDateUtils.formatShortDate(_occurredAt).toUpperCase(),
                        icon: Icons.calendar_month_outlined,
                        isSelected: !_isToday(_occurredAt) && !_isYesterday(_occurredAt),
                        onTap: () async {
                          LedgerHaptics.tick();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _occurredAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _occurredAt = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                _occurredAt.hour,
                                _occurredAt.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Expandable Note & Tags drawer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
                      icon: Icon(
                        _isDetailsExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: AppColors.textSecondary(context),
                      ),
                      label: Text(
                        _isDetailsExpanded ? 'Hide Note & Tags' : '+ Add Note & Tags',
                        style: AppTypography.bodySmall(context: context),
                      ),
                    ),
                  ],
                ),
              ),

              // Smooth Expandable Note & Tags drawer
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: _isDetailsExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Add note (e.g. Chai with friends)',
                                isDense: true,
                              ),
                              style: AppTypography.bodyMedium(context: context),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _tagController,
                                    decoration: InputDecoration(
                                      hintText: 'Add tag (e.g. #trip-goa)',
                                      isDense: true,
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add, size: 16, color: AppColors.brass),
                                        onPressed: () => _addTag(_tagController.text),
                                      ),
                                    ),
                                    onSubmitted: _addTag,
                                    style: AppTypography.bodyMedium(context: context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedTagNames.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _selectedTagNames.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevated(context),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border(context)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('#$tag', style: AppTypography.bodySmall(color: AppColors.brass)),
                                        const SizedBox(width: 5),
                                        InkWell(
                                          onTap: () => setState(() => _selectedTagNames.remove(tag)),
                                          child: Icon(Icons.close, size: 13, color: AppColors.textSecondary(context)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 6),

              // Square Gothic Keypad
              _buildKeypad(context),

              const SizedBox(height: 10),

              // Save / Update / Delete Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: widget.initialEntry != null
                    ? Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.oxbloodLit.withValues(alpha: 0.7), width: 1.2),
                                foregroundColor: AppColors.oxbloodLit,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _confirmDeleteEntry,
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.oxbloodLit),
                              label: Text(
                                'DELETE',
                                style: AppTypography.labelGothic(color: AppColors.oxbloodLit, fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brass,
                                foregroundColor: isDark ? AppColors.obsidian : AppColors.vellumInk,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () => _handleSave(addAnother: false),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'UPDATE ENTRY',
                                    style: AppTypography.labelGothic(
                                      color: isDark ? AppColors.obsidian : AppColors.vellumInk,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onLongPress: () => _handleSave(addAnother: true),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brass,
                                  foregroundColor: isDark ? AppColors.obsidian : AppColors.vellumInk,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: () => _handleSave(addAnother: false),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SAVE ENTRY',
                                      style: AppTypography.labelGothic(
                                        color: isDark ? AppColors.obsidian : AppColors.vellumInk,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.elevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelGothic(
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isYesterday(DateTime dt) {
    final yday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yday.year && dt.month == yday.month && dt.day == yday.day;
  }

  Widget _buildDateOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brass : AppColors.elevated(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brass : AppColors.border(context),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brass.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? (isDark ? AppColors.obsidian : AppColors.vellumInk) : AppColors.brass,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTypography.labelGothic(
                color: isSelected
                    ? (isDark ? AppColors.obsidian : AppColors.vellumInk)
                    : AppColors.textPrimary(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'BACK'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        LedgerHaptics.tick();
                        _onKeypadTap(key);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.elevated(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context), width: 1),
                        ),
                        child: key == 'BACK'
                            ? Icon(Icons.backspace_outlined, size: 18, color: AppColors.textPrimary(context))
                            : Text(
                                key,
                                style: AppTypography.amountLarge(context: context),
                              ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
