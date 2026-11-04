import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gothic_card.dart';
import '../../core/widgets/gothic_empty_state.dart';
import '../models/transaction_entry.dart';
import '../providers/ledger_providers.dart';

enum InsightPeriod { week, month, year, all }

class InsightsScreen extends ConsumerStatefulWidget {
  final void Function(String? categoryId, String? type)? onDrillDown;

  const InsightsScreen({super.key, this.onDrillDown});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightPeriod _period = InsightPeriod.month;
  int _periodOffset = 0;
  String _activeTab = 'spent'; // 'spent' or 'received'
  int _touchedPieIndex = -1;

  DateTime _getTargetDate() {
    final now = DateTime.now();
    switch (_period) {
      case InsightPeriod.week:
        return now.add(Duration(days: _periodOffset * 7));
      case InsightPeriod.month:
        return DateTime(now.year, now.month + _periodOffset, 1);
      case InsightPeriod.year:
        return DateTime(now.year + _periodOffset, 1, 1);
      case InsightPeriod.all:
        return now;
    }
  }

  String _getPeriodLabel(DateTime target) {
    switch (_period) {
      case InsightPeriod.week:
        final start = LedgerDateUtils.getStartOfWeek(target);
        final end = start.add(const Duration(days: 6));
        return '${start.day} ${LedgerDateUtils.formatShortDate(start).split(' ')[1]} – ${end.day} ${LedgerDateUtils.formatShortDate(end).split(' ')[1]}';
      case InsightPeriod.month:
        return LedgerDateUtils.formatMonthHeader(target);
      case InsightPeriod.year:
        return target.year.toString();
      case InsightPeriod.all:
        return 'All Time History';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(transactionsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    final categoryMap = {for (var c in allCategories) c.id: c};
    final targetDate = _getTargetDate();

    // Filter transactions for this period
    final periodTxns = allTxns.where((t) {
      switch (_period) {
        case InsightPeriod.week:
          final start = LedgerDateUtils.getStartOfWeek(targetDate, weekStartsOn: settings.weekStartsOn);
          final end = start.add(const Duration(days: 7));
          return !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end);
        case InsightPeriod.month:
          return t.monthKey == LedgerDateUtils.monthKey(targetDate);
        case InsightPeriod.year:
          return t.yearKey == LedgerDateUtils.yearKey(targetDate);
        case InsightPeriod.all:
          return true;
      }
    }).toList();

    // Summary calculations
    int totalSpent = 0;
    int totalReceived = 0;
    TransactionEntry? largestExpense;

    for (final t in periodTxns) {
      if (t.isExpense) {
        totalSpent += t.amountPaise;
        if (largestExpense == null || t.amountPaise > largestExpense.amountPaise) {
          largestExpense = t;
        }
      }
      if (t.isIncome) {
        totalReceived += t.amountPaise;
      }
    }

    final int netSaved = totalReceived - totalSpent;

    // Daily average
    int daysInPeriod = 1;
    if (_period == InsightPeriod.week) daysInPeriod = 7;
    if (_period == InsightPeriod.month) {
      daysInPeriod = DateTime(targetDate.year, targetDate.month + 1, 0).day;
    }
    if (_period == InsightPeriod.year) daysInPeriod = 365;
    if (_period == InsightPeriod.all) {
      daysInPeriod = periodTxns.isNotEmpty
          ? DateTime.now().difference(periodTxns.last.occurredAt).inDays.clamp(1, 99999)
          : 1;
    }
    final int dailyAverage = totalSpent ~/ daysInPeriod;

    // Category distribution
    final categoryTotals = <String, int>{};
    final categoryCounts = <String, int>{};
    for (final t in periodTxns) {
      if (_activeTab == 'spent' && !t.isExpense) continue;
      if (_activeTab == 'received' && !t.isIncome) continue;
      categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amountPaise;
      categoryCounts[t.categoryId] = (categoryCounts[t.categoryId] ?? 0) + 1;
    }

    final sortedCatEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final int relevantTotal = _activeTab == 'spent' ? totalSpent : totalReceived;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INSIGHTS', style: AppTypography.headingLarge(context: context)),
            Text(
              'CASH FLOW & EXPENDITURE ANALYTICS',
              style: AppTypography.labelGothic(context: context, fontSize: 10),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 1. Time Horizon Switcher (WEEK, MONTH, YEAR, ALL)
            // -------------------------------------------------------------
            Row(
              children: InsightPeriod.values.map((p) {
                final isSelected = _period == p;
                final label = p.name.toUpperCase();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        LedgerHaptics.tick();
                        setState(() {
                          _period = p;
                          _periodOffset = 0;
                          _touchedPieIndex = -1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.elevated(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isSelected ? AppColors.brass : AppColors.border(context),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          label,
                          style: AppTypography.labelGothic(
                            color: isSelected ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Period Navigation Bar: < Date Range >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: AppColors.textPrimary(context), size: 24),
                  onPressed: _period == InsightPeriod.all
                      ? null
                      : () {
                          LedgerHaptics.tick();
                          setState(() {
                            _periodOffset -= 1;
                            _touchedPieIndex = -1;
                          });
                        },
                ),
                Text(
                  _getPeriodLabel(targetDate).toUpperCase(),
                  style: AppTypography.labelGothic(context: context, fontSize: 13),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: AppColors.textPrimary(context), size: 24),
                  onPressed: _period == InsightPeriod.all || _periodOffset >= 0
                      ? null
                      : () {
                          LedgerHaptics.tick();
                          setState(() {
                            _periodOffset += 1;
                            _touchedPieIndex = -1;
                          });
                        },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // -------------------------------------------------------------
            // 2. Financial Health Hero Card
            // -------------------------------------------------------------
            GothicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SPENT
                      Expanded(
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
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('SPENT', style: AppTypography.labelGothic(context: context, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatPaise(totalSpent),
                              style: AppTypography.amountLarge(color: AppColors.expense(context)),
                            ),
                          ],
                        ),
                      ),

                      // RECEIVED
                      Expanded(
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
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('RECEIVED', style: AppTypography.labelGothic(context: context, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatPaise(totalReceived),
                              style: AppTypography.amountLarge(color: AppColors.income(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Net Saved / Deficit Summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.elevated(context),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          netSaved >= 0 ? 'NET SAVINGS' : 'NET DEFICIT',
                          style: AppTypography.labelGothic(context: context, fontSize: 10),
                        ),
                        Text(
                          CurrencyFormatter.formatSignedPaise(netSaved, isIncome: netSaved >= 0),
                          style: AppTypography.amountMedium(
                            color: netSaved >= 0 ? AppColors.income(context) : AppColors.expense(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Optional Monthly Budget Progress
                  if (_period == InsightPeriod.month && settings.monthlyBudgetPaise != null) ...[
                    const SizedBox(height: 14),
                    _buildBudgetUsageBar(
                      context: context,
                      spentPaise: totalSpent,
                      budgetPaise: settings.monthlyBudgetPaise!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------------------
            // 3. Tab Switcher: SPENT vs RECEIVED
            // -------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      LedgerHaptics.tick();
                      setState(() {
                        _activeTab = 'spent';
                        _touchedPieIndex = -1;
                      });
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeTab == 'spent' ? AppColors.elevated(context) : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: _activeTab == 'spent' ? AppColors.brass : AppColors.border(context),
                          width: _activeTab == 'spent' ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        'SPENT BREAKDOWN',
                        style: AppTypography.labelGothic(
                          color: _activeTab == 'spent' ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      LedgerHaptics.tick();
                      setState(() {
                        _activeTab = 'received';
                        _touchedPieIndex = -1;
                      });
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeTab == 'received' ? AppColors.elevated(context) : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: _activeTab == 'received' ? AppColors.brass : AppColors.border(context),
                          width: _activeTab == 'received' ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        'RECEIVED BREAKDOWN',
                        style: AppTypography.labelGothic(
                          color: _activeTab == 'received' ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (sortedCatEntries.isEmpty)
              GothicEmptyState(
                title: 'No Records for this Period',
                subtitle: 'No ${_activeTab == 'spent' ? 'expenses' : 'income'} found for ${_getPeriodLabel(targetDate)}.',
              )
            else ...[
              // -------------------------------------------------------------
              // 4. Interactive Category Donut / Pie Chart
              // -------------------------------------------------------------
              GothicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISTRIBUTION BY CATEGORY',
                      style: AppTypography.labelGothic(context: context, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedPieIndex = -1;
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 52,
                              sections: List.generate(sortedCatEntries.length, (i) {
                                final isTouched = i == _touchedPieIndex;
                                final entry = sortedCatEntries[i];
                                final cat = categoryMap[entry.key];
                                final color = AppColors.getColorByToken(cat?.colorToken);
                                final radius = isTouched ? 34.0 : 26.0;

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: radius,
                                );
                              }),
                            ),
                          ),

                          // Donut Center Total & Info
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _touchedPieIndex >= 0 && _touchedPieIndex < sortedCatEntries.length
                                    ? (categoryMap[sortedCatEntries[_touchedPieIndex].key]?.name ?? '')
                                    : (_activeTab == 'spent' ? 'TOTAL SPENT' : 'TOTAL RECEIVED'),
                                style: AppTypography.labelGothic(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                CurrencyFormatter.formatPaise(
                                  _touchedPieIndex >= 0 && _touchedPieIndex < sortedCatEntries.length
                                      ? sortedCatEntries[_touchedPieIndex].value
                                      : relevantTotal,
                                ),
                                style: AppTypography.amountMedium(context: context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick Category Color Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: sortedCatEntries.map((e) {
                        final cat = categoryMap[e.key];
                        final color = AppColors.getColorByToken(cat?.colorToken);
                        final pct = relevantTotal > 0 ? (e.value / relevantTotal * 100).toStringAsFixed(0) : '0';

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              '${cat?.name ?? ''} ($pct%)',
                              style: AppTypography.bodySmall(context: context),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // 5. Practical Spending Cadence Chart
              // -------------------------------------------------------------
              GothicCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _period == InsightPeriod.week
                          ? 'DAILY SPENDING PATTERN'
                          : (_period == InsightPeriod.month ? 'WEEKLY SPENDING VELOCITY' : 'MONTHLY OVERVIEW'),
                      style: AppTypography.labelGothic(context: context, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 170,
                      child: _buildUsefulCadenceChart(
                        context: context,
                        txns: periodTxns,
                        targetDate: targetDate,
                        weekStartsOn: settings.weekStartsOn,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // -------------------------------------------------------------
              // 6. Actionable Analytics Quick Stats
              // -------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: GothicCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAILY AVERAGE', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(dailyAverage),
                            style: AppTypography.amountMedium(context: context),
                          ),
                          const SizedBox(height: 2),
                          Text('over $daysInPeriod days', style: AppTypography.bodySmall(color: AppColors.textTertiary(context))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GothicCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LARGEST EXPENSE', style: AppTypography.labelGothic(context: context, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            largestExpense != null ? CurrencyFormatter.formatPaise(largestExpense.amountPaise) : '₹ 0',
                            style: AppTypography.amountMedium(color: AppColors.expense(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            largestExpense != null
                                ? (categoryMap[largestExpense.categoryId]?.name ?? 'Expense')
                                : 'None',
                            style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 7. Ranked Category Breakdown List with Drill-Down
              // -------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CATEGORIES RANKED',
                    style: AppTypography.labelGothic(context: context, fontSize: 11),
                  ),
                  Text(
                    'Tap to view ledger entries',
                    style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedCatEntries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = sortedCatEntries[index];
                  final cat = categoryMap[item.key];
                  final count = categoryCounts[item.key] ?? 0;
                  final percentage = relevantTotal > 0 ? (item.value / relevantTotal) : 0.0;
                  final catColor = AppColors.getColorByToken(cat?.colorToken);

                  return InkWell(
                    onTap: () {
                      LedgerHaptics.tick();
                      if (widget.onDrillDown != null) {
                        widget.onDrillDown!(item.key, _activeTab == 'spent' ? 'expense' : 'income');
                      } else {
                        ref.read(ledgerFilterProvider.notifier).setFilter(
                          LedgerFilterState(categoryId: item.key),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: catColor.withValues(alpha: 0.5)),
                                ),
                                child: Icon(
                                  CategoryIcons.getIcon(cat?.iconName),
                                  size: 16,
                                  color: catColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat?.name ?? 'Unknown',
                                      style: AppTypography.bodyLarge(context: context),
                                    ),
                                    Text(
                                      '$count entries',
                                      style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatPaise(item.value),
                                    style: AppTypography.amountMedium(
                                      color: _activeTab == 'spent' ? AppColors.expense(context) : AppColors.income(context),
                                    ),
                                  ),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary(context)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Proportional colored bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: LinearProgressIndicator(
                              value: percentage.clamp(0.0, 1.0),
                              backgroundColor: AppColors.elevated(context),
                              valueColor: AlwaysStoppedAnimation<Color>(catColor),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetUsageBar({
    required BuildContext context,
    required int spentPaise,
    required int budgetPaise,
  }) {
    final double fraction = budgetPaise > 0 ? (spentPaise / budgetPaise).clamp(0.0, 1.0) : 0.0;
    final int percent = budgetPaise > 0 ? ((spentPaise * 100) ~/ budgetPaise) : 0;
    final isOver = spentPaise > budgetPaise;

    final Color barColor = isOver
        ? AppColors.expense(context)
        : (fraction > 0.8 ? AppColors.tallow : AppColors.income(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MONTHLY BUDGET TARGET', style: AppTypography.labelGothic(context: context, fontSize: 10)),
            Text(
              '$percent% used (${CurrencyFormatter.formatPaise(spentPaise)} / ${CurrencyFormatter.formatPaise(budgetPaise)})',
              style: AppTypography.bodySmall(
                color: isOver ? AppColors.expense(context) : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.elevated(context),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildUsefulCadenceChart({
    required BuildContext context,
    required List<TransactionEntry> txns,
    required DateTime targetDate,
    required int weekStartsOn,
  }) {
    if (_period == InsightPeriod.week) {
      // 7-day pattern
      final start = LedgerDateUtils.getStartOfWeek(targetDate, weekStartsOn: weekStartsOn);
      final days = List.generate(7, (i) => start.add(Duration(days: i)));
      final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

      final dailyTotals = <int>[];
      int maxVal = 1;
      for (final day in days) {
        final key = LedgerDateUtils.dayKey(day);
        int sum = 0;
        for (final t in txns) {
          if (t.isExpense && t.dayKey == key) {
            sum += t.amountPaise;
          }
        }
        dailyTotals.add(sum);
        if (sum > maxVal) maxVal = sum;
      }

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal / 100.0) * 1.15,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < 7) {
                    final day = days[idx];
                    return Text(
                      '${weekdayLabels[day.weekday - 1]}\n${day.day}',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelGothic(context: context, fontSize: 10),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (i) {
            final val = dailyTotals[i];
            final isMax = val > 0 && val == maxVal;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val / 100.0,
                  color: isMax ? AppColors.brass : AppColors.expense(context),
                  width: 18,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }),
        ),
      );
    }

    if (_period == InsightPeriod.month) {
      // 4 or 5 weekly buckets within the month
      final lastDay = DateTime(targetDate.year, targetDate.month + 1, 0).day;
      final weekBuckets = <String, int>{'W1 (1-7)': 0, 'W2 (8-14)': 0, 'W3 (15-21)': 0, 'W4 (22-28)': 0};
      if (lastDay > 28) {
        weekBuckets['W5 (29-$lastDay)'] = 0;
      }

      for (final t in txns) {
        if (!t.isExpense) continue;
        final d = t.occurredAt.day;
        if (d <= 7) {
          weekBuckets['W1 (1-7)'] = (weekBuckets['W1 (1-7)'] ?? 0) + t.amountPaise;
        } else if (d <= 14) {
          weekBuckets['W2 (8-14)'] = (weekBuckets['W2 (8-14)'] ?? 0) + t.amountPaise;
        } else if (d <= 21) {
          weekBuckets['W3 (15-21)'] = (weekBuckets['W3 (15-21)'] ?? 0) + t.amountPaise;
        } else if (d <= 28) {
          weekBuckets['W4 (22-28)'] = (weekBuckets['W4 (22-28)'] ?? 0) + t.amountPaise;
        } else {
          weekBuckets['W5 (29-$lastDay)'] = (weekBuckets['W5 (29-$lastDay)'] ?? 0) + t.amountPaise;
        }
      }

      final list = weekBuckets.entries.toList();
      int maxBucket = 1;
      for (final e in list) {
        if (e.value > maxBucket) maxBucket = e.value;
      }

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxBucket / 100.0) * 1.15,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < list.length) {
                    return Text(
                      list[idx].key.split(' ')[0],
                      style: AppTypography.labelGothic(context: context, fontSize: 10),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: list.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value / 100.0,
                  color: AppColors.expense(context),
                  width: 28,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    // Default: Year or All time (12 months)
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthSpent = List.filled(12, 0);
    int maxMonth = 1;

    for (final t in txns) {
      if (t.isExpense) {
        final m = t.occurredAt.month - 1;
        monthSpent[m] += t.amountPaise;
        if (monthSpent[m] > maxMonth) maxMonth = monthSpent[m];
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxMonth / 100.0) * 1.15,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < 12) {
                  return Text(
                    months[idx][0],
                    style: AppTypography.labelGothic(context: context, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: List.generate(12, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: monthSpent[i] / 100.0,
                color: AppColors.expense(context),
                width: 10,
                borderRadius: BorderRadius.circular(1),
              ),
            ],
          );
        }),
      ),
    );
  }
}
