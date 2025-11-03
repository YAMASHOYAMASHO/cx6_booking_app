import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_reservation_template.dart';
import '../models/reservation_slot.dart';
import '../models/equipment.dart';
import '../viewmodels/favorite_reservation_template_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart';
import '../viewmodels/location_viewmodel.dart';

/// テンプレート編集ページ
class TemplateEditPage extends ConsumerStatefulWidget {
  final String? templateId; // nullの場合は新規作成

  const TemplateEditPage({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends ConsumerState<TemplateEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ReservationSlot> _slots = [];

  bool _isLoading = false;
  FavoriteReservationTemplate? _originalTemplate;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    if (widget.templateId == null) return;

    setState(() => _isLoading = true);

    try {
      final template = await ref.read(
        favoriteReservationTemplateProvider(widget.templateId!).future,
      );

      if (template != null) {
        _originalTemplate = template;
        _nameController.text = template.name;
        _descriptionController.text = template.description ?? '';
        _slots.addAll(template.slots);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_slots.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('少なくとも1つの予約スロットを追加してください')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = ref.read(
        favoriteReservationTemplateViewModelProvider.notifier,
      );

      if (widget.templateId == null) {
        // 新規作成
        final template = FavoriteReservationTemplate(
          id: '', // Firestoreが生成
          userId: '', // ViewModelで設定
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          slots: _slots,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await viewModel.createTemplate(template);
      } else {
        // 更新
        final template = _originalTemplate!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          slots: _slots,
          updatedAt: DateTime.now(),
        );

        await viewModel.updateTemplate(template);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // 保存成功を通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.templateId == null ? 'テンプレートを作成しました' : 'テンプレートを更新しました',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addSlot() {
    showDialog(
      context: context,
      builder: (context) => _SlotEditDialog(
        onSave: (slot) {
          setState(() {
            _slots.add(slot);
          });
        },
      ),
    );
  }

  void _editSlot(int index) {
    showDialog(
      context: context,
      builder: (context) => _SlotEditDialog(
        initialSlot: _slots[index],
        onSave: (slot) {
          setState(() {
            _slots[index] = slot;
          });
        },
      ),
    );
  }

  void _deleteSlot(int index) {
    setState(() {
      _slots.removeAt(index);
    });
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.templateId == null ? 'テンプレート新規作成' : 'テンプレート編集'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              onPressed: _saveTemplate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // テンプレート名
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'テンプレート名',
                        border: OutlineInputBorder(),
                        hintText: '例: 週次実験スケジュール',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'テンプレート名を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 説明
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '説明（任意）',
                        border: OutlineInputBorder(),
                        hintText: 'このテンプレートの説明を入力',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // スロット一覧
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '予約スロット',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('スロット追加'),
                          onPressed: _addSlot,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_slots.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'スロットがありません\n「スロット追加」から予約を追加してください',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_slots.length, (index) {
                        final slot = _slots[index];
                        final startTimeStr = _timeOfDayToString(slot.startTime);
                        final endTimeStr = _timeOfDayToString(slot.endTime);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(slot.equipmentName),
                            subtitle: Text(
                              '${slot.dayOffset >= 0 ? '+' : ''}${slot.dayOffset}日目 '
                              '$startTimeStr - $endTimeStr'
                              '${slot.note != null && slot.note!.isNotEmpty ? '\n${slot.note}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editSlot(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteSlot(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

/// スロット編集ダイアログ
class _SlotEditDialog extends ConsumerStatefulWidget {
  final ReservationSlot? initialSlot;
  final Function(ReservationSlot) onSave;

  const _SlotEditDialog({this.initialSlot, required this.onSave});

  @override
  ConsumerState<_SlotEditDialog> createState() => _SlotEditDialogState();
}

class _SlotEditDialogState extends ConsumerState<_SlotEditDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedLocationId;
  Equipment? _selectedEquipment;
  int _dayOffset = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialSlot != null) {
      final slot = widget.initialSlot!;
      _dayOffset = slot.dayOffset;
      _startTime = slot.startTime;
      _endTime = slot.endTime;
      _noteController.text = slot.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('装置を選択してください')));
      return;
    }

    // 時間の妥当性チェック
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')));
      return;
    }

    final slot = ReservationSlot(
      equipmentId: _selectedEquipment!.id,
      equipmentName: _selectedEquipment!.name,
      dayOffset: _dayOffset,
      startTime: _startTime,
      endTime: _endTime,
      note: _noteController.text.trim(),
      order: 0, // 後で設定
    );

    widget.onSave(slot);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final equipmentsAsync = ref.watch(equipmentsProvider);

    return AlertDialog(
      title: Text(widget.initialSlot == null ? 'スロット追加' : 'スロット編集'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ロケーション選択
                const Text(
                  'ロケーション',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                locationsAsync.when(
                  data: (locations) {
                    return DropdownButtonFormField<String>(
                      value: _selectedLocationId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'ロケーションを選択',
                      ),
                      items: locations
                          .map(
                            (location) => DropdownMenuItem(
                              value: location.id,
                              child: Text(location.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocationId = value;
                          _selectedEquipment = null; // 装置選択をリセット
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => SelectableText(
                    'エラー: $error',
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 装置選択
                const Text('装置', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_selectedLocationId == null)
                  const Text(
                    'まずロケーションを選択してください',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  equipmentsAsync.when(
                    data: (equipments) {
                      final filteredEquipments = equipments
                          .where((e) => e.locationId == _selectedLocationId)
                          .toList();

                      if (filteredEquipments.isEmpty) {
                        return const Text(
                          'このロケーションには装置がありません',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return DropdownButtonFormField<Equipment>(
                        value: _selectedEquipment,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '装置を選択',
                        ),
                        items: filteredEquipments
                            .map(
                              (equipment) => DropdownMenuItem(
                                value: equipment,
                                child: Text(equipment.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEquipment = value;
                          });
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => SelectableText(
                      'エラー: $error',
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 日付オフセット
                const Text(
                  '基準日からの日数',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _dayOffset.toDouble(),
                        min: -30,
                        max: 30,
                        divisions: 60,
                        label: '${_dayOffset >= 0 ? '+' : ''}$_dayOffset日',
                        onChanged: (value) {
                          setState(() {
                            _dayOffset = value.toInt();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${_dayOffset >= 0 ? '+' : ''}$_dayOffset日',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 開始時刻
                const Text(
                  '開始時刻',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickTime(true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_timeOfDayToString(_startTime)),
                  ),
                ),
                const SizedBox(height: 16),

                // 終了時刻
                const Text(
                  '終了時刻',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickTime(false),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_timeOfDayToString(_endTime)),
                  ),
                ),
                const SizedBox(height: 16),

                // メモ
                const Text(
                  'メモ（任意）',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'メモを入力',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}
