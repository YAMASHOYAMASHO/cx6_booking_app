import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/location.dart';
import '../../viewmodels/location_viewmodel.dart';

/// 場所作成・編集フォームダイアログ
class LocationFormDialog extends ConsumerStatefulWidget {
  final Location? location;

  const LocationFormDialog({super.key, this.location});

  @override
  ConsumerState<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends ConsumerState<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? '場所を追加' : '場所を編集'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '場所名',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '場所名を入力してください';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _saveLocation, child: const Text('保存')),
      ],
    );
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (widget.location == null) {
        // 新規作成
        final newLocation = Location(
          id: '', // Firestoreが自動生成
          name: _nameController.text.trim(),
          createdAt: DateTime.now(),
        );
        await ref
            .read(locationViewModelProvider.notifier)
            .addLocation(newLocation);
      } else {
        // 更新
        final updatedLocation = widget.location!.copyWith(
          name: _nameController.text.trim(),
        );
        await ref
            .read(locationViewModelProvider.notifier)
            .updateLocation(updatedLocation);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.location == null ? '場所を追加しました' : '場所を更新しました'),
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
