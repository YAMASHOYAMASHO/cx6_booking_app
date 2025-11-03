import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/equipment_viewmodel.dart';

/// 装置選択ドロップダウンウィジェット
class EquipmentSelector extends ConsumerWidget {
  final String? locationId;
  final String? selectedEquipmentId;
  final ValueChanged<String?> onEquipmentChanged;
  final String? hintText;

  const EquipmentSelector({
    super.key,
    required this.locationId,
    this.selectedEquipmentId,
    required this.onEquipmentChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 部屋が選択されていない場合
    if (locationId == null || locationId!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.precision_manufacturing, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              '先に部屋を選択してください',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final equipmentsAsync = ref.watch(
      equipmentsByLocationProvider(locationId!),
    );

    return equipmentsAsync.when(
      data: (equipments) {
        if (equipments.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.precision_manufacturing,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                const Text('装置がありません'),
              ],
            ),
          );
        }

        // 選択されている装置が現在の部屋の装置リストに含まれていない場合はクリア
        if (selectedEquipmentId != null &&
            !equipments.any((e) => e.id == selectedEquipmentId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onEquipmentChanged(null);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Row(
              children: [
                const Icon(Icons.precision_manufacturing, size: 20),
                const SizedBox(width: 8),
                Text(hintText ?? '装置を選択'),
              ],
            ),
            value: selectedEquipmentId,
            items: equipments.map((equipment) {
              return DropdownMenuItem(
                value: equipment.id,
                child: Row(
                  children: [
                    const Icon(Icons.precision_manufacturing, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(equipment.name)),
                  ],
                ),
              );
            }).toList(),
            onChanged: onEquipmentChanged,
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('装置を読み込み中...'),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'エラー: ${error.toString()}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
