import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/equipment.dart';
import '../../models/location.dart';
import '../../models/reservation.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/location_viewmodel.dart';
import '../../viewmodels/reservation_viewmodel.dart';
import '../reservation_form_page.dart';

/// 予約管理画面（ホーム画面と同じデザイン、削除・変更可能）
class ReservationManagementPage extends ConsumerStatefulWidget {
  const ReservationManagementPage({super.key});

  @override
  ConsumerState<ReservationManagementPage> createState() =>
      _ReservationManagementPageState();
}

class _ReservationManagementPageState
    extends ConsumerState<ReservationManagementPage> {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocationId = ref.watch(selectedLocationIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('予約管理')),
      body: Column(
        children: [
          // カレンダー
          _buildCalendar(),
          const Divider(height: 1),
          // 場所選択
          _LocationSelector(selectedLocationId: selectedLocationId),
          const Divider(height: 1),
          // タイムライン
          Expanded(
            child: selectedLocationId == null
                ? const Center(child: Text('場所を選択してください'))
                : _TimelineView(
                    selectedDate: _selectedDate,
                    selectedLocationId: selectedLocationId,
                    scrollController: _scrollController,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
          });
        },
        calendarFormat: CalendarFormat.week,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        locale: 'ja_JP',
      ),
    );
  }
}

/// 場所選択ドロップダウン
class _LocationSelector extends ConsumerWidget {
  final String? selectedLocationId;

