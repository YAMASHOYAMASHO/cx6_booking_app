import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../config/auth_config.dart';

/// プロフィール設定カード
class ProfileCard extends ConsumerStatefulWidget {
  final dynamic user;

  const ProfileCard({super.key, required this.user});

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  final _nameController = TextEditingController();
  final _colorCodeController = TextEditingController();
  Color _selectedColor = Colors.blue;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    if (widget.user.myColor != null) {
      _selectedColor = _parseColor(widget.user.myColor!);
      _colorCodeController.text = widget.user.myColor!;
    } else {
      _colorCodeController.text = _colorToHex(Colors.blue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorCodeController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('カラーを選択'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                  _colorCodeController.text = _colorToHex(tempColor);
                });
                Navigator.of(context).pop();
              },
              child: const Text('選択'),
            ),
          ],
        );
      },
    );
  }

  void _updateColorFromCode(String hexCode) {
    try {
      final color = _parseColor(hexCode);
      setState(() {
        _selectedColor = color;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無効なカラーコードです')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'プロフィール設定',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ユーザーID（読み取り専用）
            Text('ユーザーID', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              AuthConfig.emailToUserId(widget.user.email),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'メールアドレス: ${widget.user.email}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // 名前
            Text('名前', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            if (_isEditing)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '名前を入力',
                ),
              )
            else
              Text(widget.user.name, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // マイカラー
            Text('マイカラー', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                ),
                const SizedBox(width: 16),
                if (_isEditing) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showColorPicker,
                          icon: const Icon(Icons.palette),
                          label: const Text('カラーピッカーで選択'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _colorCodeController,
                          decoration: InputDecoration(
                            labelText: 'カラーコード',
                            hintText: '#FF5733',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                _updateColorFromCode(_colorCodeController.text);
                              },
                            ),
                          ),
                          onSubmitted: _updateColorFromCode,
                        ),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    _colorToHex(_selectedColor),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _nameController.text = widget.user.name;
                        if (widget.user.myColor != null) {
                          _selectedColor = _parseColor(widget.user.myColor!);
                          _colorCodeController.text = widget.user.myColor!;
                        }
                        _isEditing = false;
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(authViewModelProvider.notifier)
                                .updateUserProfile(
                                  userId: widget.user.id,
                                  name: _nameController.text.trim(),
                                  myColor: _colorToHex(_selectedColor),
                                );

                            if (mounted) {
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('プロフィールを更新しました')),
                              );
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
