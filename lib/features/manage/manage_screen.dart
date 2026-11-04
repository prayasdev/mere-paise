import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/gothic_card.dart';
import '../../core/widgets/gothic_divider.dart';
import '../providers/ledger_providers.dart';
import 'categories_screen.dart';

class ManageScreen extends ConsumerWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final allCategories = ref.watch(categoriesProvider);
    final tags = ref.watch(tagsProvider);
    final txns = ref.watch(transactionsProvider);
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(ledgerRepositoryProvider);

    final expenseCategories = allCategories.where((c) => c.kind == 'expense' && !c.archived).toList();
    final incomeCategories = allCategories.where((c) => c.kind == 'income' && !c.archived).toList();

    // Compute tag statistics
    final tagSpendMap = <String, int>{};
    final tagCountMap = <String, int>{};
    for (final t in txns) {
      for (final tagId in t.tagIds) {
        tagCountMap[tagId] = (tagCountMap[tagId] ?? 0) + 1;
        if (t.isExpense) {
          tagSpendMap[tagId] = (tagSpendMap[tagId] ?? 0) + t.amountPaise;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MANAGE', style: AppTypography.headingLarge(context: context)),
            Text(
              'LEDGER SETTINGS & CONTROLS',
              style: AppTypography.labelGothic(context: context, fontSize: 10),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // SECTION 1: Offline Sovereignty & Privacy
            // -------------------------------------------------------------
            Text(
              'OFFLINE SOVEREIGNTY & PRIVACY',
              style: AppTypography.labelGothic(context: context, fontSize: 11),
            ),
            const SizedBox(height: 8),

            GothicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brass.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.brass, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Offline & Private',
                              style: AppTypography.headingSmall(context: context),
                            ),
                            Text(
                              'Zero cloud servers • Zero trackers • Zero network calls',
                              style: AppTypography.bodySmall(
                                color: isDark ? AppColors.verdigrisLit : AppColors.verdigris,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const GothicDivider(),
                  const SizedBox(height: 10),
                  Text(
                    'All your financial data, accounts, categories, and tags are stored strictly in your device\'s local storage with solid integer paise arithmetic. You own and control 100% of your data.',
                    style: AppTypography.bodyMedium(context: context),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.elevated(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.textSecondary(context)),
                        const SizedBox(width: 8),
                        Text(
                          '${txns.length} transactions stored safely on this device',
                          style: AppTypography.labelGothic(context: context, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // SECTION 2: Categories Hub (Compact Clickable Card)
            // -------------------------------------------------------------
            Text(
              'CATEGORIES & CLASSIFICATIONS',
              style: AppTypography.labelGothic(context: context, fontSize: 11),
            ),
            const SizedBox(height: 8),

            GothicCard(
              onTap: () {
                LedgerHaptics.tick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.brass.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.brass.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.category_outlined, color: AppColors.brass, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Categories', style: AppTypography.bodyLarge(context: context)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.elevated(context),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Text(
                                '${expenseCategories.length} Out • ${incomeCategories.length} In',
                                style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tap to add, edit, reorder, or archive categories',
                          style: AppTypography.bodySmall(context: context),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary(context), size: 22),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // SECTION 3: Tags & Labels Hub
            // -------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TAGS & LABELS (${tags.length})',
                  style: AppTypography.labelGothic(context: context, fontSize: 11),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => _showNewTagDialog(context, ref),
                  icon: const Icon(Icons.add, size: 14, color: AppColors.brass),
                  label: Text('New Tag', style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            GothicCard(
              padding: const EdgeInsets.all(12),
              child: tags.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No tags created yet. Add #tags while recording entries to cross-categorise trips, projects, or events.',
                        style: AppTypography.bodyMedium(context: context),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((t) {
                        final count = tagCountMap[t.id] ?? 0;
                        final spend = tagSpendMap[t.id] ?? 0;

                        return InkWell(
                          onTap: () => _showTagActionsSheet(context, ref, t),
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.elevated(context),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('#${t.name}', style: AppTypography.bodyMedium(color: AppColors.brass)),
                                const SizedBox(width: 6),
                                Text(
                                  '$count • ${CurrencyFormatter.formatPaise(spend)}',
                                  style: AppTypography.bodySmall(context: context),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // SECTION 4: Ledger Preferences
            // -------------------------------------------------------------
            Text(
              'LEDGER PREFERENCES',
              style: AppTypography.labelGothic(context: context, fontSize: 11),
            ),
            const SizedBox(height: 8),

            // Theme Variant Switcher
            GothicCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        settings.isVellumTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: AppColors.brass,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme Variant', style: AppTypography.bodyLarge(context: context)),
                          Text(
                            settings.isVellumTheme
                                ? 'Vellum (Parchment & Sepia Rules)'
                                : 'Ledger of the Night (Dark Obsidian)',
                            style: AppTypography.bodySmall(context: context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: settings.isVellumTheme,
                    activeThumbColor: AppColors.brass,
                    onChanged: (val) {
                      LedgerHaptics.tick();
                      ref.read(settingsProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Week Starts On
            GothicCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.brass, size: 22),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Week Starts On', style: AppTypography.bodyLarge(context: context)),
                          Text(
                            settings.weekStartsOn == 1 ? 'Monday' : 'Sunday',
                            style: AppTypography.bodySmall(context: context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: settings.weekStartsOn,
                      dropdownColor: AppColors.elevated(context),
                      style: AppTypography.bodyLarge(context: context),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          LedgerHaptics.tick();
                          ref.read(settingsProvider.notifier).setWeekStart(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Monthly Budget Target
            GothicCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes_outlined, color: AppColors.brass, size: 22),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Budget Target', style: AppTypography.bodyLarge(context: context)),
                          Text(
                            settings.monthlyBudgetPaise != null
                                ? CurrencyFormatter.formatPaise(settings.monthlyBudgetPaise!)
                                : 'No budget configured',
                            style: AppTypography.bodySmall(context: context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showBudgetDialog(context, ref, settings.monthlyBudgetPaise),
                    child: Text('Edit', style: AppTypography.labelGothic(color: AppColors.brass)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // SECTION 5: Data & Archival
            // -------------------------------------------------------------
            Text(
              'DATA & ARCHIVAL',
              style: AppTypography.labelGothic(context: context, fontSize: 11),
            ),
            const SizedBox(height: 8),

            // Export CSV Card
            GothicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brass.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.table_chart_outlined, color: AppColors.brass, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Export Ledger (CSV)', style: AppTypography.headingSmall(context: context)),
                            const SizedBox(height: 4),
                            Text(
                              'Pristine spreadsheet export formatted with standard Indian Rupee notation (₹), signed amounts (+/-), category, and tags.',
                              style: AppTypography.bodySmall(context: context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.brass.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: txns.isEmpty
                              ? null
                              : () async {
                                  LedgerHaptics.tick();
                                  try {
                                    final filePath = await repo.exportCsvFile();
                                    // ignore: deprecated_member_use
                                    await Share.shareXFiles(
                                      [XFile(filePath)],
                                      text: 'Mere Paise - Offline Ledger Export (${txns.length} records)',
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Export failed: $e')),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.brass),
                          label: Text(
                            'SHARE CSV (${txns.length})',
                            style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brass,
                          foregroundColor: isDark ? AppColors.obsidian : AppColors.vellumInk,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: txns.isEmpty
                            ? null
                            : () async {
                                LedgerHaptics.tick();
                                try {
                                  final filePath = await repo.exportCsvFile();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('CSV saved to:\n$filePath'),
                                        backgroundColor: AppColors.verdigris,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Export failed: $e')),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text(
                          'SAVE FILE',
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
            ),

            const SizedBox(height: 8),

            // Rebuild Summaries
            GothicCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.sync_outlined, color: AppColors.textSecondary(context), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rebuild Period Summaries', style: AppTypography.bodyLarge(context: context)),
                        Text(
                          'Recalculate monthly aggregates directly from pristine transaction entries',
                          style: AppTypography.bodySmall(context: context),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      LedgerHaptics.tick();
                      await ref.read(transactionsProvider.notifier).rebuildSummaries();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All period summaries recalculated successfully.')),
                        );
                      }
                    },
                    child: Text('Rebuild', style: AppTypography.labelGothic(color: AppColors.brass)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Clear All Data
            GothicCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.delete_forever_outlined, color: AppColors.expense(context), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clear All Ledger Data',
                          style: AppTypography.bodyLarge(color: AppColors.expense(context)),
                        ),
                        Text(
                          'Permanently wipe local transactions and custom categories',
                          style: AppTypography.bodySmall(context: context),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmResetData(context, ref),
                    child: Text(
                      'Reset',
                      style: AppTypography.labelGothic(color: AppColors.expense(context)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // SECTION 6: App Details & Identity
            // -------------------------------------------------------------
            Text(
              'ABOUT & RELEASES',
              style: AppTypography.labelGothic(context: context, fontSize: 11),
            ),
            const SizedBox(height: 8),

            GothicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.brass, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brass.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/icon/app_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Mere Paise', style: AppTypography.headingMedium(context: context)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brass.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.brass.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'v1.0.1',
                                    style: AppTypography.labelGothic(color: AppColors.brass, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'The Honest Account Book for Indian Money',
                              style: AppTypography.bodySmall(context: context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const GothicDivider(),
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: () async {
                        final url = Uri.parse('https://github.com/prayasdev');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Could not launch dev link: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Made with ',
                              style: AppTypography.bodyMedium(context: context),
                            ),
                            const Icon(Icons.favorite, size: 14, color: AppColors.oxbloodLit),
                            Text(
                              ' by ',
                              style: AppTypography.bodyMedium(context: context),
                            ),
                            Text(
                              'prayasdev',
                              style: AppTypography.bodyMedium(
                                color: AppColors.brass,
                              ).copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.brass,
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
    );
  }

  Future<void> _showNewTagDialog(BuildContext context, WidgetRef ref) async {
    final textCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Tag', style: AppTypography.headingMedium(context: ctx)),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(hintText: 'e.g. goa-trip, college-fest'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, textCtrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(tagsProvider.notifier).getOrCreateTag(name.trim());
    }
  }

  Future<void> _showTagActionsSheet(BuildContext context, WidgetRef ref, dynamic tag) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppColors.textPrimary(context)),
                title: Text('Rename #${tag.name}', style: AppTypography.bodyLarge(context: context)),
                onTap: () => Navigator.pop(ctx, 'rename'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.oxbloodLit),
                title: Text(
                  'Delete #${tag.name}',
                  style: AppTypography.bodyLarge(color: AppColors.expense(context)),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'rename' && context.mounted) {
      final ctrl = TextEditingController(text: tag.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Rename Tag', style: AppTypography.headingMedium(context: ctx)),
          content: TextField(controller: ctrl),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Rename')),
          ],
        ),
      );
      if (newName != null && newName.trim().isNotEmpty) {
        await ref.read(tagsProvider.notifier).renameTag(tag.id, newName);
      }
    } else if (action == 'delete') {
      await ref.read(tagsProvider.notifier).deleteTag(tag.id, widgetRef: ref);
    }
  }

  Future<void> _showBudgetDialog(BuildContext context, WidgetRef ref, int? currentBudgetPaise) async {
    final ctrl = TextEditingController(
      text: currentBudgetPaise != null ? (currentBudgetPaise ~/ 100).toString() : '',
    );
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Monthly Budget Target (₹)', style: AppTypography.headingMedium(context: ctx)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 25000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'clear'),
            child: const Text('Clear Budget'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == 'clear') {
      ref.read(settingsProvider.notifier).setMonthlyBudget(null);
    } else if (res != null) {
      final rupees = int.tryParse(res) ?? 0;
      ref.read(settingsProvider.notifier).setMonthlyBudget(rupees * 100);
    }
  }

  Future<void> _confirmResetData(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Wipe All Ledger Data?',
          style: AppTypography.headingMedium(color: AppColors.expense(ctx)),
        ),
        content: Text(
          'Are you sure you want to delete all entries? This will completely purge your local bahi-khata. This cannot be undone.',
          style: AppTypography.bodyMedium(context: ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oxblood),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(transactionsProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All ledger data has been reset.')),
        );
      }
    }
  }
}
