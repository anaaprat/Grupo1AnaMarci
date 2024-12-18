import 'package:eventify/services/admin_service.dart';
import 'package:eventify/screens/editUser_screen.dart';
import 'package:eventify/screens/login_screen.dart';
import 'package:eventify/widgets/user_card.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  final String token;

  const AdminScreen({super.key, required this.token});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _users = [];
  late AdminService adminService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    adminService = AdminService(token: widget.token);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await adminService.getUsers();
      print('$users');
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Failed to load users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await _showConfirmationDialog(
      'Wait',
      'Are you sure you want to logout?',
    );

    if (shouldLogout == true) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmLogout,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Others'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Primera pestaña: Users
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Dismissible(
                        key: ValueKey(user.id),
                        background: _buildDismissBackground(true, user.actived),
                        secondaryBackground:
                            _buildDismissBackground(false, user.actived),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            final confirmation = await _showConfirmationDialog(
                              'Confirm Deletion',
                              'Are you sure you want to delete ${user.name}?',
                            );

                            if (confirmation == true) {
                              try {
                                final success =
                                    await adminService.deleteUser(user.id);

                                if (success) {
                                  setState(() {
                                    _users.removeAt(index);
                                  });
                                  _showSnackBar(
                                      'User ${user.name} deleted successfully');
                                } else {
                                  throw Exception('Failed to delete user.');
                                }
                              } catch (e) {
                                _showSnackBar(e.toString());
                              }
                            }
                            return confirmation ?? false;
                          } else if (direction == DismissDirection.startToEnd) {
                            final confirmation = await _showConfirmationDialog(
                              user.actived ? 'Deactivate' : 'Activate',
                              'Are you sure you want to ${user.actived ? 'deactivate' : 'activate'} ${user.name}?',
                            );

                            if (confirmation == true) {
                              try {
                                bool success;

                                if (user.actived) {
                                  success = await adminService
                                      .deactivateUser(user.id);
                                } else {
                                  success =
                                      await adminService.activateUser(user.id);
                                }

                                if (success) {
                                  setState(() {
                                    user.actived = !user
                                        .actived; // Cambia el estado del usuario
                                  });
                                  _showSnackBar(
                                      'User ${user.actived ? 'activated' : 'deactivated'} successfully');
                                } else {
                                  throw Exception(
                                      'Failed to update user status.');
                                }
                              } catch (e) {
                                _showSnackBar(
                                    'Failed to update user status: $e');
                              }
                            }
                            return false;
                          }
                          return false;
                        },
                        child: UserCard(
                          user: user,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditUserScreen(
                                  token: widget.token,
                                  userId: user.id,
                                  currentName: user.name,
                                ),
                              ),
                            );
                            if (result == true) {
                              await _loadUsers();
                            }
                          },
                        ),
                      );
                    },
                  ),
            // Segunda pestaña: Others (vacía por ahora)
            const Center(
              child: Text('No content available yet.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissBackground(bool isActivate, bool userActiveStatus) {
    final actionColor = isActivate
        ? (userActiveStatus ? Colors.orange : Colors.green)
        : Colors.red;
    final actionIcon = isActivate
        ? (userActiveStatus ? Icons.lock : Icons.lock_open)
        : Icons.delete;
    final actionText =
        isActivate ? (userActiveStatus ? 'Deactivate' : 'Activate') : 'Delete';

    return Container(
      color: actionColor,
      alignment: isActivate ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment:
            isActivate ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(actionIcon, color: Colors.white),
          const SizedBox(width: 8),
          Text(actionText, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
