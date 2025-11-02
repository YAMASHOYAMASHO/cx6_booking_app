import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/equipment.dart';
import '../../models/location.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';
import 'location_form_dialog.dart';

/// 装置作成・編集フォームダイアログ
class EquipmentFormDialog extends ConsumerStatefulWidget {
  final Equipment? equipment;

  const EquipmentFormDialog({super.key, this.equipment});

  @override
  ConsumerState<EquipmentFormDialog> createState() =>
      _EquipmentFormDialogState();
}

class _EquipmentFormDialogState extends ConsumerState<EquipmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _specificationsController;
  String? _selectedLocationId;
  String _selectedStatus = 'available';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.equipment?.description ?? '',
    );
    _specificationsController = TextEditingController(
      text: widget.equipment?.specifications ?? '',
    );
    _selectedLocationId = widget.equipment?.locationId;
    _selectedStatus = widget.equipment?.status ?? 'available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _specificationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.equipment == null ? '装置を追加' : '装置を編集',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 装置名
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '装置名 *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '装置名を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // 場所選択
                  locationsAsync.when(
                    data: (locations) {
                      if (locations.isEmpty) {
                        return const Text('場所が登録されていません');
                      }

                      // 有効なIDを持つ場所のみフィルタリングし、重複を除去
                      final validLocations = locations
                          .where((loc) => loc.id.isNotEmpty)
                          .toList();

                      // IDで重複を除去（念のため）
                      final uniqueLocationsMap = <String, Location>{};
                      for (var location in validLocations) {
                        uniqueLocationsMap[location.id] = location;
                      }
                      final uniqueLocations = uniqueLocationsMap.values
                          .toList();

                      // 選択中のIDが有効かチェック
                      if (_selectedLocationId != null &&
                          !uniqueLocationsMap.containsKey(
                            _selectedLocationId,
                          )) {
                        _selectedLocationId = null;
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedLocationId,
                              decoration: const InputDecoration(
                                labelText: '場所 *',
                                border: OutlineInputBorder(),
                              ),
                              items: uniqueLocations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location.id,
                                  child: Text(location.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocationId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return '場所を選択してください';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_location),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (context) =>
                                    const LocationFormDialog(),
                              );
                            },
                            tooltip: '場所を追加',
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('エラー: $error'),
                  ),
                  const SizedBox(height: 16),
                  // メモ
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'メモ (任意)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // 仕様
                  TextFormField(
                    controller: _specificationsController,
                    decoration: const InputDecoration(
                      labelText: '仕様 (任意)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // ステータス
                  const Text(
                    'ステータス',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusButton(
                        label: '利用可能',
                        value: 'available',
                        selected: _selectedStatus == 'available',
                        color: Colors.green,
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'available';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusButton(
                        label: 'メンテナンス中',
                        value: 'maintenance',
                        selected: _selectedStatus == 'maintenance',
                        color: Colors.orange,
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'maintenance';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _StatusButton(
                        label: '使用停止',
                        value: 'unavailable',
                        selected: _selectedStatus == 'unavailable',
                        color: Colors.red,
                        onTap: () {
                          setState(() {
                            _selectedStatus = 'unavailable';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveEquipment,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (widget.equipment == null) {
        // 新規作成
        final newEquipment = Equipment(
          id: '', // Firestoreが自動生成
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _selectedLocationId!,
          status: _selectedStatus,
          specifications: _specificationsController.text.trim().isEmpty
              ? null
              : _specificationsController.text.trim(),
          createdAt: DateTime.now(),
        );
        await ref
            .read(equipmentViewModelProvider.notifier)
            .addEquipment(newEquipment);
      } else {
        // 更新
        final updatedEquipment = widget.equipment!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _selectedLocationId,
          status: _selectedStatus,
          specifications: _specificationsController.text.trim().isEmpty
              ? null
              : _specificationsController.text.trim(),
        );
        await ref
            .read(equipmentViewModelProvider.notifier)
            .updateEquipment(updatedEquipment);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.equipment == null ? '装置を追加しました' : '装置を更新しました'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('エラー'),
            content: SelectableText(
              e.toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }
}

/// ステータスボタン
class _StatusButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
