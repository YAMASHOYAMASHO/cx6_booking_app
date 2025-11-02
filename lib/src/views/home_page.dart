import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/equipment.dart';
import '../models/location.dart';
import '../models/reservation.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/location_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart';
import '../viewmodels/reservation_viewmodel.dart';
import 'admin/admin_menu_page.dart';

/// エラー表示ウィジェット
class _ErrorDisplay extends StatelessWidget {
  final Object error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text(
                'エラーが発生しました',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              error.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// ホーム画面
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('装置予約システム'),
        actions: [
          // 管理者メニューボタン（管理者のみ表示）
          currentUser.whenOrNull(
                data: (user) {
                  if (user != null && user.isAdmin) {
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AdminMenuPage(),
                          ),
                        );
                      },
                      tooltip: '管理者メニュー',
                    );
                  }
                  return null;
                },
              ) ??
              const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // プロフィール画面へ遷移
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 左側: 部屋選択と月カレンダー
          SizedBox(
            width: 320,
            child: Column(
              children: [
                // 部屋選択
                const _LocationSelector(),
                // カレンダー
                Expanded(
                  child: _MonthCalendar(
                    selectedDate: selectedDate,
                    onDateSelected: (date) {
                      ref.read(selectedDateProvider.notifier).state = date;
                    },
                  ),
                ),
                // 前の日・今日・次の日ボタン
                _DateNavigationButtons(),
              ],
            ),
          ),
          // 右側: 日付表示とタイムライン
          Expanded(
            child: selectedLocation != null
                ? _TimelineView(
                    location: selectedLocation,
                    selectedDate: selectedDate,
                  )
                : const Center(child: Text('部屋を選択してください')),
          ),
        ],
      ),
    );
  }
}

/// 部屋選択ドロップダウン
class _LocationSelector extends ConsumerWidget {
  const _LocationSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

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

                // 初回自動選択
                if (selectedLocation == null && uniqueLocations.isNotEmpty) {
                  Future.microtask(() {
                    ref.read(selectedLocationProvider.notifier).state =
                        uniqueLocations.first;
                  });
                }

                return DropdownButton<Location>(
                  isExpanded: true,
                  value: selectedLocation,
                  items: uniqueLocations.map((location) {
                    return DropdownMenuItem<Location>(
                      value: location,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (location) {
                    ref.read(selectedLocationProvider.notifier).state =
                        location;
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => _ErrorDisplay(error: error),
            ),
          ),
        ],
      ),
    );
  }
}

