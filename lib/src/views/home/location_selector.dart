import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/location.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/favorite_equipment_viewmodel.dart';
import '../widgets/common/error_display.dart';

/// 部屋選択ドロップダウン
class LocationSelector extends ConsumerWidget {
  const LocationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);
    final favoriteMode = ref.watch(favoriteModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          const Icon(Icons.room, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('部屋:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return const Text('部屋がありません');
                }

                // 有効なIDを持つ場所のみフィルタリングし、重複を除去
                final validLocations = locations
                    .where((loc) => loc.id.isNotEmpty)
                    .toList();

                // IDで重複を除去
                final uniqueLocationsMap = <String, Location>{};
                for (var location in validLocations) {
                  uniqueLocationsMap[location.id] = location;
                }
                final uniqueLocations = uniqueLocationsMap.values.toList();

                // お気に入り用の特別なオプションを追加
                final displayItems = <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: 'FAVORITES',
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text('お気に入り'),
                      ],
                    ),
                  ),
                  ...uniqueLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }),
                ];

                // 現在の選択値を文字列として取得
                String? currentValue;
                if (favoriteMode) {
                  currentValue = 'FAVORITES';
                } else if (selectedLocation != null) {
                  currentValue = selectedLocation.id;
                }

                // 選択中のLocationがリストに存在するかチェック
                Location? validSelectedLocation = selectedLocation;
                if (selectedLocation != null && !favoriteMode) {
                  final exists = uniqueLocations.any(
                    (loc) => loc.id == selectedLocation.id,
                  );
                  if (!exists) {
                    validSelectedLocation = null;
                  }
                }

                // 初回自動選択または無効な選択をリセット
                if (!favoriteMode &&
                    validSelectedLocation == null &&
                    uniqueLocations.isNotEmpty) {
                  Future.microtask(() {
                    ref.read(selectedLocationProvider.notifier).state =
                        uniqueLocations.first;
                  });
                }

                return DropdownButton<String>(
                  isExpanded: true,
                  value: currentValue,
                  items: displayItems,
                  onChanged: (value) {
                    if (value == 'FAVORITES') {
                      // お気に入りモードをON
                      ref.read(favoriteModeProvider.notifier).state = true;
                      ref.read(selectedLocationProvider.notifier).state = null;
                    } else {
                      // 通常のロケーション選択
                      ref.read(favoriteModeProvider.notifier).state = false;
                      final location = uniqueLocations.firstWhere(
                        (loc) => loc.id == value,
                      );
                      ref.read(selectedLocationProvider.notifier).state =
                          location;
                    }
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => ErrorDisplay(error: error),
            ),
          ),
        ],
      ),
    );
  }
}
