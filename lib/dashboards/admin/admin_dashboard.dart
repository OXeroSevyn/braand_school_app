import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _OverviewTab(),
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
            value: _assignedTo,
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

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  Future<void> _exportPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF Export feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final unapproved =
        usersAsync.value?.where((u) => !u.approved && u.isTeam).length ?? 0;

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
                  Text('Admin', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    'Dashboard',
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(fontSize: 32),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _exportPDF(context),
                icon: const Icon(Icons.picture_as_pdf),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (unapproved > 0)
            Card(
              color: AppColors.warning,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text('$unapproved Team members pending approval.'),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Recent Tasks Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          tasksAsync.when(
            data: (tasks) => tasks.isEmpty
                ? const Text('No tasks created yet.')
                : Column(
                    children: tasks
                        .take(5)
                        .map(
                          (t) => Card(
                            child: ListTile(
                              title: Text(t.title),
                              subtitle: Text('Status: ${t.status}'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _TeamTab extends ConsumerWidget {
  const _TeamTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Team',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final team = users.where((u) => u.isTeam).toList();
                if (team.isEmpty)
                  return const Center(child: Text('No team members found.'));
                return ListView.builder(
                  itemCount: team.length,
                  itemBuilder: (c, i) => _TeamMemberTile(user: team[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberTile extends ConsumerWidget {
  final UserModel user;
  const _TeamMemberTile({required this.user});

  Future<void> _updateApproval(WidgetRef ref, bool approved) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('users').update({'approved': approved}).eq('id', user.id);
  }

  Future<void> _delete(WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('users').delete().eq('id', user.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!user.approved)
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.success),
                onPressed: () => _updateApproval(ref, true),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _delete(ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTab extends ConsumerWidget {
  const _TaskTab();

  Future<void> _deleteTask(WidgetRef ref, String id) async {
    await ref.read(supabaseClientProvider).from('tasks').delete().eq('id', id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Tasks',
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
                  child: ListTile(
                    title: Text(tasks[i].title),
                    subtitle: Text(
                      '${tasks[i].status.toUpperCase()} • ${tasks[i].assignedTo != null ? 'Assigned' : 'Unassigned'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => _deleteTask(ref, tasks[i].id),
                    ),
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
