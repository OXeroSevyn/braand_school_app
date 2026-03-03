import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import 'auth_provider.dart';

// Stream of all users (Realtime)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('users')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => UserModel.fromJson(e)).toList());
});

// Stream of all tasks (Realtime)
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('tasks')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => TaskModel.fromJson(e)).toList());
});

// Helper provider for users pending approval
final pendingUsersProvider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(allUsersProvider).value ?? [];
  return users.where((u) => !u.approved && !u.isSuperAdmin).toList();
});
