import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/services/firestore_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final theme = Theme.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: firestoreService.getEvent(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final eventData = snapshot.data ?? {};
        final objective =
            eventData['objective'] ??
            eventData['shortDescription'] ??
            'Seek the Lord with all your heart.';

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.eventTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _buildEventHeader(context, objective, eventData),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.outline,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'ACTIVITIES'),
                      Tab(text: 'ABOUT'),
                      Tab(text: 'PEOPLE'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesTab(firestoreService),
                _buildAboutTab(eventData),
                _buildPeopleTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventHeader(
    BuildContext context,
    String objective,
    Map<String, dynamic> data,
  ) {
    final dateFormat = DateFormat('EEE, MMM dd');
    String dateRange = 'Date TBD';
    if (data['startDate'] != null && data['endDate'] != null) {
      final startRaw = data['startDate'];
      final endRaw = data['endDate'];

      final DateTime start = startRaw is Timestamp
          ? startRaw.toDate()
          : (startRaw is DateTime ? startRaw : DateTime.now());

      final DateTime end = endRaw is Timestamp
          ? endRaw.toDate()
          : (endRaw is DateTime ? endRaw : DateTime.now());

      dateRange = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateRange,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Objective Statement Highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF), // Very light Indigo
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.indigo.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION OBJECTIVE',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  objective,
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(FirestoreService firestoreService) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getActivities(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return const Center(child: Text('No activities scheduled yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            // Reuse ActivityCard or simplify here
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(activity['title'] ?? 'Activity'),
                subtitle: Text(activity['description'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vision & Background',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            data['longDescription'] ??
                data['shortDescription'] ??
                'No further details available.',
          ),
          const SizedBox(height: 32),
          const Text(
            'Logistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on_outlined,
            data['location'] ?? 'Global Online',
          ),
          _buildInfoRow(
            Icons.monetization_on_outlined,
            data['costType'] == 'paid' ? 'Paid Registration' : 'Free Event',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    return const Center(child: Text('Participants will appear here.'));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
