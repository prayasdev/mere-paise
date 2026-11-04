import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/data/ledger_repository.dart';
import 'features/data/storage_service.dart';
import 'features/entries/quick_add_sheet.dart';
import 'features/home/home_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/manage/manage_screen.dart';
import 'features/providers/ledger_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.obsidian,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storageService = StorageService();
  final repository = LedgerRepository(storageService);
  await repository.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        ledgerRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MerePaiseApp(),
    ),
  );
}

class MerePaiseApp extends ConsumerWidget {
  const MerePaiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Mere Paise',
      debugShowCheckedModeBanner: false,
      theme: settings.isVellumTheme ? AppTheme.light() : AppTheme.dark(),
      home: const MainNavigationScaffold(),
    );
  }
}

class MainNavigationScaffold extends ConsumerStatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  ConsumerState<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends ConsumerState<MainNavigationScaffold> {
  int _currentIndex = 0;

  void _onDrillDown(String? categoryId, String? type) {
    ref.read(ledgerFilterProvider.notifier).setFilter(LedgerFilterState(
      categoryId: categoryId,
      type: type,
    ));
    setState(() => _currentIndex = 1); // Switch to Ledger
  }

  void _openQuickAdd() {
    QuickAddSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isVellum = settings.isVellumTheme;
    final navBg = isVellum ? AppColors.vellumCrypt : AppColors.crypt;
    final navBorder = isVellum ? AppColors.vellumIronLine : AppColors.ironLine;

    final pages = [
      HomeScreen(
        onNavigateToLedger: () => setState(() => _currentIndex = 1),
        onQuickAdd: _openQuickAdd,
      ),
      const LedgerScreen(),
      InsightsScreen(onDrillDown: _onDrillDown),
      const ManageScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBorder, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                // 1. Home
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    label: 'HOME',
                  ),
                ),
                // 2. Ledger
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    label: 'LEDGER',
                  ),
                ),
                // Centre: Tactile Brass Add (+) Button
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: InkWell(
                      onTap: _openQuickAdd,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brass,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.brassBright, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brass.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: AppColors.obsidian,
                        ),
                      ),
                    ),
                  ),
                ),
                // 3. Insights
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.bar_chart_outlined,
                    label: 'INSIGHTS',
                  ),
                ),
                // 4. Manage
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.tune_outlined,
                    label: 'MANAGE',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.brass : AppColors.textSecondary(context);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.labelGothic(
              color: color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
