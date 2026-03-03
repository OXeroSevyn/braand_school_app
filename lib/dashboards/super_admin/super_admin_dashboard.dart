import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _OverviewTab(),
      const _UsersTab(),
      const _TasksTab(),
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
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
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final tasksAsync = ref.watch(allTasksProvider);
    final pendingUsers = ref.watch(pendingUsersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allUsersProvider);
        ref.invalidate(allTasksProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Super Admin',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Dashboard',
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(fontSize: 32),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Users',
                  value: usersAsync.when(
                    data: (u) => u.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Total Tasks',
                  value: tasksAsync.when(
                    data: (t) => t.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '!',
                  ),
                  icon: Icons.task,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Pending Approvals',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (pendingUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No pending approvals.'),
              ),
            ),
          for (final user in pendingUsers) _UserApprovalTile(user: user),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _UserApprovalTile extends ConsumerWidget {
  final UserModel user;
  const _UserApprovalTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(user.name),
        subtitle: Text('${user.email} • ${user.role.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: AppColors.success),
              onPressed: () => _updateUserStatus(ref, true),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: AppColors.error),
              onPressed: () => _deleteUser(ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(WidgetRef ref, bool approved) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('users').update({'approved': approved}).eq('id', user.id);
  }

  Future<void> _deleteUser(WidgetRef ref) async {
    // Note: Due to FK constraints and Supabase Auth, deleting a user usually requires
    // Edge Functions to delete auth.users, or you just reject/disable them in public.users.
    // We'll soft-delete or just remove from public.users table or leave them unapproved.
    final client = ref.read(supabaseClientProvider);
    await client.from('users').delete().eq('id', user.id);
  }
}

// Stubs for other tabs to keep file short
class _UsersTab extends ConsumerWidget {
  const _UsersTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Users',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              data: (users) => ListView.builder(
                itemCount: users.length,
                itemBuilder: (c, i) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(users[i].name),
                    subtitle: Text(users[i].role),
                    trailing: users[i].approved
                        ? const Icon(Icons.check, color: AppColors.success)
                        : const Icon(Icons.pending),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerWidget {
  const _TasksTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Tasks',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) => ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (c, i) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(tasks[i].title),
                    subtitle: Text('Status: ${tasks[i].status}'),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? '',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user?.email ?? '',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
