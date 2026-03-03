import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;
  String? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _OverviewTab(
        selectedTaskId: _selectedTaskId,
        onNavigate: (index) => setState(() => _currentIndex = index),
        onTaskSelected: (taskId) => setState(() => _selectedTaskId = taskId),
      ),
      const _TeamTab(),
      const _TaskTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (v) => setState(() => _currentIndex = v),
        backgroundColor: AppColors.card,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () => _showCreateTaskDialog(context, ref),
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              label: const Text(
                'Create Task',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            )
          : null,
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreateTaskForm(),
      ),
    );
  }
}

class _CreateTaskForm extends ConsumerStatefulWidget {
  const _CreateTaskForm();
  @override
  ConsumerState<_CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends ConsumerState<_CreateTaskForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _assignedTo;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final uid = ref.read(currentUserProvider).value?.id;
      if (uid == null) return;
      await ref.read(supabaseClientProvider).from('tasks').insert({
        'title': _titleController.text,
        'description': _descController.text,
        'assigned_to': _assignedTo,
        'created_by': uid,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamMembers =
        ref
            .watch(allUsersProvider)
            .value
            ?.where((u) => u.isTeam && u.approved)
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create New Task',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _assignedTo,
            decoration: const InputDecoration(labelText: 'Assign To'),
            items: teamMembers
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setState(() => _assignedTo = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Create Task'),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF167B8F), width: 2),
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final void Function(int) onNavigate;
  final String? selectedTaskId;
  final void Function(String?) onTaskSelected;

  const _OverviewTab({
    required this.onNavigate,
    required this.onTaskSelected,
    this.selectedTaskId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final usersAsync = ref.watch(allUsersProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final activityAsync = ref.watch(activityLogsProvider);

    int totalTeam = 0;
    int onlineNow = 0;
    int onBreak = 0;

    if (usersAsync.value != null) {
      final team = usersAsync.value!.where((u) => u.isTeam);
      totalTeam = team.length;
      if (totalTeam > 0) {
        onlineNow = (totalTeam * 0.6).round();
        onBreak = (totalTeam * 0.1).round();
      }
    }

    final bool hasOnlineMembers = onlineNow > 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUsersProvider);
        ref.invalidate(allTasksProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADMIN OVERVIEW',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hello, ${user?.name.split(' ').first ?? 'Admin'}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 32),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: AppColors.card),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.teamCardGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Team Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusMetric(
                      icon: Icons.group,
                      value: '$totalTeam',
                      label: 'TOTAL TEAM',
                    ),
                    _buildDivider(),
                    _buildStatusMetric(
                      icon: Icons.wifi,
                      value: '$onlineNow',
                      label: 'ONLINE NOW',
                      showDot: hasOnlineMembers,
                    ),
                    _buildDivider(),
                    _buildStatusMetric(
                      icon: Icons.coffee,
                      value: '$onBreak',
                      label: 'ON BREAK',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Live Activity Feed', 'View All'),
          const SizedBox(height: 16),
          _buildActivityFeed(activityAsync, usersAsync),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Quick Actions', 'See All'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigate(2),
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.assignment,
                    title: 'View Tasks',
                    subtitle: '3 pending today',
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => onNavigate(1),
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Attendance',
                    subtitle: '98% this month',
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
            context,
            'Task Progress',
            null,
            hasMore: true,
            onMorePressed: () => _showTaskSelectionMenu(context, ref),
          ),
          const SizedBox(height: 16),
          _buildTaskProgressCard(tasksAsync),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatusMetric({
    required IconData icon,
    required String value,
    required String label,
    bool showDot = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            if (showDot)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.onlinePulse,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF167B8F),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String? actionText, {
    bool hasMore = false,
    VoidCallback? onMorePressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {},
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (hasMore)
          IconButton(
            onPressed: onMorePressed ?? () {},
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
          ),
      ],
    );
  }

  void _showTaskSelectionMenu(BuildContext context, WidgetRef ref) {
    final tasks = ref.read(allTasksProvider).value ?? [];
    if (tasks.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Watch Task Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...tasks.map(
              (t) => ListTile(
                title: Text(t.title),
                trailing: t.id == selectedTaskId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onTaskSelected(t.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(
    AsyncValue<List<Map<String, dynamic>>> activityAsync,
    AsyncValue<List<UserModel>> usersAsync,
  ) {
    return activityAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No recent activity.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final users = usersAsync.value ?? [];

        final feedItems = logs.take(3).map((log) {
          final userId = log['user_id'] as String?;
          final user = users.firstWhere(
            (u) => u.id == userId,
            orElse: () => UserModel(
              id: '',
              email: '',
              role: '',
              name: 'Unknown User',
              approved: true,
              createdAt: DateTime.now(),
            ),
          );

          final action = log['action'] as String? ?? 'performed action';
          final project = log['target_name'] as String? ?? '';
          final createdAtStr = log['created_at'] as String?;
          final createdAt = createdAtStr != null
              ? DateTime.parse(createdAtStr)
              : DateTime.now();

          final diff = DateTime.now().difference(createdAt);
          String timeAgo = diff.inMinutes < 60
              ? '${diff.inMinutes} mins ago'
              : '${diff.inHours} hours ago';
          if (diff.inDays > 0) timeAgo = '${diff.inDays} days ago';
          if (diff.inMinutes == 0) timeAgo = 'Just now';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildMockActivityItem(
              name: user.name,
              action: action,
              department: project,
              time: timeAgo,
              color: AppColors.primaryBlue,
            ),
          );
        }).toList();

        return Column(children: feedItems);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMockActivityItem({
    required String name,
    required String action,
    required String department,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    children: [
                      TextSpan(
                        text: '$name ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: action,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  department,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressCard(AsyncValue<List<TaskModel>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(child: Text('No active tasks to display.'));
        }

        final task = selectedTaskId != null
            ? tasks.firstWhere(
                (t) => t.id == selectedTaskId,
                orElse: () => tasks.first,
              )
            : tasks.first;
        final double progress = task.progress / 100.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.background,
                      color: AppColors.primary,
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (task.description != null)
                      Text(
                        task.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.status.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _TeamTab extends ConsumerWidget {
  const _TeamTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Team Tab'));
  }
}

class _TaskTab extends ConsumerWidget {
  const _TaskTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Task Tab'));
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('Profile Tab'));
  }
}