  const _LocationSelector({required this.selectedLocationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on),
          const SizedBox(width: 8),
          const Text('場所: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return const Text('場所が登録されていません');
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

                // 選択中のLocationIDがリストに存在するかチェック
                String? validSelectedLocationId = selectedLocationId;
                if (selectedLocationId != null) {
                  final exists = uniqueLocations.any(
                    (loc) => loc.id == selectedLocationId,
                  );
                  if (!exists) {
                    validSelectedLocationId = null;
                  }
                }

                return DropdownButton<String>(
                  value: validSelectedLocationId,
                  isExpanded: true,
                  hint: const Text('場所を選択'),
                  items: uniqueLocations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location.id,
                      child: Text(location.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    ref.read(selectedLocationIdProvider.notifier).state = value;
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

/// タイムライン表示
class _TimelineView extends ConsumerWidget {
  final DateTime selectedDate;
  final String selectedLocationId;
  final ScrollController scrollController;

  const _TimelineView({
    required this.selectedDate,
    required this.selectedLocationId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(
      equipmentsByLocationProvider(selectedLocationId),
    );
    final reservationsAsync = ref.watch(adminAllReservationsProvider);

    return equipmentsAsync.when(
      data: (equipments) {
        if (equipments.isEmpty) {
          return const Center(child: Text('この場所に装置が登録されていません'));
        }

        return reservationsAsync.when(
          data: (allReservations) {
            // 選択日の予約のみフィルタリング
            final reservations = allReservations.where((r) {
              final reservationDate = DateTime(
                r.startTime.year,
                r.startTime.month,
                r.startTime.day,
              );
              final targetDate = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              );
              return reservationDate == targetDate;
            }).toList();

            return _HorizontalTimelineGrid(
              equipments: equipments,
              reservations: reservations,
              selectedDate: selectedDate,
              selectedLocationId: selectedLocationId,
              scrollController: scrollController,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: _ErrorDisplay(error: error)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: _ErrorDisplay(error: error)),
    );
  }
}

/// 横方向タイムラインのグリッド
class _HorizontalTimelineGrid extends ConsumerWidget {
  final List<Equipment> equipments;
  final List<Reservation> reservations;
  final DateTime selectedDate;
  final String selectedLocationId;
  final ScrollController scrollController;
  static const double hourWidth = 40.0;
  static const double rowHeight = 80.0;

  const _HorizontalTimelineGrid({
    required this.equipments,
    required this.reservations,
    required this.selectedDate,
    required this.selectedLocationId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 24 * hourWidth + 200,
          child: Column(
            children: [
              // 時間軸ヘッダー
              _buildTimeHeader(),
              const Divider(height: 1),
              // 装置行
              Expanded(
                child: ListView.builder(
                  itemCount: equipments.length,
                  itemBuilder: (context, index) {
                    return _buildEquipmentRow(
                      context,
                      ref,
                      equipments[index],
                      reservations,
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

  Widget _buildTimeHeader() {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // 装置名エリア
          Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: const Center(
              child: Text('装置', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // 時間軸
          ...List.generate(24, (hour) {
            return Container(
              width: hourWidth,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(left: BorderSide(color: Colors.grey.shade400)),
              ),
              child: Center(
                child: Text('$hour', style: const TextStyle(fontSize: 12)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEquipmentRow(
    BuildContext context,
    WidgetRef ref,
    Equipment equipment,
    List<Reservation> allReservations,
  ) {
    final equipmentReservations = allReservations
        .where((r) => r.equipmentId == equipment.id)
        .toList();

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 装置名
          Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  equipment.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (equipment.description.isNotEmpty)
                  Text(
                    equipment.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    );
                  }),
                ),
                // 予約バー
                ...equipmentReservations.map((reservation) {
                  return _buildReservationBar(context, ref, reservation);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationBar(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) {
    final startHour =
        reservation.startTime.hour + reservation.startTime.minute / 60.0;
    final endHour =
        reservation.endTime.hour + reservation.endTime.minute / 60.0;
    final duration = endHour - startHour;

    return Consumer(
      builder: (context, ref, _) {
        final userAsync = ref.watch(userByIdProvider(reservation.userId));

        return userAsync.when(
          data: (user) {
            // ユーザーのマイカラーを取得
            Color reservationColor = Colors.blue.shade300;
            Color borderColor = Colors.blue.shade700;

            if (user?.myColor != null && user!.myColor!.isNotEmpty) {
              try {
                final hex = user.myColor!.replaceAll('#', '');
                final baseColor = Color(int.parse('FF$hex', radix: 16));
                reservationColor = baseColor.withValues(alpha: 0.7);
                borderColor = baseColor.withValues(alpha: 0.9);
              } catch (e) {
                // カラーコードのパースに失敗した場合はデフォルト色
                reservationColor = Colors.blue.shade300;
                borderColor = Colors.blue.shade700;
              }
            }

            final userName = user?.name ?? '不明なユーザー';

            return Positioned(
              left: startHour * hourWidth,
              top: 8,
              width: duration * hourWidth - 4,
              height: rowHeight - 16,
              child: InkWell(
                onTap: () => _showReservationMenu(context, ref, reservation),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: reservationColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${DateFormat('HH:mm').format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      if (reservation.note != null &&
                          reservation.note!.isNotEmpty)
                        Expanded(
                          child: Text(
                            reservation.note!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  void _showReservationMenu(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final userAsync = ref.watch(userByIdProvider(reservation.userId));

          return userAsync.when(
            data: (user) {
              final userName = user?.name ?? '不明なユーザー';

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('予約詳細', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildDetailRow('装置', reservation.equipmentName),
                    _buildDetailRow('予約者', userName),
                    _buildDetailRow(
                      '時間',
                      '${DateFormat('yyyy/MM/dd HH:mm').format(reservation.startTime)} - ${DateFormat('HH:mm').format(reservation.endTime)}',
                    ),
                    if (reservation.note != null &&
                        reservation.note!.isNotEmpty)
                      _buildDetailRow('メモ', reservation.note!),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // 装置情報を取得
                            final equipments = await ref.read(
                              equipmentsByLocationProvider(
                                selectedLocationId,
                              ).future,
                            );
                            final equipment = equipments.firstWhere(
                              (e) => e.id == reservation.equipmentId,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ReservationFormPage(
                                    equipment: equipment,
                                    selectedDate: selectedDate,
                                    reservation: reservation,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('編集'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('予約を削除'),
                                content: const Text('この予約を削除しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      '削除',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref
                                  .read(reservationViewModelProvider.notifier)
                                  .deleteReservation(reservation.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('予約を削除しました')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('削除'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(16),
              child: const Text('ユーザー情報の取得に失敗しました'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

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
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text(
                'エラーが発生しました',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
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
