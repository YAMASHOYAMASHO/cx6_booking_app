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
import '../viewmodels/favorite_equipment_viewmodel.dart';
import 'admin/admin_menu_page.dart';
import 'equipment_timeline_page.dart';
import 'reservation_form_page.dart';
import 'my_page.dart';
import 'home/month_calendar.dart';
import 'home/timeline/timeline_view.dart';

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
          // 装置別タイムラインボタン
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EquipmentTimelinePage(),
                ),
              );
            },
            tooltip: '装置別タイムライン',
          ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // モバイル版レイアウトを使用
          return _MobileLayout(
            selectedLocation: selectedLocation,
            selectedDate: selectedDate,
          );
        },
      );
      },
    );
  }

  void _showReservationDialog(BuildContext context, Reservation reservation) {
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
}

/// お気に入り装置のタイムライン表示
class _FavoriteEquipmentsTimelineView extends ConsumerWidget {
  final DateTime selectedDate;

  const _FavoriteEquipmentsTimelineView({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteDetailsAsync = ref.watch(favoriteEquipmentDetailsProvider);
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
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'お気に入り装置 - ${dateFormat.format(selectedDate)}',
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
          child: favoriteDetailsAsync.when(
            data: (favoriteDetails) {
              if (favoriteDetails.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_border, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'お気に入り装置がありません',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'マイページからお気に入り装置を追加してください',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return reservationsAsync.when(
                data: (allReservations) {
                  // お気に入り装置のIDリストを取得
                  final favoriteEquipmentIds = favoriteDetails
                      .map((d) => d.equipment?.id)
                      .whereType<String>()
                      .toSet();

                  // 選択日の予約のみフィルタ
                  final selectedDayReservations = allReservations
                      .where(
                        (r) =>
                            isSameDay(r.startTime, selectedDate) &&
                            favoriteEquipmentIds.contains(r.equipmentId),
                      )
                      .toList();

                  return _HorizontalTimelineGrid(
                    equipments: favoriteDetails
                        .map((d) => d.equipment)
                        .whereType<Equipment>()
                        .toList(),
                    reservations: selectedDayReservations,
                    selectedDate: selectedDate,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _ErrorDisplay(error: error),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _ErrorDisplay(error: error),
          ),
        ),
      ],
    );
  }
}

/// スマホ用レイアウト（折りたたみカレンダー方式）
class _MobileLayout extends ConsumerStatefulWidget {
  final Location? selectedLocation;
  final DateTime selectedDate;

  const _MobileLayout({
    required this.selectedLocation,
    required this.selectedDate,
  });

  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout> {
  bool _isCalendarExpanded = false;
  bool _isLocationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final favoriteMode = ref.watch(favoriteModeProvider);

    return Column(
      children: [
        // 日付選択（折りたたみ可能）
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ExpansionTile(
            initiallyExpanded: _isCalendarExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isCalendarExpanded = expanded);
            },
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: Text(
              DateFormat('yyyy年M月d日(E)', 'ja_JP').format(widget.selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: [
              // カレンダー（高さ制限でスクロール可能に）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: MonthCalendar(
                      selectedDate: widget.selectedDate,
                      onDateSelected: (date) {
                        ref.read(selectedDateProvider.notifier).state = date;
                        // 日付選択後、カレンダーを自動で閉じる
                        setState(() => _isCalendarExpanded = false);
                      },
                    ),
                  ),
                ),
              ),
              // 日付ナビゲーションボタン
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DateNavigationButtons(),
              ),
            ],
          ),
        ),
        // 部屋選択（折りたたみ可能）
        Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ExpansionTile(
            initiallyExpanded: _isLocationExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isLocationExpanded = expanded);
            },
            leading: const Icon(Icons.room, color: Colors.blue),
            title: Text(
              widget.selectedLocation?.name ?? '部屋を選択してください',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: [
              // 部屋選択リスト
              _MobileLocationSelector(
                onSelected: () {
                  // 部屋選択後、自動で閉じる
                  setState(() => _isLocationExpanded = false);
                },
              ),
            ],
          ),
        ),
        // お気に入りモード切り替え
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('お気に入り装置のみ表示'),
              const Spacer(),
              Switch(
                value: favoriteMode,
                onChanged: (value) {
                  ref.read(favoriteModeProvider.notifier).state = value;
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // タイムライン（メインコンテンツ）
        Expanded(
          child: favoriteMode
              ? _FavoriteEquipmentsTimelineView(
                  selectedDate: widget.selectedDate,
                )
              : widget.selectedLocation != null
              ? TimelineView(
                  location: widget.selectedLocation!,
                  selectedDate: widget.selectedDate,
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.room_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '部屋を選択してください',
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

/// スマホ用部屋選択（リスト形式）
class _MobileLocationSelector extends ConsumerWidget {
  final VoidCallback onSelected;

  const _MobileLocationSelector({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return locationsAsync.when(
      data: (locations) {
        if (locations.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('部屋がありません'),
          );
        }

        // 部屋が多い場合に備えて高さ制限とスクロール
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: locations.map((location) {
                final isSelected = selectedLocation?.id == location.id;
                return ListTile(
                  leading: Icon(
                    Icons.room,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    location.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(selectedLocationProvider.notifier).state =
                        location;
                    onSelected();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: _ErrorDisplay(error: error),
      ),
    );
  }
}
