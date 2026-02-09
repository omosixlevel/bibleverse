import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/locale_provider.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'bible_version_selector_screen.dart';
import 'language_selector_screen.dart';
import '../../core/localization/app_strings.dart';

/// Profile Screen - Focused on reflection, not vanity
/// No public follower counts or visible leaderboards
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileService _profileService = ProfileService();

  UserProfile? _userProfile;
  List<ActivityItem> _activities = [];
  bool _isEditingInterests = false;
  bool _isLoading = true;
  List<InsightItem> _insights = [];
  bool _isInsightsLoading = false;
  final Set<String> _selectedActivityFilters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Defer loading until after first frame to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final uid = authService.currentUser?.uid ?? 'user_offline';

      print('📱 Loading profile for uid: $uid');

      final profile = await _profileService.getUserProfile(uid);
      final activities = await _profileService.getActivityHistory(limit: 20);

      print('✅ Profile loaded: ${profile.displayName}');
      print('✅ Activities loaded: ${activities.length}');

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
        _activities = activities;
        _isLoading = false;
      });

      // Load insights (non-blocking)
      _loadInsights(profile.uid);
    } catch (e, stackTrace) {
      print('❌ Error loading profile: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadProfileData),
          ),
        );
      }
    }
  }

  Future<void> _loadInsights(String uid) async {
    if (!mounted) return;
    setState(() => _isInsightsLoading = true);

    try {
      final insights = await _profileService.getInsights(uid);
      if (mounted) {
        setState(() {
          _insights = insights;
          _isInsightsLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading insights: $e');
      if (mounted) setState(() => _isInsightsLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final TAB_TITLES = [
      strings.spiritualInterests,
      'Activity',
      strings.insights,
    ];

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.profileTitle)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your profile...'),
            ],
          ),
        ),
      );
    }

    // Fallback if profile failed to load
    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              Text(strings.error, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Please try again',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfileData,
                icon: const Icon(Icons.refresh),
                label: Text(strings.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            floating: false,
            pinned: true,

            title: Text(
              strings.profileTitle,
              style: TextStyle(
                color: innerBoxIsScrolled
                    ? theme.colorScheme.onSurface
                    : Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.tertiaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with edit button
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withOpacity(
                                    0.2,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: theme.colorScheme.surface,
                              backgroundImage: _userProfile?.avatarUrl != null
                                  ? NetworkImage(_userProfile!.avatarUrl!)
                                  : null,
                              child: _userProfile?.avatarUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 48,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userProfile?.displayName ?? 'Pilgrim',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),

                      Text(
                        '${strings.id}: ${_userProfile?.uid.substring(0, 12) ?? 'Unknown'}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                indicatorColor: theme.colorScheme.primary,

                tabs: [
                  Tab(text: strings.spiritualInterests),
                  Tab(text: strings.activityHistory),
                  Tab(text: strings.insights),
                ],
              ),
              theme.colorScheme.surface,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInterestsTab(theme, strings),
            _buildActivityTab(theme, strings),
            _buildInsightsTab(theme, strings),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsTab(ThemeData theme, AppStrings strings) {
    final allInterests = [
      'Prayer',
      'Worship',
      'Bible Study',
      'Fasting',
      'Evangelism',
      'Discipleship',
      'Meditation',
      'Journaling',
      'Fellowship',
      'Service',
      'Missions',
      'Teaching',
    ];

    final userInterests = _userProfile?.spiritualInterests ?? [];
    final stats = _userProfile?.stats ?? UserStats();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.spiritualInterests,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: Icon(_isEditingInterests ? Icons.check : Icons.edit),
              label: Text(_isEditingInterests ? strings.done : strings.edit),
              onPressed: () async {
                if (_isEditingInterests) {
                  // Save changes
                  await _profileService.updateSpiritualInterests(
                    _userProfile!.uid,
                    userInterests,
                  );
                }
                setState(() {
                  _isEditingInterests = !_isEditingInterests;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        Text(
          strings.interestsDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allInterests.map((interest) {
            final isSelected = userInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              showCheckmark: false,
              onSelected: _isEditingInterests
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          userInterests.add(interest);
                        } else {
                          userInterests.remove(interest);
                        }
                      });
                    }
                  : null,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Dynamic Stats Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.5),
                theme.colorScheme.tertiaryContainer.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    strings.privateStats,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    '${stats.currentStreak}',
                    strings.dayStreak,
                    Icons.local_fire_department,
                  ),
                  _buildStatItem(
                    theme,
                    '${stats.tasksCompletedThisWeek}',
                    strings.thisWeek,
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    theme,
                    '${stats.hoursThisWeek.toStringAsFixed(1)}h',
                    strings.timeInvested,
                    Icons.schedule,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActivityTab(ThemeData theme, AppStrings strings) {
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                strings.activityHistory,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.onlyYouCanSee,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),

          const SizedBox(height: 16),

          // Activity Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tasks', 'task_completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Bible', 'bible_read'),
                const SizedBox(width: 8),
                _buildFilterChip('Notes', 'note_created'),
                const SizedBox(width: 8),
                _buildFilterChip('Rooms', 'room_joined'),
                const SizedBox(width: 8),
                _buildFilterChip('Events', 'event_registered'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  strings.noActivities,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else ...[
            if (_filteredActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No activities match your filters',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              )
            else
              ..._filteredActivities.map(
                (activity) => _buildActivityTile(theme, activity),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTile(ThemeData theme, ActivityItem activity) {
    // Map activity types to icons and colors
    final activityConfig = _getActivityConfig(activity.type);
    final timeAgo = _formatTimeAgo(activity.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activityConfig['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activityConfig['icon'],
              size: 20,
              color: activityConfig['color'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (activity.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getActivityConfig(String type) {
    switch (type) {
      case 'task_completed':
        return {'icon': Icons.check_circle, 'color': Colors.green};
      case 'bible_read':
        return {'icon': Icons.menu_book, 'color': AppTheme.prayerColor};
      case 'note_created':
        return {'icon': Icons.note_add, 'color': Colors.orange};
      case 'room_joined':
        return {'icon': Icons.groups, 'color': Colors.purple};
      case 'event_registered':
        return {'icon': Icons.event, 'color': Colors.blue};
      case 'highlight_created':
        return {'icon': Icons.brush, 'color': Colors.amber};
      default:
        return {'icon': Icons.circle, 'color': Colors.grey};
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return 'Today, ${DateFormat.jm().format(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat.jm().format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.MMMd().format(timestamp);
    }
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _selectedActivityFilters.contains(type);
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedActivityFilters.add(type);
          } else {
            _selectedActivityFilters.remove(type);
          }
        });
      },
      showCheckmark: false,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  List<ActivityItem> get _filteredActivities {
    if (_selectedActivityFilters.isEmpty) return _activities;
    return _activities
        .where((a) => _selectedActivityFilters.contains(a.type))
        .toList();
  }

  Widget _buildInsightsTab(ThemeData theme, AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            Text(
              strings.insights,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Private, personalized insights based on your journey', // Missing key? Use general privacy message or added one? Using 'onlyYouCanSee' might be ok or need new key. Keeping hardcoded for speed or using onlyYouCanSee.
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Dynamic Insights from Gemini
        if (_isInsightsLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  Text(strings.generatingInsights),
                ],
              ),
            ),
          )
        else if (_insights.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Check back later for personalized insights based on your activity.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          )
        else
          ..._insights.map((insight) {
            Color color;
            IconData icon;

            // Resolve color
            try {
              color = insight.colorHex != null
                  ? Color(
                      int.parse(insight.colorHex!.replaceFirst('#', '0xFF')),
                    )
                  : theme.colorScheme.primary;
            } catch (_) {
              color = theme.colorScheme.primary;
            }

            // Resolve icon (basic mapping)
            switch (insight.iconName) {
              case 'wb_sunny':
                icon = Icons.wb_sunny;
                break;
              case 'menu_book':
                icon = Icons.menu_book;
                break;
              case 'trending_up':
                icon = Icons.trending_up;
                break;
              case 'lightbulb':
                icon = Icons.lightbulb;
                break;
              case 'star':
                icon = Icons.star;
                break;
              case 'timer':
                icon = Icons.timer;
                break;
              case 'auto_awesome':
                icon = Icons.auto_awesome;
                break;
              default:
                icon = Icons.lightbulb_outline;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInsightCard(
                theme,
                insight.title,
                icon,
                insight.description,
                color,
              ),
            );
          }).toList(),

        const SizedBox(height: 24),

        // Refresh button
        OutlinedButton.icon(
          onPressed: _loadProfileData,
          icon: const Icon(Icons.refresh),
          label: Text(strings.refreshInsights),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    ThemeData theme,
    String title,
    IconData icon,
    String content,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Edit Profile'),
                      subtitle: Text(_userProfile?.displayName ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(profile: _userProfile!),
                          ),
                        );
                        if (result == true) {
                          _loadProfileData(); // Reload profile after edit
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      subtitle: Text(
                        _userProfile?.preferences.notificationsEnabled ?? true
                            ? 'Enabled'
                            : 'Disabled',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationSettingsScreen(
                              profile: _userProfile!,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Theme'),
                      subtitle: Text(
                        context.watch<ThemeProvider>().isDarkMode
                            ? 'Dark'
                            : 'Light',
                      ),
                      trailing: Switch(
                        value: context.watch<ThemeProvider>().isDarkMode,
                        onChanged: (value) {
                          context.read<ThemeProvider>().toggleTheme();
                        },
                      ),
                      onTap: () {
                        context.read<ThemeProvider>().toggleTheme();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: const Text('Bible Version'),
                      subtitle: Text(
                        _userProfile?.preferences.bibleVersion ?? 'KJV',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BibleVersionSelectorScreen(
                              profile: _userProfile!,
                            ),
                          ),
                        );
                        if (result != null) {
                          _loadProfileData(); // Reload to show new version
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: Text(
                        context.watch<LocaleProvider>().isFrench
                            ? 'Français'
                            : 'English',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LanguageSelectorScreen(profile: _userProfile!),
                          ),
                        );
                        if (result != null) {
                          _loadProfileData(); // Reload to sync any profile changes
                        }
                      },
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy & Security'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to privacy settings
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to help
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to about screen
                      },
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final shouldSignOut = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                ),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (shouldSignOut == true && context.mounted) {
                          await context.read<AuthService>().signOut();
                          _profileService.clearCache();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
