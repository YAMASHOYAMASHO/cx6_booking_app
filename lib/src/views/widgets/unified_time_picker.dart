import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnifiedTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  const UnifiedTimePicker({
    super.key,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<UnifiedTimePicker> createState() => _UnifiedTimePickerState();
}

class _UnifiedTimePickerState extends State<UnifiedTimePicker> {
  late TimeOfDay _time;
  bool _isDropdownMode = true;

  // Controllers for text fields
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _hourController = TextEditingController(
      text: _time.hour.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: _time.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void didUpdateWidget(UnifiedTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTime != oldWidget.initialTime) {
      _time = widget.initialTime;
      // Only update text if not focused to avoid interrupting typing?
      // For simplicity, we update if the parent changes it.
      // But usually parent changes it based on our callback.
      // To avoid cursor jumping, we might want to be careful.
      // However, since we use local state for immediate updates, we might not need to force update from parent unless it's a completely external change.
      // Let's keep it simple: sync if different.
      if (_hourController.text != _time.hour.toString().padLeft(2, '0')) {
        _hourController.text = _time.hour.toString().padLeft(2, '0');
      }
      if (_minuteController.text != _time.minute.toString().padLeft(2, '0')) {
        _minuteController.text = _time.minute.toString().padLeft(2, '0');
      }
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateTime(int newHour, int newMinute) {
    final newTime = TimeOfDay(hour: newHour, minute: newMinute);
    setState(() {
      _time = newTime;
      // Update text controllers if we are not typing in them (e.g. dropdown change)
      // Or just always keep them in sync
      _hourController.text = newHour.toString().padLeft(2, '0');
      _minuteController.text = newMinute.toString().padLeft(2, '0');
    });
    widget.onChanged(newTime);
  }

  void _onHourChanged(String value) {
    if (value.isEmpty) return;
    final int? newHour = int.tryParse(value);
    if (newHour != null && newHour >= 0 && newHour < 24) {
      _updateTime(newHour, _time.minute);
    }
  }

  void _onMinuteChanged(String value) {
    if (value.isEmpty) return;
    final int? newMinute = int.tryParse(value);
    if (newMinute != null && newMinute >= 0 && newMinute < 60) {
      _updateTime(_time.hour, newMinute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isDropdownMode) _buildDropdownMode() else _buildInputMode(),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _isDropdownMode = !_isDropdownMode;
              });
            },
            icon: Icon(
              _isDropdownMode ? Icons.keyboard : Icons.arrow_drop_down_circle,
              size: 16,
            ),
            label: Text(
              _isDropdownMode ? 'キーボード入力に切り替え' : 'リスト選択に切り替え',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputMode() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(
          controller: _hourController,
          onChanged: _onHourChanged,
          max: 23,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            ':',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTextField(
          controller: _minuteController,
          onChanged: _onMinuteChanged,
          max: 59,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required int max,
  }) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          _RangeTextInputFormatter(max: max),
        ],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        onChanged: onChanged,
        onSubmitted: (value) {
          // Ensure 2 digits on submit
          if (value.isNotEmpty) {
            final int val = int.parse(value);
            controller.text = val.toString().padLeft(2, '0');
          }
        },
      ),
    );
  }

  Widget _buildDropdownMode() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDropdown(
          value: _time.hour,
          items: List.generate(24, (i) => i),
          onChanged: (val) => _updateTime(val!, _time.minute),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            ':',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildDropdown(
          value: _time.minute,
          items: List.generate(60, (i) => i),
          onChanged: (val) => _updateTime(_time.hour, val!),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<int>(
        value: value,
        underline: const SizedBox(), // Remove default underline
        items: items.map((i) {
          return DropdownMenuItem(
            value: i,
            child: Text(i.toString().padLeft(2, '0')),
          );
        }).toList(),
        onChanged: onChanged,
        menuMaxHeight: 300,
      ),
    );
  }
}

class _RangeTextInputFormatter extends TextInputFormatter {
  final int max;

  _RangeTextInputFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }

    return newValue;
  }
}
