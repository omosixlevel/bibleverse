import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/events/events_screen.dart';
import 'features/rooms/rooms_screen.dart';
import 'features/bible/bible_screen.dart';
import 'features/discovery/public_discovery_screen.dart';
import 'features/profile/profile_screen.dart';
import 'core/widgets/sacred_bottom_navigation.dart';
import 'core/services/inspired_alert_service.dart';
import 'core/widgets/sacred_alert.dart';
import 'core/providers/app_navigation_provider.dart';
import 'core/localization/app_strings.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const PublicDiscoveryScreen(), // Index 1
    const EventsScreen(), // Index 2
    const RoomsScreen(), // Index 3
    const BibleScreen(), // Index 4
    const ProfileScreen(), // Index 5
  ];

  @override
  Widget build(BuildContext context) {
    final alertService = context.watch<InspiredAlertService>();
    final navProvider = context.watch<AppNavigationProvider>();
    final currentAlert = alertService.currentAlert;
    final strings = AppStrings.of(context);

    final List<SacredNavItem> navItems = [
      SacredNavItem(
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        label: strings.navHome,
      ),
      SacredNavItem(
        activeIcon: Icons.explore,
        inactiveIcon: Icons.explore_outlined,
        label: strings.navDiscover,
      ),
      SacredNavItem(
        activeIcon: Icons.event,
        inactiveIcon: Icons.event_outlined,
        label: strings.navEvents,
      ),
      SacredNavItem(
        activeIcon: Icons.groups,
        inactiveIcon: Icons.groups_outlined,
        label: strings.navRooms,
      ),
      SacredNavItem(
        activeIcon: Icons.menu_book,
        inactiveIcon: Icons.menu_book_outlined,
        label: strings.navBible,
      ),
      SacredNavItem(
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
        label: strings.navProfile,
      ),
    ];

    return Scaffold(
      extendBody: true, // Allow body to extend behind floating bar
      body: Stack(
        children: [
          IndexedStack(index: navProvider.currentIndex, children: _screens),
          if (currentAlert != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SacredAlert(
                alert: currentAlert,
                onDismiss: () => alertService.dismiss(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SacredBottomNavigation(
        selectedIndex: navProvider.currentIndex,
        onItemSelected: (index) {
          navProvider.setPageIndex(index);
        },
        items: navItems,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above nav bar
        child: FloatingActionButton(
          onPressed: () => _showGeminiConcierge(context),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
    );
  }

  void _showGeminiConcierge(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.tertiary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.tertiary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gemini Spiritual Engine",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Your AI-Powered Spiritual Companion",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                "HOW I OPERATE",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),

              _buildGeminiFeature(
                context,
                icon: Icons.psychology,
                title: "Spiritual Coach",
                description:
                    "I analyze your habits and habits to propose personalized spiritual paths on the Home Screen.",
              ),
              _buildGeminiFeature(
                context,
                icon: Icons.translate,
                title: "Deep Scripture Analysis",
                description:
                    "In the Bible tab, I provide original language roots, thematic studies, and prayer points.",
              ),
              _buildGeminiFeature(
                context,
                icon: Icons.admin_panel_settings,
                title: "Circle Moderation",
                description:
                    "I help moderate prayer circles, ensuring everyone has a turn to speak.",
              ),

              const SizedBox(height: 32),
              Text(
                "TRY A FEATURE",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Provider.of<AppNavigationProvider>(
                          context,
                          listen: false,
                        ).setPageIndex(4); // Bible
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text("Study Bible"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Trigger a demo alert
                        Provider.of<InspiredAlertService>(
                          context,
                          listen: false,
                        ).showAlert(
                          message: "Gemini is Active",
                          subMessage: "I am ready to assist your journey.",
                          intent: AlertIntent.revelation,
                        );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Demo Alert"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeminiFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.tertiary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
