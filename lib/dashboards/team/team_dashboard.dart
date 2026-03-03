import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task_model.dart';

class TeamDashboard extends ConsumerStatefulWidget {
  const TeamDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<TeamDashboard> createState() => _TeamDashboardState();
}

class _TeamDashboardState extends ConsumerState<TeamDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const _MyTasksTab(), const _ProfileTab()];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (v) => setState(() => _currentIndex = v),
        backgroundColor: AppColors.card,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'My Tasks',
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

class _MyTasksTab extends ConsumerWidget {
  const _MyTasksTab();

  Future<void> _updateTaskStatus(
    WidgetRef ref,
    String taskId,
    String newStatus,
    String? comment,
  ) async {
    final updateData = {'status': newStatus};
    if (comment != null && comment.isNotEmpty) {
      updateData['comments'] = comment;
    }
    await ref
        .read(supabaseClientProvider)
        .from('tasks')
        .update(updateData)
        .eq('id', taskId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);
    final user = ref.watch(currentUserProvider).value;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.name ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'My Tasks',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                // Team members only see their assigned tasks
                final myTasks = tasks.toList();
                if (myTasks.isEmpty)
                  return const Center(child: Text('No assigned tasks.'));

                return ListView.builder(
                  itemCount: myTasks.length,
                  itemBuilder: (c, i) => _TaskCard(
                    task: myTasks[i],
                    onUpdateStatus: (s, c) =>
                        _updateTaskStatus(ref, myTasks[i].id, s, c),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(String, String?) onUpdateStatus;

  const _TaskCard({required this.task, required this.onUpdateStatus});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  final _commentController = TextEditingController();

  void _showActionDialog(String nextStatus, String actionLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionLabel),
        content: TextField(
          controller: _commentController,
          decoration: const InputDecoration(labelText: 'Optional Comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUpdateStatus(nextStatus, _commentController.text);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.textSecondary;
    if (widget.task.status == 'in_progress') statusColor = AppColors.warning;
    if (widget.task.status == 'completed') statusColor = AppColors.success;
    if (widget.task.status == 'accepted') statusColor = AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    widget.task.status.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.task.description != null &&
                widget.task.description!.isNotEmpty)
              Text(widget.task.description!),
            if (widget.task.comments != null &&
                widget.task.comments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Comment: ${widget.task.comments}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (widget.task.status == 'pending')
                  ElevatedButton(
                    onPressed: () => widget.onUpdateStatus('accepted', null),
                    child: const Text('Accept'),
                  ),
                if (widget.task.status == 'accepted')
                  ElevatedButton(
                    onPressed: () => widget.onUpdateStatus('in_progress', null),
                    child: const Text('Start Progress'),
                  ),
                if (widget.task.status == 'in_progress')
                  ElevatedButton(
                    onPressed: () =>
                        _showActionDialog('completed', 'Complete Task'),
                    child: const Text('Mark Completed'),
                  ),
              ],
            ),
          ],
        ),
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
