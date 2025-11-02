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
import 'reservation_form_page.dart';
import 'my_page.dart';

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
    final authUser = ref.watch(authStateProvider);

    // 認証状態を確認
    return authUser.when(
      data: (user) {
        if (user == null) {
          // 未認証の場合（念のため）
          return const Scaffold(body: Center(child: Text('認証が必要です')));
        }

        // 認証済みの場合、メイン画面を表示
        return _buildMainScaffold(
          context,
          ref,
          selectedLocation,
          selectedDate,
          currentUser,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('認証エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authStateProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScaffold(
    BuildContext context,
    WidgetRef ref,
    Location? selectedLocation,
    DateTime selectedDate,
    AsyncValue currentUser,
  ) {
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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const MyPage()));
            },
            tooltip: 'マイページ',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).signOut();
            },
            tooltip: 'ログアウト',
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

                // 選択中のLocationがリストに存在するかチェック
                Location? validSelectedLocation = selectedLocation;
                if (selectedLocation != null) {
                  final exists = uniqueLocations.any(
                    (loc) => loc.id == selectedLocation.id,
                  );
                  if (!exists) {
                    validSelectedLocation = null;
                  }
                }

                // 初回自動選択または無効な選択をリセット
                if (validSelectedLocation == null &&
                    uniqueLocations.isNotEmpty) {
                  Future.microtask(() {
                    ref.read(selectedLocationProvider.notifier).state =
                        uniqueLocations.first;
                  });
                }

                return DropdownButton<Location>(
                  isExpanded: true,
                  value: validSelectedLocation,
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
class _HorizontalTimelineGrid extends ConsumerStatefulWidget {
  final List<Equipment> equipments;
  final List<Reservation> reservations;
  final DateTime selectedDate;

  const _HorizontalTimelineGrid({
    required this.equipments,
    required this.reservations,
    required this.selectedDate,
  });

  @override
  ConsumerState<_HorizontalTimelineGrid> createState() =>
      _HorizontalTimelineGridState();
}

class _HorizontalTimelineGridState
    extends ConsumerState<_HorizontalTimelineGrid> {
  Equipment? _dragTargetEquipment;
  double? _dragStartX;
  double? _dragCurrentX;

  @override
  Widget build(BuildContext context) {
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
                  itemCount: widget.equipments.length,
                  itemBuilder: (context, index) {
                    final equipment = widget.equipments[index];
                    final equipmentReservations = widget.reservations
                        .where((r) => r.equipmentId == equipment.id)
                        .toList();
                    return _buildEquipmentRow(
                      context,
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
    Equipment equipment,
    List<Reservation> equipmentReservations,
    double hourWidth,
    double rowHeight,
  ) {
    final isDragging =
        _dragTargetEquipment?.id == equipment.id && _dragStartX != null;

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
          // タイムライングリッド（ドラッグ可能）
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() {
                  _dragTargetEquipment = equipment;
                  _dragStartX = details.localPosition.dx;
                  _dragCurrentX = details.localPosition.dx;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragCurrentX = details.localPosition.dx;
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragStartX != null && _dragCurrentX != null) {
                  _handleDragEnd(context, equipment, hourWidth);
                }
                setState(() {
                  _dragTargetEquipment = null;
                  _dragStartX = null;
                  _dragCurrentX = null;
                });
              },
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
                      reservation,
                      hourWidth,
                      rowHeight,
                    );
                  }),
                  // ドラッグ中のプレビュー
                  if (isDragging &&
                      _dragStartX != null &&
                      _dragCurrentX != null)
                    _buildDragPreview(hourWidth, rowHeight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ドラッグプレビューを構築
  Widget _buildDragPreview(double hourWidth, double rowHeight) {
    final startX = _dragStartX!;
    final currentX = _dragCurrentX!;
    final left = startX < currentX ? startX : currentX;
    final width = (startX - currentX).abs();

    return Positioned(
      left: left,
      top: 4,
      width: width,
      height: rowHeight - 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          border: Border.all(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(child: Icon(Icons.add, color: Colors.blue)),
      ),
    );
  }

  /// ドラッグ終了時の処理
  void _handleDragEnd(
    BuildContext context,
    Equipment equipment,
    double hourWidth,
  ) {
    if (_dragStartX == null || _dragCurrentX == null) return;

    final startX = _dragStartX! < _dragCurrentX!
        ? _dragStartX!
        : _dragCurrentX!;
    final endX = _dragStartX! < _dragCurrentX! ? _dragCurrentX! : _dragStartX!;

    // 最小ドラッグ幅（0.5時間 = 30分）
    if (endX - startX < hourWidth * 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予約時間は最低30分必要です'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 時刻を計算（30分単位に丸める）
    final startHour = (startX / hourWidth * 2).round() / 2.0;
    final endHour = (endX / hourWidth * 2).round() / 2.0;

    // 時刻をDateTime型に変換（15分単位に調整）
    final startTotalMinutes = (startHour * 60).round();
    final endTotalMinutes = (endHour * 60).round();

    // 15分単位に丸める（0, 15, 30, 45のいずれか）
    final roundedStartMinutes = ((startTotalMinutes / 15).round() * 15);
    final roundedEndMinutes = ((endTotalMinutes / 15).round() * 15);

    // 時と分に分解
    final startHourInt = roundedStartMinutes ~/ 60;
    final startMinuteInt = roundedStartMinutes % 60;
    final endHourInt = roundedEndMinutes ~/ 60;
    final endMinuteInt = roundedEndMinutes % 60;

    // DateTimeを構築
    final startTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      startHourInt,
      startMinuteInt,
    );
    final endTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      endHourInt,
      endMinuteInt,
    );

    // 予約フォーム画面へ遷移
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservationFormPage(
          equipment: equipment,
          selectedDate: widget.selectedDate,
          initialStartTime: startTime,
          initialEndTime: endTime,
        ),
      ),
    );
  }

  /// 予約バーを構築
  Widget _buildReservationBar(
    BuildContext context,
    Reservation reservation,
    double hourWidth,
    double rowHeight,
  ) {
    // ユーザー情報を動的に取得して表示
    return Consumer(
      builder: (context, ref, child) {
        final reservationUserAsync = ref.watch(
          userByIdProvider(reservation.userId),
        );
        final currentUser = ref.read(currentUserProvider).value;
        final isMyReservation = currentUser?.id == reservation.userId;

        return reservationUserAsync.when(
          data: (reservationUser) {
            final startHour =
                reservation.startTime.hour +
                reservation.startTime.minute / 60.0;
            final endHour =
                reservation.endTime.hour + reservation.endTime.minute / 60.0;
            final duration = endHour - startHour;

            final left = startHour * hourWidth;
            final width = duration * hourWidth;

            // ユーザーのマイカラーを取得（リアルタイム）
            Color reservationColor = Colors.blue[100]!;
            Color borderColor = Colors.blue;

            if (reservationUser?.myColor != null &&
                reservationUser!.myColor!.isNotEmpty) {
              try {
                final hex = reservationUser.myColor!.replaceAll('#', '');
                final baseColor = Color(int.parse('FF$hex', radix: 16));
                reservationColor = baseColor.withOpacity(0.3);
                borderColor = baseColor;
              } catch (e) {
                // カラーコードのパースに失敗した場合はデフォルト色
                reservationColor = Colors.blue[100]!;
                borderColor = Colors.blue;
              }
            }

            // 自分の予約の場合は枠線を太く、影を追加して目立たせる
            final borderWidth = isMyReservation ? 3.0 : 1.5;
            final boxShadow = isMyReservation
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null;

            // ユーザー名を取得（リアルタイム）
            final userName = reservationUser?.name ?? '不明なユーザー';

            return Positioned(
              left: left,
              top: 4,
              width: width,
              height: rowHeight - 8,
              child: GestureDetector(
                onTap: () {
                  _showReservationDialog(context, reservation);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: reservationColor,
                    border: Border.all(color: borderColor, width: borderWidth),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: boxShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          // 自分の予約にはアイコンを表示
                          if (isMyReservation) ...[
                            Icon(Icons.person, size: 12, color: borderColor),
                            const SizedBox(width: 2),
                          ],
                          Expanded(
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontWeight: isMyReservation
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 11,
                                color: isMyReservation ? borderColor : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  void _showReservationDialog(BuildContext context, Reservation reservation) {
    final currentUser = ref.read(currentUserProvider).value;
    final canDelete =
        currentUser?.id == reservation.userId ||
        (currentUser?.isAdmin ?? false);

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final userAsync = ref.watch(userByIdProvider(reservation.userId));

          return userAsync.when(
            data: (user) {
              final userName = user?.name ?? '不明なユーザー';

              return AlertDialog(
                title: const Text('予約詳細'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('装置: ${reservation.equipmentName}'),
                    Text('予約者: $userName'),
                    Text(
                      '時間: ${DateFormat('HH:mm').format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
                    ),
                    if (reservation.note != null &&
                        reservation.note!.isNotEmpty)
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
                      child: const Text(
                        '削除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AlertDialog(
              title: const Text('エラー'),
              content: const Text('ユーザー情報の取得に失敗しました'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
