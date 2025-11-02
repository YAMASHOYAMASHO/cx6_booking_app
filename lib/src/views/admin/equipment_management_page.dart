import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/equipment.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';
import 'equipment_form_dialog.dart';
import 'location_form_dialog.dart';

/// 装置管理画面
class EquipmentManagementPage extends ConsumerWidget {
  const EquipmentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(equipmentsProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('装置管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const LocationFormDialog(),
              );
            },
            tooltip: '場所を追加',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const EquipmentFormDialog(),
              );
            },
            tooltip: '装置を追加',
          ),
        ],
      ),
      body: equipmentsAsync.when(
        data: (equipments) {
          if (equipments.isEmpty) {
            return const Center(child: Text('装置が登録されていません'));
          }

          return locationsAsync.when(
            data: (locations) {
              // 場所IDから場所名へのマップを作成
              final locationMap = {
                for (var location in locations) location.id: location.name,
              };

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: equipments.length,
                itemBuilder: (context, index) {
                  final equipment = equipments[index];
                  final locationName =
                      locationMap[equipment.locationId] ?? '不明';

                  return _EquipmentCard(
                    equipment: equipment,
                    locationName: locationName,
                    onEdit: () async {
                      await showDialog(
                        context: context,
                        builder: (context) =>
                            EquipmentFormDialog(equipment: equipment),
                      );
                    },
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('装置を削除'),
                          content: Text('${equipment.name}を削除しますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                '削除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref
                            .read(equipmentViewModelProvider.notifier)
                            .deleteEquipment(equipment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('装置を削除しました')),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('エラー: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}

/// 装置カード
class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final String locationName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EquipmentCard({
    required this.equipment,
    required this.locationName,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return '利用可能';
      case 'maintenance':
        return 'メンテナンス中';
      case 'unavailable':
        return '使用停止';
      default:
        return '不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locationName,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(equipment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(equipment.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (equipment.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(equipment.description),
            ],
            if (equipment.specifications != null &&
                equipment.specifications!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '仕様: ${equipment.specifications}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('削除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
