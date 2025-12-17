import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'equipment_management_page.dart';
import 'reservation_management_page.dart';
import 'allowed_users_page.dart';
import 'user_management_page.dart';

/// 管理者メニュー画面
class AdminMenuPage extends ConsumerWidget {
  const AdminMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      data: (user) {
        if (user == null || !user.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('管理者メニュー')),
            body: const Center(child: Text('管理者権限がありません')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('管理者メニュー'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authViewModelProvider.notifier).signOut();
                },
                tooltip: 'ログアウト',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5, // カードの縦横比（1.0で正方形、1.2で横長）
              children: [
                _MenuCard(
                  title: '装置管理',
                  icon: Icons.precision_manufacturing,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EquipmentManagementPage(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  title: '予約管理',
                  icon: Icons.calendar_today,
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ReservationManagementPage(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  title: '事前登録管理',
                  icon: Icons.how_to_reg,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllowedUsersPage(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  title: 'ユーザー管理',
                  icon: Icons.people,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UserManagementPage(),
                      ),
                    );
                  },
                ),
                _MenuCard(
                  title: '統計情報',
                  icon: Icons.bar_chart,
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('今後実装予定')));
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('管理者メニュー')),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }
}

/// メニューカード
class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
