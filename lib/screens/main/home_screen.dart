import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lovely/navigation/app_router.dart';
import 'package:lovely/providers/home_view_model.dart';
import 'package:lovely/widgets/home/week_strip.dart';
import 'package:lovely/widgets/home/cycle_card.dart';
import 'package:lovely/widgets/home/daily_tip_card.dart';
import 'package:lovely/services/auth_service.dart';
import 'package:lovely/widgets/email_verification_banner.dart';
import 'package:lovely/widgets/day_detail_bottom_sheet.dart';
import 'package:lovely/services/pin_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    ref.read(homeViewModelProvider);
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final pinService = PinService();
    if (!await pinService.hasPin()) {
      // Placeholder for prompt logic
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    // Show details for the selected date
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailBottomSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeStateAsync = ref.watch(homeViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: homeStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (homeState) {
          // Show verification dialog based on state
          if (homeState.showVerificationRequired) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                // Check if dialog already shown?
                // Simple logic might spam dialogs.
                // relying on setVerificationRequired(false) in dismissed callback of dialog
                // But wait, if built continuously...
                // Ideally separate event listener. For now, let's just use the banner.
                // Commenting out dialog auto-show to avoid loops, relying on Banner.
                // _showVerificationDialog();
              }
            });
          }

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  title: Column(
                    children: [
                      Text(
                        _getGreeting(homeState),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Lovely',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // TODO: Notifications
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.analytics);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_outline),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                    ),
                  ],
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80), // Fab spacing
                    child: Column(
                      children: [
                        if (homeState.showVerificationRequired)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: EmailVerificationBanner(),
                          ),

                        // Week Strip
                        WeekStrip(
                          currentPeriod: homeState.currentPeriod,
                          lastPeriodStart: homeState.lastPeriodStart,
                          averageCycleLength: homeState.averageCycleLength,
                          onDateSelected: _onDateSelected,
                        ),

                        // Main Cycle Card
                        CycleCard(
                          currentPeriod: homeState.currentPeriod,
                          lastPeriodStart: homeState.lastPeriodStart,
                          averageCycleLength: homeState.averageCycleLength,
                          averagePeriodLength: homeState.averagePeriodLength,
                        ),

                        const SizedBox(height: 12),

                        // View History Button
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.cycleHistory,
                            );
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('View Cycle History'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Daily Tip
                        // Daily Tip
                        DailyTipCard(
                          cycleDay: homeState.lastPeriodStart != null
                              ? DateTime.now()
                                        .difference(homeState.lastPeriodStart!)
                                        .inDays +
                                    1
                              : null,
                          avgCycleLength: homeState.averageCycleLength,
                          isPeriod: homeState.currentPeriod != null,
                        ),

                        // Note: We removed the giant list of quick actions and details from here
                        // because they were overwhelming. Logic is now cleaner.
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.dailyLog,
            arguments: {'selectedDate': _selectedDate},
          ).then(
            (_) => ref.refresh(homeViewModelProvider),
          ); // Refresh on return
        },
        icon: const Icon(Icons.add),
        label: const Text('Log'),
        elevation: 4,
      ),
    );
  }

  String _getGreeting(HomeState state) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good Morning';
    } else if (hour < 17) {
      timeGreeting = 'Good Afternoon';
    } else {
      timeGreeting = 'Good Evening';
    }

    // Personalized name if available
    final name =
        AuthService().currentUser?.userMetadata?['first_name'] ??
        AuthService().currentUser?.userMetadata?['name'] ??
        'lovely';

    return '$timeGreeting, $name';
  }
}
