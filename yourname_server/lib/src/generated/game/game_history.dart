/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;

abstract class GameHistory
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameHistory._({
    this.id,
    required this.userId,
    required this.roomId,
    required this.round,
    required this.completedAt,
    required this.viewJson,
  });

  factory GameHistory({
    int? id,
    required String userId,
    required int roomId,
    required int round,
    required DateTime completedAt,
    required String viewJson,
  }) = _GameHistoryImpl;

  factory GameHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameHistory(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      round: jsonSerialization['round'] as int,
      completedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['completedAt'],
      ),
      viewJson: jsonSerialization['viewJson'] as String,
    );
  }

  static final t = GameHistoryTable();

  static const db = GameHistoryRepository._();

  @override
  int? id;

  String userId;

  int roomId;

  int round;

  DateTime completedAt;

  String viewJson;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameHistory copyWith({
    int? id,
    String? userId,
    int? roomId,
    int? round,
    DateTime? completedAt,
    String? viewJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameHistory',
      if (id != null) 'id': id,
      'userId': userId,
      'roomId': roomId,
      'round': round,
      'completedAt': completedAt.toJson(),
      'viewJson': viewJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static GameHistoryInclude include() {
    return GameHistoryInclude._();
  }

  static GameHistoryIncludeList includeList({
    _i1.WhereExpressionBuilder<GameHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameHistoryTable>? orderByList,
    GameHistoryInclude? include,
  }) {
    return GameHistoryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameHistory.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameHistory.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameHistoryImpl extends GameHistory {
  _GameHistoryImpl({
    int? id,
    required String userId,
    required int roomId,
    required int round,
    required DateTime completedAt,
    required String viewJson,
  }) : super._(
         id: id,
         userId: userId,
         roomId: roomId,
         round: round,
         completedAt: completedAt,
         viewJson: viewJson,
       );

  /// Returns a shallow copy of this [GameHistory]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameHistory copyWith({
    Object? id = _Undefined,
    String? userId,
    int? roomId,
    int? round,
    DateTime? completedAt,
    String? viewJson,
  }) {
    return GameHistory(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      round: round ?? this.round,
      completedAt: completedAt ?? this.completedAt,
      viewJson: viewJson ?? this.viewJson,
    );
  }
}

class GameHistoryUpdateTable extends _i1.UpdateTable<GameHistoryTable> {
  GameHistoryUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> roomId(int value) => _i1.ColumnValue(
    table.roomId,
    value,
  );

  _i1.ColumnValue<int, int> round(int value) => _i1.ColumnValue(
    table.round,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> completedAt(DateTime value) =>
      _i1.ColumnValue(
        table.completedAt,
        value,
      );

  _i1.ColumnValue<String, String> viewJson(String value) => _i1.ColumnValue(
    table.viewJson,
    value,
  );
}

class GameHistoryTable extends _i1.Table<int?> {
  GameHistoryTable({super.tableRelation}) : super(tableName: 'game_history') {
    updateTable = GameHistoryUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    roomId = _i1.ColumnInt(
      'roomId',
      this,
    );
    round = _i1.ColumnInt(
      'round',
      this,
    );
    completedAt = _i1.ColumnDateTime(
      'completedAt',
      this,
    );
    viewJson = _i1.ColumnString(
      'viewJson',
      this,
    );
  }

  late final GameHistoryUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnInt roomId;

  late final _i1.ColumnInt round;

  late final _i1.ColumnDateTime completedAt;

  late final _i1.ColumnString viewJson;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    roomId,
    round,
    completedAt,
    viewJson,
  ];
}

class GameHistoryInclude extends _i1.IncludeObject {
  GameHistoryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => GameHistory.t;
}

class GameHistoryIncludeList extends _i1.IncludeList {
  GameHistoryIncludeList._({
    _i1.WhereExpressionBuilder<GameHistoryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameHistory.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameHistory.t;
}

class GameHistoryRepository {
  const GameHistoryRepository._();

  /// Returns a list of [GameHistory]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<GameHistory>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameHistoryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameHistoryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameHistory>(
      where: where?.call(GameHistory.t),
      orderBy: orderBy?.call(GameHistory.t),
      orderByList: orderByList?.call(GameHistory.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameHistory] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<GameHistory?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameHistoryTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameHistoryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameHistoryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameHistory>(
      where: where?.call(GameHistory.t),
      orderBy: orderBy?.call(GameHistory.t),
      orderByList: orderByList?.call(GameHistory.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameHistory] by its [id] or null if no such row exists.
  Future<GameHistory?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameHistory>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameHistory]s in the list and returns the inserted rows.
  ///
  /// The returned [GameHistory]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameHistory>> insert(
    _i1.DatabaseSession session,
    List<GameHistory> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameHistory>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameHistory] and returns the inserted row.
  ///
  /// The returned [GameHistory] will have its `id` field set.
  Future<GameHistory> insertRow(
    _i1.DatabaseSession session,
    GameHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameHistory]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameHistory>> update(
    _i1.DatabaseSession session,
    List<GameHistory> rows, {
    _i1.ColumnSelections<GameHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameHistory>(
      rows,
      columns: columns?.call(GameHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameHistory]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameHistory> updateRow(
    _i1.DatabaseSession session,
    GameHistory row, {
    _i1.ColumnSelections<GameHistoryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameHistory>(
      row,
      columns: columns?.call(GameHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameHistory] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameHistory?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameHistoryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameHistory>(
      id,
      columnValues: columnValues(GameHistory.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameHistory]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameHistory>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameHistoryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GameHistoryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameHistoryTable>? orderBy,
    _i1.OrderByListBuilder<GameHistoryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameHistory>(
      columnValues: columnValues(GameHistory.t.updateTable),
      where: where(GameHistory.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameHistory.t),
      orderByList: orderByList?.call(GameHistory.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameHistory]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameHistory>> delete(
    _i1.DatabaseSession session,
    List<GameHistory> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameHistory>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameHistory].
  Future<GameHistory> deleteRow(
    _i1.DatabaseSession session,
    GameHistory row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameHistory>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameHistoryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameHistory>(
      where: where(GameHistory.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameHistoryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameHistory>(
      where: where?.call(GameHistory.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameHistory] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameHistoryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameHistory>(
      where: where(GameHistory.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
