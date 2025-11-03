# お気に入り機能 アーキテクチャ設計

## 目次
1. [概要](#概要)
2. [データモデル設計](#データモデル設計)
3. [Firestore構造](#firestore構造)
4. [ViewModel設計](#viewmodel設計)
5. [UI設計](#ui設計)
6. [実装フェーズ](#実装フェーズ)
7. [将来的な拡張](#将来的な拡張)

---

## 概要

お気に入り機能は以下の2つのサブ機能で構成されます：

### 1. お気に入り装置リスト
- **目的**: よく使う装置を素早くアクセス
- **場所**: 各予約画面の場所選択ドロップダウンに「⭐ お気に入り」オプションを追加
- **管理**: マイページから装置の追加/削除
- **将来**: 予約履歴ベースのサジェスト機能

### 2. お気に入り予約（マクロ予約）
- **目的**: 定型パターンの予約を一括登録
- **機能**: 複数装置・複数日の予約をテンプレート化
- **実行**: ボタン一つで指定日に一括予約
- **安全性**: 重複チェック、実行前プレビュー

---

## データモデル設計

### 1. FavoriteEquipment（お気に入り装置）

```dart
// lib/src/models/favorite_equipment.dart

class FavoriteEquipment {
  final String id;              // ドキュメントID
  final String userId;          // ユーザーID
  final String equipmentId;     // 装置ID
  final String equipmentName;   // 装置名（キャッシュ）
  final String locationId;      // 場所ID（キャッシュ）
  final String locationName;    // 場所名（キャッシュ）
  final int order;              // 表示順序
  final DateTime createdAt;     // 登録日時
  
  FavoriteEquipment({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.locationId,
    required this.locationName,
    this.order = 0,
    required this.createdAt,
  });
  
  // Firestoreとの変換
  factory FavoriteEquipment.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
  
  // 並び替え用
  FavoriteEquipment copyWith({int? order});
}
```

### 2. FavoriteReservationTemplate（お気に入り予約テンプレート）

```dart
// lib/src/models/favorite_reservation_template.dart

class FavoriteReservationTemplate {
  final String id;              // ドキュメントID
  final String userId;          // ユーザーID
  final String name;            // テンプレート名（例: "月曜日の実験セット"）
  final String? description;    // 説明
  final List<ReservationSlot> slots; // 予約スロットリスト
  final DateTime createdAt;     // 作成日時
  final DateTime updatedAt;     // 更新日時
  
  FavoriteReservationTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.slots,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory FavoriteReservationTemplate.fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore();
}
```

### 3. ReservationSlot（予約スロット）

```dart
// lib/src/models/reservation_slot.dart

class ReservationSlot {
  final String equipmentId;     // 装置ID
  final String equipmentName;   // 装置名（キャッシュ）
  final int dayOffset;          // 基準日からの日数オフセット（0=当日, 1=翌日, -1=前日）
  final TimeOfDay startTime;    // 開始時刻
  final TimeOfDay endTime;      // 終了時刻
  final String? note;           // メモ（オプション）
  final int order;              // 実行順序
  
  ReservationSlot({
    required this.equipmentId,
    required this.equipmentName,
    required this.dayOffset,
    required this.startTime,
    required this.endTime,
    this.note,
    this.order = 0,
  });
  
  // 時間をJSON形式で保存
  Map<String, dynamic> toJson();
  factory ReservationSlot.fromJson(Map<String, dynamic> json);
  
  // 実際の予約日時を計算
  DateTime getStartDateTime(DateTime baseDate);
  DateTime getEndDateTime(DateTime baseDate);
  
  // 期間を計算
  Duration get duration;
}
```

### 4. FavoriteReservationExecution（お気に入り予約実行結果）

```dart
// lib/src/models/favorite_reservation_execution.dart

class FavoriteReservationExecution {
  final String templateId;      // テンプレートID
  final String templateName;    // テンプレート名
  final DateTime baseDate;      // 基準日
  final List<ReservationSlot> slots; // 実行するスロット
  final List<ConflictInfo> conflicts; // 競合情報
  
  FavoriteReservationExecution({
    required this.templateId,
    required this.templateName,
    required this.baseDate,
    required this.slots,
    required this.conflicts,
  });
  
  // 実行可能かどうか
  bool get canExecute => conflicts.isEmpty;
  
  // 作成される予約の数
  int get reservationCount => slots.length;
}

class ConflictInfo {
  final ReservationSlot slot;   // 競合するスロット
  final Reservation existingReservation; // 既存の予約
  
  ConflictInfo({
    required this.slot,
    required this.existingReservation,
  });
  
  String get description => 
    '${slot.equipmentName} ${DateFormat('HH:mm').format(slot.getStartDateTime(baseDate))}-${DateFormat('HH:mm').format(slot.getEndDateTime(baseDate))} は既に予約されています';
}
```

---

## Firestore構造

### 1. favoriteEquipments コレクション

```
favoriteEquipments/{favoriteEquipmentId}
  - userId: string           (インデックス)
  - equipmentId: string
  - equipmentName: string
  - locationId: string
  - locationName: string
  - order: number
  - createdAt: timestamp
```

**複合インデックス:**
- `userId` (昇順) + `order` (昇順)

### 2. favoriteReservationTemplates コレクション

```
favoriteReservationTemplates/{templateId}
  - userId: string           (インデックス)
  - name: string
  - description: string (nullable)
  - slots: array[
      {
        equipmentId: string
        equipmentName: string
        dayOffset: number
        startTime: { hour: number, minute: number }
        endTime: { hour: number, minute: number }
        note: string (nullable)
        order: number
      }
    ]
  - createdAt: timestamp
  - updatedAt: timestamp
```

**単一フィールドインデックス:**
- `userId` (昇順)

---

## ViewModel設計

### 1. FavoriteEquipmentViewModel

```dart
// lib/src/viewmodels/favorite_equipment_viewmodel.dart

/// お気に入り装置リストのプロバイダー
final favoriteEquipmentsProvider = StreamProvider<List<FavoriteEquipment>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref
    .watch(favoriteEquipmentRepositoryProvider)
    .getFavoriteEquipmentsStream(user.id);
});

/// お気に入り装置の詳細情報（Equipment情報を含む）
final favoriteEquipmentDetailsProvider = 
  StreamProvider.family<List<FavoriteEquipmentDetail>, String>((ref, userId) {
    // FavoriteEquipmentとEquipmentを結合
  });

/// お気に入り装置かどうかを判定
final isFavoriteEquipmentProvider = 
  Provider.family<bool, String>((ref, equipmentId) {
    final favorites = ref.watch(favoriteEquipmentsProvider).value ?? [];
    return favorites.any((f) => f.equipmentId == equipmentId);
  });

class FavoriteEquipmentViewModel extends StateNotifier<AsyncValue<void>> {
  final FavoriteEquipmentRepository _repository;
  final String _userId;
  
  FavoriteEquipmentViewModel(this._repository, this._userId) 
    : super(const AsyncValue.data(null));
  
  /// お気に入りに追加
  Future<void> addFavorite(Equipment equipment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 最大order値を取得して+1
      final maxOrder = await _repository.getMaxOrder(_userId);
      await _repository.addFavoriteEquipment(
        userId: _userId,
        equipmentId: equipment.id,
        equipmentName: equipment.name,
        locationId: equipment.locationId,
        locationName: equipment.locationName,
        order: maxOrder + 1,
      );
    });
  }
  
  /// お気に入りから削除
  Future<void> removeFavorite(String favoriteEquipmentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteFavoriteEquipment(favoriteEquipmentId);
    });
  }
  
  /// 並び替え
  Future<void> reorder(List<FavoriteEquipment> reorderedList) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateOrders(reorderedList);
    });
  }
}

final favoriteEquipmentViewModelProvider = 
  StateNotifierProvider<FavoriteEquipmentViewModel, AsyncValue<void>>((ref) {
    final user = ref.watch(currentUserProvider).value;
    return FavoriteEquipmentViewModel(
      ref.watch(favoriteEquipmentRepositoryProvider),
      user?.id ?? '',
    );
  });
```

### 2. FavoriteReservationTemplateViewModel

```dart
// lib/src/viewmodels/favorite_reservation_template_viewmodel.dart

/// お気に入り予約テンプレートリストのプロバイダー
final favoriteReservationTemplatesProvider = 
  StreamProvider<List<FavoriteReservationTemplate>>((ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return Stream.value([]);
    
    return ref
      .watch(favoriteReservationTemplateRepositoryProvider)
      .getTemplatesStream(user.id);
  });

/// テンプレート実行シミュレーション
final templateExecutionSimulationProvider = 
  FutureProvider.family<FavoriteReservationExecution, TemplateExecutionParams>(
    (ref, params) async {
      // 競合チェックを実施
      final conflicts = await ref
        .watch(favoriteReservationTemplateRepositoryProvider)
        .checkConflicts(params.templateId, params.baseDate);
      
      return FavoriteReservationExecution(
        templateId: params.templateId,
        templateName: params.templateName,
        baseDate: params.baseDate,
        slots: params.slots,
        conflicts: conflicts,
      );
    },
  );

class FavoriteReservationTemplateViewModel 
  extends StateNotifier<AsyncValue<void>> {
  final FavoriteReservationTemplateRepository _repository;
  final ReservationRepository _reservationRepository;
  final String _userId;
  
  FavoriteReservationTemplateViewModel(
    this._repository,
    this._reservationRepository,
    this._userId,
  ) : super(const AsyncValue.data(null));
  
  /// テンプレート作成
  Future<void> createTemplate({
    required String name,
    String? description,
    required List<ReservationSlot> slots,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createTemplate(
        userId: _userId,
        name: name,
        description: description,
        slots: slots,
      );
    });
  }
  
  /// テンプレート更新
  Future<void> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    List<ReservationSlot>? slots,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateTemplate(
        templateId: templateId,
        name: name,
        description: description,
        slots: slots,
      );
    });
  }
  
  /// テンプレート削除
  Future<void> deleteTemplate(String templateId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteTemplate(templateId);
    });
  }
  
  /// テンプレート実行（一括予約）
  Future<ExecutionResult> executeTemplate({
    required String templateId,
    required DateTime baseDate,
    required List<ReservationSlot> slots,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // 1. 競合チェック
      final conflicts = await _repository.checkConflicts(templateId, baseDate);
      
      if (conflicts.isNotEmpty) {
        state = const AsyncValue.data(null);
        return ExecutionResult(
          success: false,
          message: '競合する予約があります',
          conflicts: conflicts,
        );
      }
      
      // 2. 一括予約作成
      final results = <String>[];
      for (final slot in slots) {
        final reservationId = await _reservationRepository.createReservation(
          Reservation(
            id: '',
            userId: _userId,
            equipmentId: slot.equipmentId,
            equipmentName: slot.equipmentName,
            startTime: slot.getStartDateTime(baseDate),
            endTime: slot.getEndDateTime(baseDate),
            note: slot.note,
            createdAt: DateTime.now(),
          ),
        );
        results.add(reservationId);
      }
      
      state = const AsyncValue.data(null);
      return ExecutionResult(
        success: true,
        message: '${results.length}件の予約を作成しました',
        createdReservationIds: results,
      );
      
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return ExecutionResult(
        success: false,
        message: 'エラーが発生しました: $e',
      );
    }
  }
}

class ExecutionResult {
  final bool success;
  final String message;
  final List<ConflictInfo>? conflicts;
  final List<String>? createdReservationIds;
  
  ExecutionResult({
    required this.success,
    required this.message,
    this.conflicts,
    this.createdReservationIds,
  });
}

class TemplateExecutionParams {
  final String templateId;
  final String templateName;
  final DateTime baseDate;
  final List<ReservationSlot> slots;
  
  TemplateExecutionParams({
    required this.templateId,
    required this.templateName,
    required this.baseDate,
    required this.slots,
  });
}
```

---

## UI設計

### 1. マイページへの追加

#### 1.1 お気に入り装置管理セクション

```dart
// lib/src/views/my_page.dart に追加

Widget _buildFavoriteEquipmentsSection() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⭐ お気に入り装置', style: titleStyle),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => _showAddFavoriteEquipmentDialog(),
                tooltip: '装置を追加',
              ),
            ],
          ),
          Divider(),
          _buildFavoriteEquipmentsList(),
        ],
      ),
    ),
  );
}
```

#### 1.2 お気に入り予約テンプレート管理セクション

```dart
Widget _buildFavoriteReservationTemplatesSection() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📋 お気に入り予約', style: titleStyle),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('新規作成'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FavoriteReservationTemplateEditPage(),
                  ),
                ),
              ),
            ],
          ),
          Divider(),
          _buildTemplatesList(),
        ],
      ),
    ),
  );
}
```

### 2. 場所選択ドロップダウンの拡張

```dart
// lib/src/views/widgets/location_equipment_selector.dart

class LocationEquipmentSelector extends ConsumerWidget {
  final String? selectedLocationId;
  final String? selectedEquipmentId;
  final Function(String?) onLocationChanged;
  final Function(String?) onEquipmentChanged;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);
    final favoriteEquipments = ref.watch(favoriteEquipmentsProvider).value ?? [];
    
    return Column(
      children: [
        // 場所選択（お気に入りオプション付き）
        DropdownButton<String>(
          value: selectedLocationId,
          hint: Text('場所を選択'),
          items: [
            // お気に入りオプション
            if (favoriteEquipments.isNotEmpty)
              DropdownMenuItem(
                value: 'FAVORITES',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('⭐ お気に入り', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            DropdownMenuItem(
              value: null,
              child: Divider(),
              enabled: false,
            ),
            // 通常の場所リスト
            ...locations.map((loc) => DropdownMenuItem(
              value: loc.id,
              child: Text(loc.name),
            )),
          ],
          onChanged: onLocationChanged,
        ),
        
        SizedBox(height: 16),
        
        // 装置選択
        _buildEquipmentSelector(selectedLocationId),
      ],
    );
  }
  
  Widget _buildEquipmentSelector(String? locationId) {
    if (locationId == 'FAVORITES') {
      // お気に入り装置を表示
      return _buildFavoriteEquipmentSelector();
    } else {
      // 通常の装置選択
      return EquipmentSelector(
        locationId: locationId,
        selectedEquipmentId: selectedEquipmentId,
        onEquipmentChanged: onEquipmentChanged,
      );
    }
  }
}
```

### 3. お気に入り予約テンプレート編集画面

```dart
// lib/src/views/favorite_reservation_template_edit_page.dart

class FavoriteReservationTemplateEditPage extends ConsumerStatefulWidget {
  final FavoriteReservationTemplate? template; // 編集時は既存テンプレート
  
  @override
  ConsumerState createState() => _FavoriteReservationTemplateEditPageState();
}

class _FavoriteReservationTemplateEditPageState 
  extends ConsumerState<FavoriteReservationTemplateEditPage> {
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ReservationSlot> _slots = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? '新規テンプレート' : 'テンプレート編集'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // テンプレート名・説明入力
          _buildHeaderSection(),
          
          Divider(),
          
          // 予約スロット一覧
          Expanded(child: _buildSlotsList()),
          
          // スロット追加ボタン
          _buildAddSlotButton(),
        ],
      ),
    );
  }
  
  Widget _buildSlotsList() {
    return ReorderableListView.builder(
      itemCount: _slots.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final slot = _slots.removeAt(oldIndex);
          _slots.insert(newIndex, slot);
        });
      },
      itemBuilder: (context, index) {
        final slot = _slots[index];
        return _buildSlotCard(slot, index);
      },
    );
  }
  
  Widget _buildSlotCard(ReservationSlot slot, int index) {
    return Card(
      key: ValueKey(slot),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.drag_handle),
            Text('#${index + 1}', style: TextStyle(fontSize: 10)),
          ],
        ),
        title: Text(slot.equipmentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('日付: ${_getDayOffsetText(slot.dayOffset)}'),
            Text('時間: ${slot.startTime.format(context)} - ${slot.endTime.format(context)}'),
            if (slot.note != null) Text('メモ: ${slot.note}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editSlot(index),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSlot(index),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. お気に入り予約実行画面

```dart
// lib/src/views/favorite_reservation_execute_page.dart

class FavoriteReservationExecutePage extends ConsumerStatefulWidget {
  final FavoriteReservationTemplate template;
  
  @override
  ConsumerState createState() => _FavoriteReservationExecutePageState();
}

class _FavoriteReservationExecutePageState 
  extends ConsumerState<FavoriteReservationExecutePage> {
  
  DateTime _selectedDate = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    final simulationAsync = ref.watch(
      templateExecutionSimulationProvider(
        TemplateExecutionParams(
          templateId: widget.template.id,
          templateName: widget.template.name,
          baseDate: _selectedDate,
          slots: widget.template.slots,
        ),
      ),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('予約実行: ${widget.template.name}'),
      ),
      body: Column(
        children: [
          // カレンダー（日付選択）
          _buildCalendar(),
          
          Divider(),
          
          // 実行プレビュー
          Expanded(
            child: simulationAsync.when(
              data: (execution) => _buildExecutionPreview(execution),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('エラー: $error')),
            ),
          ),
          
          // 実行ボタン
          _buildExecuteButton(simulationAsync.value),
        ],
      ),
    );
  }
  
  Widget _buildExecutionPreview(FavoriteReservationExecution execution) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // サマリー
        Card(
          color: execution.canExecute ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  execution.canExecute ? '✓ 実行可能' : '⚠ 競合があります',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: execution.canExecute ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text('作成される予約: ${execution.reservationCount}件'),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // 予約スロット一覧
        Text('予約内容', style: Theme.of(context).textTheme.titleLarge),
        ...execution.slots.map((slot) => _buildSlotPreview(slot)),
        
        // 競合情報
        if (execution.conflicts.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('⚠ 競合', style: Theme.of(context).textTheme.titleLarge),
          ...execution.conflicts.map((conflict) => _buildConflictCard(conflict)),
        ],
      ],
    );
  }
}
```

---

## 実装フェーズ

### Phase 1: データ層とモデル（1-2日）

**優先度: 高**

1. **モデル作成**
   - `FavoriteEquipment`
   - `FavoriteReservationTemplate`
   - `ReservationSlot`
   - `FavoriteReservationExecution`

2. **Repository作成**
   - `FavoriteEquipmentRepository`
   - `FavoriteReservationTemplateRepository`

3. **Firestoreセキュリティルール**
   ```javascript
   // お気に入り装置
   match /favoriteEquipments/{favoriteId} {
     allow read: if isAuthenticated() && 
                 resource.data.userId == request.auth.uid;
     allow create: if isAuthenticated() && 
                   request.resource.data.userId == request.auth.uid;
     allow update, delete: if isAuthenticated() && 
                           resource.data.userId == request.auth.uid;
   }
   
   // お気に入り予約テンプレート
   match /favoriteReservationTemplates/{templateId} {
     allow read: if isAuthenticated() && 
                 resource.data.userId == request.auth.uid;
     allow create: if isAuthenticated() && 
                   request.resource.data.userId == request.auth.uid;
     allow update, delete: if isAuthenticated() && 
                           resource.data.userId == request.auth.uid;
   }
   ```

### Phase 2: お気に入り装置機能（1-2日）

**優先度: 高**

1. **ViewModel作成**
   - `FavoriteEquipmentViewModel`
   - 必要なProviderを定義

2. **UI実装**
   - マイページに管理セクション追加
   - お気に入り装置リスト表示
   - 追加/削除/並び替え機能

3. **場所選択の拡張**
   - ドロップダウンに「⭐ お気に入り」追加
   - お気に入り装置の表示切り替え

### Phase 3: お気に入り予約テンプレート基本機能（2-3日）

**優先度: 中**

1. **ViewModel作成**
   - `FavoriteReservationTemplateViewModel`
   - テンプレートCRUD操作

2. **テンプレート編集画面**
   - 新規作成/編集UI
   - スロット追加/削除/並び替え
   - 装置選択、時間設定

3. **マイページ統合**
   - テンプレート一覧表示
   - 編集/削除ボタン

### Phase 4: お気に入り予約実行機能（2-3日）

**優先度: 中**

1. **競合チェックロジック**
   - 既存予約との重複検出
   - `ConflictInfo`生成

2. **実行画面**
   - カレンダーで日付選択
   - 実行プレビュー表示
   - 競合警告表示

3. **一括予約作成**
   - トランザクション処理
   - エラーハンドリング
   - 成功/失敗通知

### Phase 5: UX改善（1-2日）

**優先度: 低**

1. **ビジュアル改善**
   - アイコンとカラー統一
   - アニメーション追加

2. **ユーザビリティ向上**
   - ヘルプテキスト
   - 空状態のプレースホルダー
   - 確認ダイアログ

3. **パフォーマンス最適化**
   - キャッシュ戦略
   - ローディング表示

---

## 将来的な拡張

### 1. 予約履歴ベースのサジェスト機能

```dart
// lib/src/viewmodels/favorite_suggestion_viewmodel.dart

/// 予約履歴から頻繁に使う装置を分析
final favoriteEquipmentSuggestionsProvider = 
  FutureProvider<List<EquipmentSuggestion>>((ref) async {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return [];
    
    // 過去3ヶ月の予約を分析
    final reservations = await ref
      .watch(reservationRepositoryProvider)
      .getReservationsByUserIdAndDateRange(
        user.id,
        DateTime.now().subtract(Duration(days: 90)),
        DateTime.now(),
      );
    
    // 装置ごとの使用頻度を集計
    final frequencyMap = <String, int>{};
    for (final reservation in reservations) {
      frequencyMap[reservation.equipmentId] = 
        (frequencyMap[reservation.equipmentId] ?? 0) + 1;
    }
    
    // 頻度順にソートして上位5件を返す
    final suggestions = frequencyMap.entries
      .map((e) => EquipmentSuggestion(
            equipmentId: e.key,
            usageCount: e.value,
          ))
      .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    return suggestions.take(5).toList();
  });
```

### 2. テンプレートの共有機能

- チーム内でテンプレートを共有
- 公開/非公開設定
- インポート/エクスポート

### 3. スマート実行

- 空き時間の自動検出
- 最適な時間帯の提案
- 複数候補日の一括チェック

### 4. 定期実行

- 毎週月曜日に自動実行
- cron式での実行スケジュール設定

---

## セキュリティとバリデーション

### 1. バリデーション

```dart
class ReservationSlotValidator {
  static String? validateSlot(ReservationSlot slot) {
    // 時間の妥当性チェック
    if (slot.startTime.hour > slot.endTime.hour ||
        (slot.startTime.hour == slot.endTime.hour && 
         slot.startTime.minute >= slot.endTime.minute)) {
      return '終了時刻は開始時刻より後である必要があります';
    }
    
    // dayOffsetの範囲チェック（±30日以内）
    if (slot.dayOffset < -30 || slot.dayOffset > 30) {
      return '日付オフセットは±30日以内で指定してください';
    }
    
    return null;
  }
}
```

### 2. アクセス制御

- ユーザーは自分のお気に入りのみ操作可能
- Firestoreルールで厳密に制御
- クライアント側でもチェック

---

## テスト戦略

### 1. ユニットテスト

- モデルのJSON変換
- 日時計算ロジック
- 競合検出アルゴリズム

### 2. Widgetテスト

- お気に入り装置リスト
- テンプレート編集UI
- 実行プレビュー画面

### 3. 統合テスト

- テンプレート作成→実行フロー
- 競合時の動作
- 複数装置の一括予約

---

## まとめ

### 実装推奨順序

1. **Phase 1**: データ層（必須）
2. **Phase 2**: お気に入り装置（使いやすさ向上）
3. **Phase 3**: テンプレート基本機能（コア機能）
4. **Phase 4**: テンプレート実行（メイン機能）
5. **Phase 5**: UX改善（磨き上げ）

### 見積もり工数

- **Phase 1**: 1-2日
- **Phase 2**: 1-2日
- **Phase 3**: 2-3日
- **Phase 4**: 2-3日
- **Phase 5**: 1-2日

**合計**: 7-12日

### 技術的課題

1. **競合チェックの性能**: 大量予約時の処理時間
2. **トランザクション**: Firestoreの制限（500ドキュメント/トランザクション）
3. **UI/UX**: 複雑な操作をシンプルに

### 次のステップ

アーキテクチャをレビューいただき、承認後にPhase 1から実装を開始します。
