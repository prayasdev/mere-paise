import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gothic_empty_state.dart';
import '../entries/quick_add_sheet.dart';
import '../models/category_item.dart';
import '../models/transaction_entry.dart';
import '../providers/ledger_providers.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilterPanel = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxns = ref.watch(filteredTransactionsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final allTags = ref.watch(tagsProvider);
    final filter = ref.watch(ledgerFilterProvider);
    final categoryMap = {for (var c in allCategories) c.id: c};
    final tagMap = {for (var t in allTags) t.id: t.name};

    final isAmountSorted = filter.sortOption == LedgerSortOption.amountHighToLow ||
        filter.sortOption == LedgerSortOption.amountLowToHigh;

    // Group transactions by dayKey for date-based sorting
    final grouped = <String, List<TransactionEntry>>{};
    for (final t in filteredTxns) {
      grouped.putIfAbsent(t.dayKey, () => []).add(t);
    }
    final sortedDayKeys = grouped.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LEDGER', style: AppTypography.headingLarge(context: context)),
            Text(
              '${filteredTxns.length} ENTRIES RECORDED',
              style: AppTypography.labelGothic(context: context, fontSize: 10),
            ),
          ],
        ),
        actions: [
          // Sort Menu Action
          PopupMenuButton<LedgerSortOption>(
            icon: Icon(
              Icons.swap_vert_rounded,
              color: filter.sortOption != LedgerSortOption.newestFirst
                  ? AppColors.brass
                  : AppColors.textPrimary(context),
            ),
            tooltip: 'Sort Ledger',
            color: AppColors.surface(context),
            onSelected: (option) {
              LedgerHaptics.tick();
              ref.read(ledgerFilterProvider.notifier).setFilter(
                    filter.copyWith(sortOption: option),
                  );
            },
            itemBuilder: (ctx) => [
              _buildSortMenuItem(
                context,
                title: 'Newest First (Default)',
                value: LedgerSortOption.newestFirst,
                current: filter.sortOption,
              ),
              _buildSortMenuItem(
                context,
                title: 'Oldest First',
                value: LedgerSortOption.oldestFirst,
                current: filter.sortOption,
              ),
              _buildSortMenuItem(
                context,
                title: 'Highest Amount (₹ ↓)',
                value: LedgerSortOption.amountHighToLow,
                current: filter.sortOption,
              ),
              _buildSortMenuItem(
                context,
                title: 'Lowest Amount (₹ ↑)',
                value: LedgerSortOption.amountLowToHigh,
                current: filter.sortOption,
              ),
            ],
          ),

          // Filter Toggle Action
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: AnimatedRotation(
                  turns: _showFilterPanel ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    _showFilterPanel ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: (_showFilterPanel || filter.hasActiveFilter) ? AppColors.brass : AppColors.textPrimary(context),
                  ),
                ),
                tooltip: 'Filter & Refine',
                onPressed: () {
                  LedgerHaptics.tick();
                  setState(() => _showFilterPanel = !_showFilterPanel);
                },
              ),
              if (filter.activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.brass,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${filter.activeFilterCount}',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelGothic(
                        color: AppColors.obsidian,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes, tags, categories...',
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16, color: AppColors.textSecondary(context)),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(ledgerFilterProvider.notifier).setFilter(
                                filter.copyWith(searchQuery: ''),
                              );
                        },
                      )
                    : null,
                isDense: true,
              ),
              style: AppTypography.bodyMedium(context: context),
              onChanged: (val) {
                ref.read(ledgerFilterProvider.notifier).setFilter(
                      filter.copyWith(searchQuery: val.trim()),
                    );
              },
            ),
          ),

          // Active Filter Chips Bar (Smooth animated glide in/out)
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: filter.hasActiveFilter
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Clear All Pill
                        InkWell(
                          onTap: () {
                            LedgerHaptics.tick();
                            _searchController.clear();
                            ref.read(ledgerFilterProvider.notifier).setFilter(const LedgerFilterState());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.expense(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.expense(context).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.refresh, size: 12, color: AppColors.expense(context)),
                                const SizedBox(width: 4),
                                Text(
                                  'RESET ALL',
                                  style: AppTypography.labelGothic(color: AppColors.expense(context), fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Sort Chip
                        if (filter.sortOption != LedgerSortOption.newestFirst)
                          _buildActiveFilterChip(
                            context: context,
                            label: 'Sort: ${_sortOptionLabel(filter.sortOption)}',
                            onRemove: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                  filter.copyWith(sortOption: LedgerSortOption.newestFirst),
                                ),
                          ),

                        // Type Chip
                        if (filter.type != null)
                          _buildActiveFilterChip(
                            context: context,
                            label: filter.type == 'expense' ? 'Spent Only' : 'Received Only',
                            onRemove: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                  filter.copyWith(clearType: true),
                                ),
                          ),

                        // Category Chip
                        if (filter.categoryId != null)
                          _buildActiveFilterChip(
                            context: context,
                            label: categoryMap[filter.categoryId]?.name ?? 'Category',
                            onRemove: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                  filter.copyWith(clearCategory: true),
                                ),
                          ),

                        // Tag Chip
                        if (filter.tagId != null)
                          _buildActiveFilterChip(
                            context: context,
                            label: '#${tagMap[filter.tagId] ?? 'tag'}',
                            onRemove: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                  filter.copyWith(clearTag: true),
                                ),
                          ),

                        // Date Range Chip
                        if (filter.dateRange != null)
                          _buildActiveFilterChip(
                            context: context,
                            label:
                                '${LedgerDateUtils.formatShortDate(filter.dateRange!.start)} – ${LedgerDateUtils.formatShortDate(filter.dateRange!.end)}',
                            onRemove: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                  filter.copyWith(clearDateRange: true),
                                ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Smooth Expandable Filter & Sort Drawer
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: _showFilterPanel
                ? AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeIn,
                    opacity: _showFilterPanel ? 1.0 : 0.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.elevated(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: TYPE Filter
                          Row(
                            children: [
                              Text('TYPE: ', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'All',
                                isSelected: filter.type == null,
                                onTap: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                      filter.copyWith(clearType: true),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'Spent',
                                isSelected: filter.type == 'expense',
                                onTap: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                      filter.copyWith(type: 'expense'),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'Received',
                                isSelected: filter.type == 'income',
                                onTap: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                      filter.copyWith(type: 'income'),
                                    ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Row 2: Category Filter
                          Row(
                            children: [
                              Text('CATEGORY: ', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      isExpanded: true,
                                      dropdownColor: AppColors.elevated(context),
                                      value: filter.categoryId,
                                      items: [
                                        DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('All Categories', style: AppTypography.bodyMedium(context: context)),
                                        ),
                                        ...allCategories.map((c) {
                                          final color = AppColors.getColorByToken(c.colorToken);
                                          return DropdownMenuItem<String?>(
                                            value: c.id,
                                            child: Row(
                                              children: [
                                                Icon(CategoryIcons.getIcon(c.iconName), size: 14, color: color),
                                                const SizedBox(width: 6),
                                                Text(c.name, style: AppTypography.bodyMedium(context: context)),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) {
                                          ref.read(ledgerFilterProvider.notifier).setFilter(
                                                filter.copyWith(clearCategory: true),
                                              );
                                        } else {
                                          ref.read(ledgerFilterProvider.notifier).setFilter(
                                                filter.copyWith(categoryId: val),
                                              );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Row 3: Date Range Quick Presets
                          Row(
                            children: [
                              Text('DATE: ', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'All Time',
                                isSelected: filter.dateRange == null,
                                onTap: () => ref.read(ledgerFilterProvider.notifier).setFilter(
                                      filter.copyWith(clearDateRange: true),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'This Month',
                                isSelected: false,
                                onTap: () {
                                  final now = DateTime.now();
                                  final start = DateTime(now.year, now.month, 1);
                                  final end = DateTime(now.year, now.month + 1, 0);
                                  ref.read(ledgerFilterProvider.notifier).setFilter(
                                        filter.copyWith(dateRange: DateTimeRange(start: start, end: end)),
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                context: context,
                                label: 'Custom 📅',
                                isSelected: filter.dateRange != null,
                                onTap: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    initialDateRange: filter.dateRange,
                                  );
                                  if (picked != null) {
                                    ref.read(ledgerFilterProvider.notifier).setFilter(
                                          filter.copyWith(dateRange: picked),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),

                          // Row 4: Tag Filter (If tags exist)
                          if (allTags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('TAG: ', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(context),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border(context)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        isExpanded: true,
                                        dropdownColor: AppColors.elevated(context),
                                        value: filter.tagId,
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('All Tags', style: AppTypography.bodyMedium(context: context)),
                                          ),
                                          ...allTags.map((t) {
                                            return DropdownMenuItem<String?>(
                                              value: t.id,
                                              child: Text('#${t.name}', style: AppTypography.bodyMedium(color: AppColors.brass)),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) {
                                          if (val == null) {
                                            ref.read(ledgerFilterProvider.notifier).setFilter(
                                                  filter.copyWith(clearTag: true),
                                                );
                                          } else {
                                            ref.read(ledgerFilterProvider.notifier).setFilter(
                                                  filter.copyWith(tagId: val),
                                                );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Ledger Entries List
          Expanded(
            child: filteredTxns.isEmpty
                ? GothicEmptyState(
                    title: 'No Matching Entries',
                    subtitle: filter.hasActiveFilter
                        ? 'Try clearing your search filters or sort options.'
                        : 'Your ledger is pristine. Tap + to record your first transaction.',
                  )
                : isAmountSorted
                    // Ranked List when sorted by Highest or Lowest Amount
                    ? ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: filteredTxns.length,
                        itemBuilder: (context, index) {
                          final entry = filteredTxns[index];
                          final cat = categoryMap[entry.categoryId];
                          final rank = index + 1;

                          return _buildTransactionTile(
                            context: context,
                            ref: ref,
                            entry: entry,
                            cat: cat,
                            tagMap: tagMap,
                            rank: rank,
                          );
                        },
                      )
                    // Chronological Day-Grouped List (Default & Oldest)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: sortedDayKeys.length,
                        itemBuilder: (context, dayIndex) {
                          final dayKey = sortedDayKeys[dayIndex];
                          final dayTxns = grouped[dayKey]!;
                          final firstDate = dayTxns.first.occurredAt;

                          int dayOutPaise = 0;
                          int dayInPaise = 0;
                          for (final t in dayTxns) {
                            if (t.isExpense) dayOutPaise += t.amountPaise;
                            if (t.isIncome) dayInPaise += t.amountPaise;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Header with Subtotal
                              Padding(
                                padding: const EdgeInsets.only(top: 14, bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      LedgerDateUtils.formatRelativeDay(firstDate).toUpperCase(),
                                      style: AppTypography.labelGothic(context: context, fontSize: 11),
                                    ),
                                    Row(
                                      children: [
                                        if (dayOutPaise > 0)
                                          Text(
                                            '− ${CurrencyFormatter.formatPaise(dayOutPaise)}  ',
                                            style: AppTypography.amountSmall(color: AppColors.expense(context)),
                                          ),
                                        if (dayInPaise > 0)
                                          Text(
                                            '+ ${CurrencyFormatter.formatPaise(dayInPaise)}',
                                            style: AppTypography.amountSmall(color: AppColors.income(context)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Day Entries
                              ...dayTxns.map((entry) {
                                final cat = categoryMap[entry.categoryId];
                                return _buildTransactionTile(
                                  context: context,
                                  ref: ref,
                                  entry: entry,
                                  cat: cat,
                                  tagMap: tagMap,
                                );
                              }),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile({
    required BuildContext context,
    required WidgetRef ref,
    required TransactionEntry entry,
    required CategoryItem? cat,
    required Map<String, String> tagMap,
    int? rank,
  }) {
    final isExpense = entry.isExpense;

    return Dismissible(
      key: Key('ledger_del_${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.oxblood,
        child: const Icon(Icons.delete_outline, color: AppColors.bone),
      ),
      onDismissed: (_) async {
        LedgerHaptics.doubleTick();
        final deleted = await ref.read(transactionsProvider.notifier).softDelete(entry.id);
        if (context.mounted && deleted != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry removed (${CurrencyFormatter.formatPaise(entry.amountPaise)})'),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: AppColors.brass,
                onPressed: () {
                  ref.read(transactionsProvider.notifier).restore(entry.id);
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: rank != null
              ? Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.elevated(context),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    '#$rank',
                    style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 12),
                  ),
                )
              : Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.elevated(context),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Icon(
                    CategoryIcons.getIcon(cat?.iconName),
                    size: 16,
                    color: AppColors.getColorByToken(cat?.colorToken),
                  ),
                ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  cat?.name ?? 'Unknown',
                  style: AppTypography.bodyMedium(context: context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.formatSignedPaise(entry.amountPaise, isIncome: !isExpense),
                style: AppTypography.amountMedium(
                  color: isExpense ? AppColors.expense(context) : AppColors.income(context),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  entry.note.isNotEmpty ? entry.note : LedgerDateUtils.formatDisplayDate(entry.occurredAt),
                  style: AppTypography.bodySmall(context: context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.tagIds.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  entry.tagIds.map((id) => '#${tagMap[id] ?? ''}').join(' '),
                  style: AppTypography.bodySmall(color: AppColors.brass),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                rank != null
                    ? '${LedgerDateUtils.formatShortDate(entry.occurredAt)} • ${LedgerDateUtils.formatTime(entry.occurredAt)}'
                    : LedgerDateUtils.formatTime(entry.occurredAt),
                style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
              ),
            ],
          ),
          onTap: () {
            QuickAddSheet.show(context, initialEntry: entry);
          },
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: () {
        LedgerHaptics.tick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brass : AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brass : AppColors.border(context),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brass.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelGothic(
            color: isSelected ? (isDark ? AppColors.obsidian : AppColors.vellumInk) : AppColors.textPrimary(context),
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required BuildContext context,
    required String label,
    required VoidCallback onRemove,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brass.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.brass),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () {
              LedgerHaptics.tick();
              onRemove();
            },
            borderRadius: BorderRadius.circular(12),
            child: Icon(Icons.close, size: 14, color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<LedgerSortOption> _buildSortMenuItem(
    BuildContext context, {
    required String title,
    required LedgerSortOption value,
    required LedgerSortOption current,
  }) {
    final isSelected = value == current;
    return PopupMenuItem<LedgerSortOption>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 16,
            color: isSelected ? AppColors.brass : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTypography.bodyMedium(
              color: isSelected ? AppColors.brass : AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _sortOptionLabel(LedgerSortOption option) {
    switch (option) {
      case LedgerSortOption.newestFirst:
        return 'Newest';
      case LedgerSortOption.oldestFirst:
        return 'Oldest';
      case LedgerSortOption.amountHighToLow:
        return 'Highest ₹';
      case LedgerSortOption.amountLowToHigh:
        return 'Lowest ₹';
    }
  }
}
