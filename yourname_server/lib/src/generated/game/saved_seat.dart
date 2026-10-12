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

abstract class SavedSeat
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  SavedSeat._({
    this.id,
    required this.userId,
    required this.roomId,
    required this.playerId,
    required this.joinedAt,
  });

  factory SavedSeat({
    int? id,
    required String userId,
    required int roomId,
    required String playerId,
    required DateTime joinedAt,
  }) = _SavedSeatImpl;

  factory SavedSeat.fromJson(Map<String, dynamic> jsonSerialization) {
    return SavedSeat(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      roomId: jsonSerialization['roomId'] as int,
      playerId: jsonSerialization['playerId'] as String,
      joinedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['joinedAt'],
      ),
    );
  }

  static final t = SavedSeatTable();

  static const db = SavedSeatRepository._();

  @override
  int? id;

  String userId;

  int roomId;

  String playerId;

  DateTime joinedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [SavedSeat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SavedSeat copyWith({
    int? id,
    String? userId,
    int? roomId,
    String? playerId,
    DateTime? joinedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SavedSeat',
      if (id != null) 'id': id,
      'userId': userId,
      'roomId': roomId,
      'playerId': playerId,
      'joinedAt': joinedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SavedSeatInclude include() {
    return SavedSeatInclude._();
  }

  static SavedSeatIncludeList includeList({
    _i1.WhereExpressionBuilder<SavedSeatTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSeatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSeatTable>? orderByList,
    SavedSeatInclude? include,
  }) {
    return SavedSeatIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SavedSeat.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(SavedSeat.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SavedSeatImpl extends SavedSeat {
  _SavedSeatImpl({
    int? id,
    required String userId,
    required int roomId,
    required String playerId,
    required DateTime joinedAt,
  }) : super._(
         id: id,
         userId: userId,
         roomId: roomId,
         playerId: playerId,
         joinedAt: joinedAt,
       );

  /// Returns a shallow copy of this [SavedSeat]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SavedSeat copyWith({
    Object? id = _Undefined,
    String? userId,
    int? roomId,
    String? playerId,
    DateTime? joinedAt,
  }) {
    return SavedSeat(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      playerId: playerId ?? this.playerId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class SavedSeatUpdateTable extends _i1.UpdateTable<SavedSeatTable> {
  SavedSeatUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<int, int> roomId(int value) => _i1.ColumnValue(
    table.roomId,
    value,
  );

  _i1.ColumnValue<String, String> playerId(String value) => _i1.ColumnValue(
    table.playerId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> joinedAt(DateTime value) =>
      _i1.ColumnValue(
        table.joinedAt,
        value,
      );
}

class SavedSeatTable extends _i1.Table<int?> {
  SavedSeatTable({super.tableRelation}) : super(tableName: 'saved_seat') {
    updateTable = SavedSeatUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    roomId = _i1.ColumnInt(
      'roomId',
      this,
    );
    playerId = _i1.ColumnString(
      'playerId',
      this,
    );
    joinedAt = _i1.ColumnDateTime(
      'joinedAt',
      this,
    );
  }

  late final SavedSeatUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnInt roomId;

  late final _i1.ColumnString playerId;

  late final _i1.ColumnDateTime joinedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    roomId,
    playerId,
    joinedAt,
  ];
}

class SavedSeatInclude extends _i1.IncludeObject {
  SavedSeatInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => SavedSeat.t;
}

class SavedSeatIncludeList extends _i1.IncludeList {
  SavedSeatIncludeList._({
    _i1.WhereExpressionBuilder<SavedSeatTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SavedSeat.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => SavedSeat.t;
}

class SavedSeatRepository {
  const SavedSeatRepository._();

  /// Returns a list of [SavedSeat]s matching the given query parameters.
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
  Future<List<SavedSeat>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SavedSeatTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSeatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSeatTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SavedSeat>(
      where: where?.call(SavedSeat.t),
      orderBy: orderBy?.call(SavedSeat.t),
      orderByList: orderByList?.call(SavedSeat.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [SavedSeat] matching the given query parameters.
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
  Future<SavedSeat?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SavedSeatTable>? where,
    int? offset,
    _i1.OrderByBuilder<SavedSeatTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SavedSeatTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SavedSeat>(
      where: where?.call(SavedSeat.t),
      orderBy: orderBy?.call(SavedSeat.t),
      orderByList: orderByList?.call(SavedSeat.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SavedSeat] by its [id] or null if no such row exists.
  Future<SavedSeat?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SavedSeat>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SavedSeat]s in the list and returns the inserted rows.
  ///
  /// The returned [SavedSeat]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<SavedSeat>> insert(
    _i1.DatabaseSession session,
    List<SavedSeat> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<SavedSeat>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [SavedSeat] and returns the inserted row.
  ///
  /// The returned [SavedSeat] will have its `id` field set.
  Future<SavedSeat> insertRow(
    _i1.DatabaseSession session,
    SavedSeat row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<SavedSeat>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [SavedSeat]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<SavedSeat>> update(
    _i1.DatabaseSession session,
    List<SavedSeat> rows, {
    _i1.ColumnSelections<SavedSeatTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<SavedSeat>(
      rows,
      columns: columns?.call(SavedSeat.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SavedSeat]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SavedSeat> updateRow(
    _i1.DatabaseSession session,
    SavedSeat row, {
    _i1.ColumnSelections<SavedSeatTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<SavedSeat>(
      row,
      columns: columns?.call(SavedSeat.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SavedSeat] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SavedSeat?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<SavedSeatUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<SavedSeat>(
      id,
      columnValues: columnValues(SavedSeat.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SavedSeat]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<SavedSeat>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<SavedSeatUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SavedSeatTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SavedSeatTable>? orderBy,
    _i1.OrderByListBuilder<SavedSeatTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<SavedSeat>(
      columnValues: columnValues(SavedSeat.t.updateTable),
      where: where(SavedSeat.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SavedSeat.t),
      orderByList: orderByList?.call(SavedSeat.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [SavedSeat]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<SavedSeat>> delete(
    _i1.DatabaseSession session,
    List<SavedSeat> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<SavedSeat>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [SavedSeat].
  Future<SavedSeat> deleteRow(
    _i1.DatabaseSession session,
    SavedSeat row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SavedSeat>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<SavedSeat>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SavedSeatTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<SavedSeat>(
      where: where(SavedSeat.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SavedSeatTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<SavedSeat>(
      where: where?.call(SavedSeat.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SavedSeat] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SavedSeatTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SavedSeat>(
      where: where(SavedSeat.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
