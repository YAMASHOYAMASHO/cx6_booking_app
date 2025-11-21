import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../viewmodels/reservation_viewmodel.dart';

/// 月カレンダー
class MonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const MonthCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDate,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        onDateSelected(selectedDay);
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue[200],
          shape: BoxShape.circle,
        ),
      ),
      locale: 'ja_JP',
    );
  }
}

/// 日付ナビゲーションボタン
class DateNavigationButtons extends ConsumerWidget {
  const DateNavigationButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: () {
              final current = ref.read(selectedDateProvider);
              ref.read(selectedDateProvider.notifier).state = current.subtract(
                const Duration(days: 1),
              );
            },
            child: const Text('< 前の日'),
          ),
          TextButton(
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = DateTime.now();
            },
            child: const Text('今日'),
          ),
          TextButton(
            onPressed: () {
              final current = ref.read(selectedDateProvider);
              ref.read(selectedDateProvider.notifier).state = current.add(
                const Duration(days: 1),
              );
            },
            child: const Text('次の日 >'),
          ),
        ],
      ),
    );
  }
}
