import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_users_cubit.dart';
import '../../widgets/common_widgets.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminUsersCubit>().loadUsers();
  }

  void _updateRole(UserModel user) {
    String currentRole = user.roles.isNotEmpty ? user.roles.first : 'User';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              leading: Radio<String>(
                value: 'Admin',
                groupValue: currentRole,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  if (val != null) context.read<AdminUsersCubit>().updateUserRole(user.id, val);
                },
              ),
            ),
            ListTile(
              title: const Text('User'),
              leading: Radio<String>(
                value: 'User',
                groupValue: currentRole,
                onChanged: (val) {
                  Navigator.pop(ctx);
                  if (val != null) context.read<AdminUsersCubit>().updateUserRole(user.id, val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _lockUnlock(UserModel user) {
    context.read<AdminUsersCubit>().lockUnlockUser(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AdminUsersCubit, AdminUsersState>(
        listener: (context, state) {
          if (state is AdminUserOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AdminUsersError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Users Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<AdminUsersCubit>().loadUsers(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
                  builder: (context, state) {
                    List<UserModel>? users;
                    bool isLoading = false;

                    if (state is AdminUsersLoading) {
                      users = state.previousUsers;
                      isLoading = true;
                    } else if (state is AdminUsersLoaded) {
                      users = state.users;
                    }

                    if (users == null && isLoading) {
                      return const ShimmerLoader(count: 6);
                    }

                    if (users == null || users.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'No Users Found',
                        subtitle: 'Registered users will be listed here.',
                        onRetry: () => context.read<AdminUsersCubit>().loadUsers(),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users![index];
                            final role = user.roles.isNotEmpty ? user.roles.first : 'User';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(user.initials, style: const TextStyle(color: AppColors.primary)),
                                ),
                                title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${user.email}\nRole: $role'),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'role') {
                                      _updateRole(user);
                                    } else if (action == 'lock') {
                                      _lockUnlock(user);
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(value: 'role', child: Text('Update Role')),
                                    PopupMenuItem(value: 'lock', child: Text('Lock / Unlock')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (isLoading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
