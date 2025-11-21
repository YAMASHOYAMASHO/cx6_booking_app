import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/equipment.dart';
import '../../../models/reservation.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/reservation_viewmodel.dart';
import '../../../viewmodels/equipment_viewmodel.dart';
import '../../reservation_form_page.dart';

/// 横方向タイムライングリッド
class HorizontalTimelineGrid extends ConsumerStatefulWidget {
  final List<Equipment> equipments;
  final List<Reservation> reservations;
  final DateTime selectedDate;

  const HorizontalTimelineGrid({
    super.key,
    required this.equipments,
    required this.reservations,
    required this.selectedDate,
  });

  @override
  ConsumerState<HorizontalTimelineGrid> createState() =>
      _HorizontalTimelineGridState();
}

class _HorizontalTimelineGridState
    extends ConsumerState<HorizontalTimelineGrid> {
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

    // 予約フォームを開く
    Navigator.push(
      context,
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
                // カラーパースエラー時はデフォルト色
              }
            }

            // 自分の予約の場合は色を濃くする
            if (isMyReservation) {
              reservationColor = borderColor.withOpacity(0.6);
            }

            return Positioned(
              left: left,
              top: 4,
              width: width,
              height: rowHeight - 8,
              child: GestureDetector(
                onTap: () {
                  // 予約詳細・編集ダイアログを表示（実装は省略）
                  _showReservationDetails(context, reservation, isMyReservation);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: reservationColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.name ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (width > 40) // 幅が十分ある場合のみ時間を表示
                        Text(
                          '${reservation.startTime.hour}:${reservation.startTime.minute.toString().padLeft(2, '0')} - ${reservation.endTime.hour}:${reservation.endTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  void _showReservationDetails(
    BuildContext context,
    Reservation reservation,
    bool isMyReservation,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final userAsync = ref.watch(userByIdProvider(reservation.userId));
          final userName = userAsync.value?.name ?? 'Unknown';

          return AlertDialog(
            title: Text(reservation.equipmentName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('予約者: $userName'),
                Text(
                  '時間: ${reservation.startTime.hour}:${reservation.startTime.minute.toString().padLeft(2, '0')} - ${reservation.endTime.hour}:${reservation.endTime.minute.toString().padLeft(2, '0')}',
                ),
                if (reservation.note != null && reservation.note!.isNotEmpty)
                  Text('備考: ${reservation.note}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
              if (isMyReservation)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 編集画面へ遷移（実装が必要なら追加）
                  },
                  child: const Text('編集'),
                ),
            ],
          );
        },
      ),
    );
  }
}
