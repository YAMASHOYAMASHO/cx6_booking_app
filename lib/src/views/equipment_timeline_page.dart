import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/location.dart';
import '../models/reservation.dart';
import '../models/date_range.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/location_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart'
    show equipmentsByLocationProvider, equipmentsProvider;
import '../viewmodels/equipment_timeline_viewmodel.dart';
import '../viewmodels/reservation_viewmodel.dart';
import 'widgets/equipment_selector.dart';
import 'reservation_form_page.dart';

/// 装置別予約タイムライン画面
class EquipmentTimelinePage extends ConsumerStatefulWidget {
  const EquipmentTimelinePage({super.key});

  @override
  ConsumerState<EquipmentTimelinePage> createState() =>
      _EquipmentTimelinePageState();
}

class _EquipmentTimelinePageState extends ConsumerState<EquipmentTimelinePage> {
  DateTime _focusedDay = DateTime.now();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // ドラッグ状態管理
  DateTime? _dragTargetDate; // ドラッグ対象の日付
  double? _dragStartX; // ドラッグ開始X座標
  double? _dragCurrentX; // ドラッグ中の現在のX座標

  // タイムラインの定数
  static const double hourWidth = 40.0; // 1時間あたりの幅
  static const double rowHeight = 60.0; // 1行の高さ
  static const double timeHeaderHeight = 40.0; // 時刻ヘッダーの高さ
  static const double dateColumnWidth = 120.0; // 日付列の幅

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(selectedLocationProvider);
    final selectedEquipment = ref.watch(selectedEquipmentProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('装置別予約タイムライン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 日付範囲をリセット
              final today = DateTime.now();
              final startOfToday = DateTime(today.year, today.month, today.day);
              ref.read(dateRangeProvider.notifier).state = DateRange(
                start: startOfToday,
                end: startOfToday.add(const Duration(days: 20)),
              );
            },
            tooltip: '今日から3週間に戻す',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // スマホ版レイアウト
            return _buildMobileLayout(
              selectedLocation,
              selectedEquipment,
              dateRange,
            );
          } else {
            // PC版レイアウト（従来通り）
            return Row(
              children: [
                // 左サイドバー
                _buildSidebar(selectedLocation, selectedEquipment, dateRange),
                // 中央タイムライン
                Expanded(
                  child: _buildTimeline(
                    selectedLocation,
                    selectedEquipment,
                    dateRange,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// 左サイドバー
  Widget _buildSidebar(
    Location? selectedLocation,
    String? selectedEquipment,
    DateRange dateRange,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 部屋選択
            const Text(
              '部屋選択',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildLocationSelector(),
            const SizedBox(height: 24),
            // 装置選択
            const Text(
              '装置選択',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            EquipmentSelector(
              locationId: selectedLocation?.id,
              selectedEquipmentId: selectedEquipment,
              onEquipmentChanged: (equipmentId) {
                ref.read(selectedEquipmentProvider.notifier).state =
                    equipmentId;
              },
              hintText: '装置を選択してください',
            ),
            const SizedBox(height: 24),
            // 期間表示
            const Text(
              '表示期間',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy/MM/dd').format(dateRange.start),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('〜', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy/MM/dd').format(dateRange.end),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dateRange.dayCount}日間',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // カレンダー
            const Text(
              'カレンダー',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildCalendar(dateRange),
          ],
        ),
      ),
    );
  }

  /// 部屋選択ドロップダウン
  Widget _buildLocationSelector() {
    final locationsAsync = ref.watch(locationsProvider);

    return locationsAsync.when(
      data: (locations) {
        final selectedLocation = ref.watch(selectedLocationProvider);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Row(
              children: [
                Icon(Icons.location_on, size: 20),
                SizedBox(width: 8),
                Text('部屋を選択'),
              ],
            ),
            value: selectedLocation?.id,
            items: locations.map((location) {
              return DropdownMenuItem(
                value: location.id,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(location.name)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (locationId) {
              if (locationId != null) {
                final newLocation = locations.firstWhere(
                  (l) => l.id == locationId,
                );
                ref.read(selectedLocationProvider.notifier).state = newLocation;
                // 装置選択をクリア
                ref.read(selectedEquipmentProvider.notifier).state = null;
              }
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  /// カレンダー
  Widget _buildCalendar(DateRange dateRange) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => dateRange.contains(day),
      rangeStartDay: dateRange.start,
      rangeEndDay: dateRange.end,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        // 選択日を基準に2週間の範囲を設定
        final startOfDay = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        ref.read(dateRangeProvider.notifier).state = DateRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 13)),
        );
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        rangeHighlightColor: Colors.blue.shade100,
        rangeStartDecoration: BoxDecoration(
          color: Colors.blue.shade700,
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: Colors.blue.shade700,
          shape: BoxShape.circle,
        ),
        withinRangeDecoration: BoxDecoration(
          color: Colors.blue.shade200,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  /// タイムライン
  Widget _buildTimeline(
    Location? selectedLocation,
    String? selectedEquipment,
    DateRange dateRange,
  ) {
    // 装置が選択されていない場合
    if (selectedEquipment == null || selectedEquipment.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.precision_manufacturing,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '装置を選択してください',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final reservationsAsync = ref.watch(selectedEquipmentReservationsProvider);

    return reservationsAsync.when(
      data: (reservations) =>
          _buildTimelineGrid(selectedEquipment, dateRange, reservations),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラー: $error'),
          ],
        ),
      ),
    );
  }

  /// タイムライングリッド
  Widget _buildTimelineGrid(
    String equipmentId,
    DateRange dateRange,
    List<Reservation> reservations,
  ) {
    final days = dateRange.days;

    return Column(
      children: [
        // 時刻ヘッダー
        _buildTimeHeader(),
        // タイムライン本体
        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日付列
                  _buildDateColumn(days),
                  // グリッドとバー
                  Expanded(
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 24 * hourWidth,
                          child: Stack(
                            children: [
                              // グリッド
                              _buildGrid(days, equipmentId),
                              // 予約バー
                              ...days.asMap().entries.map((entry) {
                                final index = entry.key;
                                final day = entry.value;
                                return _buildDayReservations(
                                  day,
                                  index,
                                  reservations,
                                  equipmentId,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 時刻ヘッダー
  Widget _buildTimeHeader() {
    return Row(
      children: [
        // 日付列の空白
        SizedBox(
          width: dateColumnWidth,
          height: timeHeaderHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: Border(
                right: BorderSide(color: Colors.grey.shade400),
                bottom: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            child: const Center(
              child: Text('日付', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        // 時刻ヘッダー
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: 24 * hourWidth,
              height: timeHeaderHeight,
              child: Stack(
                children: List.generate(25, (hour) {
                  return Positioned(
                    left: hour * hourWidth,
                    top: 0,
                    width: hourWidth,
                    height: timeHeaderHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border(
                          left: hour == 0
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hour < 24 ? '$hour:00' : '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 日付列
  Widget _buildDateColumn(List<DateTime> days) {
    return Container(
      width: dateColumnWidth,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(right: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Column(
        children: days.map((day) {
          final isToday = DateUtils.isSameDay(day, DateTime.now());
          return Container(
            height: rowHeight,
            decoration: BoxDecoration(
              color: isToday ? Colors.blue.shade50 : null,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('M/d').format(day),
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: isToday ? Colors.blue.shade700 : null,
                    ),
                  ),
                  Text(
                    DateFormat('(E)', 'ja_JP').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      color: isToday
                          ? Colors.blue.shade700
                          : _getWeekdayColor(day),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 曜日の色を取得
  Color _getWeekdayColor(DateTime day) {
    switch (day.weekday) {
      case DateTime.sunday:
        return Colors.red;
      case DateTime.saturday:
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  /// グリッド
  Widget _buildGrid(List<DateTime> days, String equipmentId) {
    return Column(
      children: days.asMap().entries.map((entry) {
        final day = entry.value;
        final isDragging =
            _dragTargetDate != null &&
            DateUtils.isSameDay(_dragTargetDate, day) &&
            _dragStartX != null;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            setState(() {
              _dragTargetDate = day;
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
              _handleDragEnd(context, equipmentId, day);
            }
            setState(() {
              _dragTargetDate = null;
              _dragStartX = null;
              _dragCurrentX = null;
            });
          },
          child: Container(
            height: rowHeight,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Stack(
              children: [
                // グリッド背景
                Row(
                  children: List.generate(24, (hour) {
                    return Container(
                      width: hourWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          left: hour == 0
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    );
                  }),
                ),
                // ドラッグプレビュー
                if (isDragging && _dragStartX != null && _dragCurrentX != null)
                  _buildDragPreview(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ドラッグプレビュー
  Widget _buildDragPreview() {
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
    String equipmentId,
    DateTime targetDate,
  ) async {
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

    // 時刻を計算（15分単位に丸める）
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
      targetDate.year,
      targetDate.month,
      targetDate.day,
      startHourInt,
      startMinuteInt,
    );

    final endTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      endHourInt,
      endMinuteInt,
    );

    // 装置情報を取得
    final locationId = ref.read(selectedLocationProvider)?.id;
    if (locationId == null) return;

    final equipmentsAsync = ref.read(equipmentsByLocationProvider(locationId));

    await equipmentsAsync.when(
      data: (equipments) async {
        final equipment = equipments.firstWhere(
          (e) => e.id == equipmentId,
          orElse: () => throw Exception('装置が見つかりません'),
        );

        // 予約フォームを開く
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationFormPage(
                equipment: equipment,
                selectedDate: targetDate,
                initialStartTime: startTime,
                initialEndTime: endTime,
              ),
            ),
          );
        }
      },
      loading: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('装置情報を読み込み中...')));
      },
      error: (error, stack) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $error')));
      },
    );
  }

  /// 1日分の予約バー
  Widget _buildDayReservations(
    DateTime day,
    int dayIndex,
    List<Reservation> allReservations,
    String equipmentId,
  ) {
    // その日の予約のみ抽出
    final dayReservations = allReservations.where((r) {
      return DateUtils.isSameDay(r.startTime, day);
    }).toList();

    return Positioned(
      top: dayIndex * rowHeight,
      left: 0,
      right: 0,
      height: rowHeight,
      child: Stack(
        children: dayReservations.map((reservation) {
          return _buildReservationBar(reservation, equipmentId, day);
        }).toList(),
      ),
    );
  }

  /// 予約バー
  Widget _buildReservationBar(
    Reservation reservation,
    String equipmentId,
    DateTime day,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(userByIdProvider(reservation.userId));
        final currentUser = ref.read(currentUserProvider).value;
        final isMyReservation = currentUser?.id == reservation.userId;

        return userAsync.when(
          data: (user) {
            final startHour =
                reservation.startTime.hour +
                reservation.startTime.minute / 60.0;
            final endHour =
                reservation.endTime.hour + reservation.endTime.minute / 60.0;
            final duration = endHour - startHour;

            final left = startHour * hourWidth;
            final width = duration * hourWidth;

            // ユーザーのマイカラーを取得
            Color reservationColor = Colors.blue[100]!;
            Color borderColor = Colors.blue;

            if (user?.myColor != null && user!.myColor!.isNotEmpty) {
              try {
                final hex = user.myColor!.replaceAll('#', '');
                final baseColor = Color(int.parse('FF$hex', radix: 16));
                reservationColor = baseColor.withOpacity(0.3);
                borderColor = baseColor;
              } catch (e) {
                // カラーコードのパースに失敗した場合はデフォルト色
                reservationColor = Colors.blue[100]!;
                borderColor = Colors.blue;
              }
            }

            // 自分の予約の場合は枠線を太く
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

            final userName = user?.name ?? '不明なユーザー';

            return Positioned(
              left: left,
              top: 4,
              width: width,
              height: rowHeight - 8,
              child: GestureDetector(
                onTap: () {
                  _showReservationDetails(
                    context,
                    ref,
                    reservation,
                    equipmentId,
                  );
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
                                color:
                                    (reservationColor.computeLuminance() *
                                                reservationColor.opacity +
                                            (1 - reservationColor.opacity)) >
                                        0.5
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (width > 60)
                        Text(
                          '${DateFormat('HH:mm').format(reservation.startTime)}-${DateFormat('HH:mm').format(reservation.endTime)}',
                          style: const TextStyle(fontSize: 9),
                          overflow: TextOverflow.ellipsis,
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

  /// 予約詳細ダイアログ
  void _showReservationDetails(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
    String equipmentId,
  ) {
    final currentUser = ref.read(currentUserProvider).value;
    final canDelete =
        currentUser?.id == reservation.userId ||
        (currentUser?.isAdmin ?? false);
    final canEdit = currentUser?.id == reservation.userId;

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
                      '日付: ${DateFormat('yyyy年M月d日(E)', 'ja_JP').format(reservation.startTime)}',
                    ),
                    Text(
                      '時間: ${DateFormat('HH:mm').format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
                    ),
                    if (reservation.note != null &&
                        reservation.note!.isNotEmpty)
                      Text('メモ: ${reservation.note}'),
                  ],
                ),
                actions: [
                  if (canEdit)
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        // 装置情報を取得
                        final equipmentsAsync = ref.read(equipmentsProvider);
                        final equipment = equipmentsAsync.value?.firstWhere(
                          (e) => e.id == reservation.equipmentId,
                          orElse: () => throw Exception('装置が見つかりません'),
                        );

                        if (equipment != null && context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservationFormPage(
                                equipment: equipment,
                                selectedDate: DateTime(
                                  reservation.startTime.year,
                                  reservation.startTime.month,
                                  reservation.startTime.day,
                                ),
                                reservation: reservation,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        '編集',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
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

  /// スマホ用レイアウト
  Widget _buildMobileLayout(
    Location? selectedLocation,
    String? selectedEquipment,
    DateRange dateRange,
  ) {
    return Column(
      children: [
        // 部屋・装置選択（折りたたみ可能）
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ExpansionTile(
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: Text(
              selectedEquipment != null ? '装置選択済み' : '部屋と装置を選択してください',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 部屋選択
                        const Text(
                          '部屋',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, _) {
                            final locationsAsync = ref.watch(locationsProvider);
                            return locationsAsync.when(
                              data: (locations) =>
                                  DropdownButtonFormField<Location>(
                                    initialValue: selectedLocation,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: locations.map((location) {
                                      return DropdownMenuItem(
                                        value: location,
                                        child: Text(location.name),
                                      );
                                    }).toList(),
                                    onChanged: (location) {
                                      ref
                                              .read(
                                                selectedLocationProvider
                                                    .notifier,
                                              )
                                              .state =
                                          location;
                                      ref
                                              .read(
                                                selectedEquipmentProvider
                                                    .notifier,
                                              )
                                              .state =
                                          null;
                                    },
                                  ),
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const Text('エラー'),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // 装置選択
                        if (selectedLocation != null) ...[
                          const Text(
                            '装置',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Consumer(
                            builder: (context, ref, _) {
                              final equipmentsAsync = ref.watch(
                                equipmentsByLocationProvider(
                                  selectedLocation.id,
                                ),
                              );
                              return equipmentsAsync.when(
                                data: (equipments) {
                                  if (equipments.isEmpty) {
                                    return const Text('この部屋に装置がありません');
                                  }
                                  return Column(
                                    children: equipments.map((equipment) {
                                      final isSelected =
                                          selectedEquipment == equipment.id;
                                      return RadioListTile<String>(
                                        value: equipment.id,
                                        groupValue: selectedEquipment,
                                        title: Text(equipment.name),
                                        selected: isSelected,
                                        onChanged: (value) {
                                          ref
                                                  .read(
                                                    selectedEquipmentProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              value;
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (_, __) => const Text('エラー'),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // タイムライン
        Expanded(
          child: selectedEquipment != null
              ? _buildTimeline(selectedLocation, selectedEquipment, dateRange)
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '装置を選択してください',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