/// 月カレンダー
class _MonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _MonthCalendar({
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
class _DateNavigationButtons extends ConsumerWidget {
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

/// タイムライン表示（横方向）
class _TimelineView extends ConsumerWidget {
  final Location location;
  final DateTime selectedDate;

  const _TimelineView({required this.location, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(
      equipmentsByLocationProvider(location.id),
    );
    final reservationsAsync = ref.watch(reservationsByDateProvider);
    final dateFormat = DateFormat('M月d日(E)', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示ヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'タイムラインをクリックして予約',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // タイムライン
        Expanded(
          child: equipmentsAsync.when(
            data: (equipments) {
              if (equipments.isEmpty) {
                return const Center(child: Text('この部屋には装置がありません'));
              }
              return reservationsAsync.when(
                data: (allReservations) {
                  return _HorizontalTimelineGrid(
                    equipments: equipments,
                    reservations: allReservations,
                    selectedDate: selectedDate,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: _ErrorDisplay(error: error)),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: _ErrorDisplay(error: error)),
          ),
        ),
      ],
    );
  }
}

/// 横方向タイムライングリッド
class _HorizontalTimelineGrid extends ConsumerWidget {
  final List<Equipment> equipments;
  final List<Reservation> reservations;
  final DateTime selectedDate;

  const _HorizontalTimelineGrid({
    required this.equipments,
    required this.reservations,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double hourWidth = 40.0; // 1時間あたり40px
    const double equipmentRowHeight = 60.0;
    const double timeHeaderHeight = 40.0;

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 24 * hourWidth + 120, // 24時間 + 装置名の幅
          child: Column(
            children: [
              // 時間軸ヘッダー
              _buildTimeHeader(hourWidth, timeHeaderHeight),
              // 装置ごとの行
              Expanded(
                child: ListView.builder(
                  itemCount: equipments.length,
                  itemBuilder: (context, index) {
                    final equipment = equipments[index];
                    final equipmentReservations = reservations
                        .where((r) => r.equipmentId == equipment.id)
                        .toList();
                    return _buildEquipmentRow(
                      context,
                      ref,
                      equipment,
                      equipmentReservations,
                      hourWidth,
                      equipmentRowHeight,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 時間軸ヘッダーを構築
  Widget _buildTimeHeader(double hourWidth, double headerHeight) {
    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // 装置名のスペース
          SizedBox(
            width: 120,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!),
                  bottom: BorderSide(color: Colors.grey[400]!),
                ),
                color: Colors.grey[100],
              ),
              child: const Center(
                child: Text(
                  '装置名',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // 時間表示
          ...List.generate(24, (hour) {
            return Container(
              width: hourWidth,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey[300]!,
                    width: hour % 6 == 0 ? 1.5 : 0.5,
                  ),
                  bottom: BorderSide(color: Colors.grey[400]!),
                ),
                color: Colors.grey[50],
              ),
              child: Center(
                child: Text(
                  hour.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: hour % 6 == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 装置の行を構築
  Widget _buildEquipmentRow(
    BuildContext context,
    WidgetRef ref,
    Equipment equipment,
    List<Reservation> equipmentReservations,
    double hourWidth,
    double rowHeight,
  ) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          // 装置名
          Container(
            width: 120,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: equipment.isAvailable ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    equipment.name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // タイムライングリッド
          Expanded(
            child: Stack(
              children: [
                // グリッド背景
                Row(
                  children: List.generate(24, (hour) {
                    return Container(
                      width: hourWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey[300]!,
                            width: hour % 6 == 0 ? 1.5 : 0.5,
                          ),
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    );
                  }),
                ),
                // 予約バー
                ...equipmentReservations.map((reservation) {
                  return _buildReservationBar(
                    context,
                    ref,
                    reservation,
                    hourWidth,
                    rowHeight,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 予約バーを構築
  Widget _buildReservationBar(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
    double hourWidth,
    double rowHeight,
  ) {
    final startHour =
        reservation.startTime.hour + reservation.startTime.minute / 60.0;
    final endHour =
        reservation.endTime.hour + reservation.endTime.minute / 60.0;
    final duration = endHour - startHour;

    final left = startHour * hourWidth;
    final width = duration * hourWidth;

    return Positioned(
      left: left,
      top: 4,
      width: width,
      height: rowHeight - 8,
      child: GestureDetector(
        onTap: () {
          _showReservationDialog(context, ref, reservation);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.blue, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reservation.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (width > 60 &&
                  reservation.note != null &&
                  reservation.note!.isNotEmpty)
                Text(
                  reservation.note!,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDialog(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) {
    final currentUser = ref.read(currentUserProvider).value;
    final canDelete =
        currentUser?.id == reservation.userId ||
        (currentUser?.isAdmin ?? false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('装置: ${reservation.equipmentName}'),
            Text('予約者: ${reservation.userName}'),
            Text(
              '時間: ${DateFormat('HH:mm').format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
            ),
            if (reservation.note != null && reservation.note!.isNotEmpty)
              Text('メモ: ${reservation.note}'),
          ],
        ),
        actions: [
          if (canDelete)
            TextButton(
              onPressed: () async {
                await ref
                    .read(reservationViewModelProvider.notifier)
                    .deleteReservation(reservation.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
