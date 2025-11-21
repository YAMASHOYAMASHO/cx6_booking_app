import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/favorite_equipment.dart';
import '../../viewmodels/favorite_equipment_viewmodel.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';

/// お気に入り装置セクション
class FavoriteEquipmentsSection extends ConsumerWidget {
  const FavoriteEquipmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteDetailsAsync = ref.watch(favoriteEquipmentDetailsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'お気に入り装置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddFavoriteDialog(context, ref),
                  tooltip: '装置を追加',
                ),
              ],
            ),
            const SizedBox(height: 16),
            favoriteDetailsAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'お気に入り装置がありません\n右上の＋ボタンから追加できます',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (oldIndex, newIndex) {
                    // リストを再構築
                    final reorderedFavorites = List<FavoriteEquipment>.from(
                      favorites.map((d) => d.favorite),
                    );

                    // 要素を移動
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = reorderedFavorites.removeAt(oldIndex);
                    reorderedFavorites.insert(newIndex, item);

                    // ViewModelに通知
                    ref
                        .read(favoriteEquipmentViewModelProvider.notifier)
                        .reorder(reorderedFavorites);
                  },
                  children: favorites.map((detail) {
                    return ListTile(
                      key: ValueKey(detail.favorite.id),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(detail.favorite.equipmentName),
                      subtitle: Text(detail.favorite.locationName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('お気に入りから削除'),
                              content: Text(
                                '「${detail.favorite.equipmentName}」をお気に入りから削除しますか？',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('キャンセル'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
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
                                .read(
                                  favoriteEquipmentViewModelProvider.notifier,
                                )
                                .removeFavorite(detail.favorite.id);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('お気に入りから削除しました')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('エラー: $error'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFavoriteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AddFavoriteDialog(),
    );
  }
}

class _AddFavoriteDialog extends ConsumerStatefulWidget {
  const _AddFavoriteDialog();

  @override
  ConsumerState<_AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends ConsumerState<_AddFavoriteDialog> {
  String? _selectedLocationId;
  String? _selectedEquipmentId;

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    return AlertDialog(
      title: const Text('お気に入り装置を追加'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 部屋選択
          locationsAsync.when(
            data: (locations) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: '部屋'),
                value: _selectedLocationId,
                items: locations.map((loc) {
                  return DropdownMenuItem(value: loc.id, child: Text(loc.name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocationId = value;
                    _selectedEquipmentId = null; // 部屋が変わったら装置選択をリセット
                  });
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('エラー: $e'),
          ),
          const SizedBox(height: 16),
          // 装置選択
          if (_selectedLocationId != null)
            Consumer(
              builder: (context, ref, child) {
                final equipmentsAsync = ref.watch(
                  equipmentsByLocationProvider(_selectedLocationId!),
                );

                return equipmentsAsync.when(
                  data: (equipments) {
                    if (equipments.isEmpty) {
                      return const Text('この部屋には装置がありません');
                    }
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '装置'),
                      value: _selectedEquipmentId,
                      items: equipments.map((eq) {
                        return DropdownMenuItem(
                          value: eq.id,
                          child: Text(eq.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipmentId = value;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('エラー: $e'),
                );
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedEquipmentId == null
              ? null
              : () async {
                  final equipments = ref.read(equipmentsProvider).value;
                  final equipment = equipments?.firstWhere(
                    (e) => e.id == _selectedEquipmentId,
                    orElse: () => throw Exception('装置が見つかりません'),
                  );

                  if (equipment != null) {
                    await ref
                        .read(favoriteEquipmentViewModelProvider.notifier)
                        .addFavorite(equipment);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('お気に入りに追加しました')),
                    );
                  }
                },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
