import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gothic_card.dart';
import '../../core/widgets/gothic_divider.dart';
import '../../core/widgets/gothic_empty_state.dart';
import '../entries/quick_add_sheet.dart';
import '../models/category_item.dart';
import '../models/transaction_entry.dart';
import '../providers/ledger_providers.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToLedger;
  final VoidCallback onQuickAdd;

  const HomeScreen({
    super.key,
    required this.onNavigateToLedger,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final currentMonthSummary = ref.watch(currentMonthSummaryProvider);
    final allTransactions = ref.watch(transactionsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);

    // Recent 10 entries
    final recentEntries = allTransactions.take(10).toList();

    // Compute 7-day bar strip for current week
    final startOfWeek = LedgerDateUtils.getStartOfWeek(now, weekStartsOn: settings.weekStartsOn);
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final dayOutMap = <String, int>{};
    int maxDayOut = 1;
    for (final day in weekDays) {
      final key = LedgerDateUtils.dayKey(day);
      int sum = 0;
      for (final t in allTransactions) {
        if (t.isExpense && t.dayKey == key) {
          sum += t.amountPaise;
        }
      }
      dayOutMap[key] = sum;
      if (sum > maxDayOut) maxDayOut = sum;
    }

    final categoryMap = {for (var c in allCategories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.brass.withValues(alpha: 0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brass.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/icon/app_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MERE PAISE', style: AppTypography.wordmark(context: context, fontSize: 19)),
                Text(
                  LedgerDateUtils.formatMonthHeader(now).toUpperCase(),
                  style: AppTypography.labelGothic(context: context, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, color: AppColors.brass),
            tooltip: 'Quick Add',
            onPressed: onQuickAdd,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Balance Card
              GothicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NET THIS MONTH', style: AppTypography.labelGothic(context: context)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.elevated(context),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Text(
                            currentMonthSummary.netPaise >= 0 ? 'SURPLUS' : 'DEFICIT',
                            style: AppTypography.labelGothic(
                              color: currentMonthSummary.netPaise >= 0
                                  ? AppColors.income(context)
                                  : AppColors.expense(context),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.formatPaise(currentMonthSummary.netPaise),
                      style: AppTypography.amountLarge(
                        color: currentMonthSummary.netPaise >= 0 ? AppColors.brass : AppColors.expense(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Side-by-side Out & In blocks
              Row(
                children: [
                  Expanded(
                    child: GothicCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.oxblood,
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'SPENT',
                                style: AppTypography.labelGothic(context: context, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.formatPaise(currentMonthSummary.outPaise),
                            style: AppTypography.amountMedium(color: AppColors.expense(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GothicCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.verdigris,
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RECEIVED',
                                style: AppTypography.labelGothic(context: context, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyFormatter.formatPaise(currentMonthSummary.inPaise),
                            style: AppTypography.amountMedium(color: AppColors.income(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Compact 7-Day Bar Strip
              GothicCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('THIS WEEK AT A GLANCE', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                        Text(
                          '${weekDays.first.day}–${weekDays.last.day} ${LedgerDateUtils.formatShortDate(weekDays.last).split(' ')[1]}',
                          style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 54,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weekDays.map((d) {
                          final key = LedgerDateUtils.dayKey(d);
                          final amount = dayOutMap[key] ?? 0;
                          final fraction = maxDayOut > 0 ? (amount / maxDayOut).clamp(0.05, 1.0) : 0.05;
                          final isToday = d.day == now.day && d.month == now.month && d.year == now.year;
                          final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final label = weekdayLabels[d.weekday - 1];

                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 14,
                                      height: 38 * fraction,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? AppColors.brass
                                            : (amount > 0 ? AppColors.expense(context) : AppColors.border(context)),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: AppTypography.labelGothic(
                                    color: isToday ? AppColors.brass : AppColors.textSecondary(context),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const GothicDivider(showArchMotif: true, padding: EdgeInsets.symmetric(vertical: 16)),

              // Recent Entries Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECENT ENTRIES', style: AppTypography.labelGothic(context: context)),
                  TextButton(
                    onPressed: onNavigateToLedger,
                    child: Text(
                      'View All (${allTransactions.length})',
                      style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (recentEntries.isEmpty)
                GothicEmptyState(
                  title: 'No Entries Logged Yet',
                  subtitle: 'Tap the brass + button below to log your first chai, metro ticket, or salary.',
                  action: ElevatedButton(
                    onPressed: onQuickAdd,
                    child: const Text('Log An Entry'),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentEntries.length,
                  itemBuilder: (context, index) {
                    final entry = recentEntries[index];
                    final cat = categoryMap[entry.categoryId];
                    final isExpense = entry.isExpense;

                    return Dismissible(
                      key: Key('home_del_${entry.id}'),
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
                          leading: Container(
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
                              Text(
                                LedgerDateUtils.formatTime(entry.occurredAt),
                                style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                              ),
                            ],
                          ),
                          onTap: () {
                            QuickAddSheet.show(context, initialEntry: entry);
                          },
                          onLongPress: () {
                            LedgerHaptics.tick();
                            _showEntryOptions(context, ref, entry, cat);
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryOptions(
    BuildContext context,
    WidgetRef ref,
    TransactionEntry entry,
    CategoryItem? cat,
  ) {
    final amountText = CurrencyFormatter.formatPaise(entry.amountPaise);
    final isExpense = entry.isExpense;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(color: AppColors.border(context)),
            left: BorderSide(color: AppColors.border(context)),
            right: BorderSide(color: AppColors.border(context)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 3,
                color: isExpense ? AppColors.oxblood : AppColors.verdigris,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.elevated(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(
                        CategoryIcons.getIcon(cat?.iconName),
                        size: 16,
                        color: AppColors.getColorByToken(cat?.colorToken),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat?.name ?? 'Unknown', style: AppTypography.bodyMedium(context: context)),
                          Text(
                            entry.note.isNotEmpty ? entry.note : LedgerDateUtils.formatDisplayDate(entry.occurredAt),
                            style: AppTypography.bodySmall(context: context),
                          ),
                        ],
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
              ),
              Divider(height: 1, color: AppColors.border(context)),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.brass),
                title: Text('Edit Entry', style: AppTypography.bodyMedium(context: context)),
                onTap: () {
                  Navigator.pop(ctx);
                  QuickAddSheet.show(context, initialEntry: entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.oxbloodLit),
                title: Text('Delete Entry', style: AppTypography.bodyMedium(color: AppColors.oxbloodLit)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: AppColors.surface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      title: Text('Delete Entry?', style: AppTypography.headingMedium(context: context)),
                      content: Text(
                        'Are you sure you want to delete this $amountText entry? You have 6 seconds to undo.',
                        style: AppTypography.bodyMedium(context: context),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: Text('Cancel', style: AppTypography.labelGothic(color: AppColors.textSecondary(context))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.oxblood,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    LedgerHaptics.doubleTick();
                    final deleted = await ref.read(transactionsProvider.notifier).softDelete(entry.id);
                    if (context.mounted && deleted != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Entry removed ($amountText)'),
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
                  }
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
