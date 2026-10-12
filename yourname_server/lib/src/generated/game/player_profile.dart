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

abstract class PlayerProfile
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PlayerProfile._({
    this.id,
    required this.userId,
    required this.displayName,
    required this.avatarIndex,
    this.avatarImage,
  });

  factory PlayerProfile({
    int? id,
    required String userId,
    required String displayName,
    required int avatarIndex,
    String? avatarImage,
  }) = _PlayerProfileImpl;

  factory PlayerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlayerProfile(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      displayName: jsonSerialization['displayName'] as String,
      avatarIndex: jsonSerialization['avatarIndex'] as int,
      avatarImage: jsonSerialization['avatarImage'] as String?,
    );
  }

  static final t = PlayerProfileTable();

  static const db = PlayerProfileRepository._();

  @override
  int? id;

  String userId;

  String displayName;

  int avatarIndex;

  String? avatarImage;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PlayerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PlayerProfile copyWith({
    int? id,
    String? userId,
    String? displayName,
    int? avatarIndex,
    String? avatarImage,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlayerProfile',
      if (id != null) 'id': id,
      'userId': userId,
      'displayName': displayName,
      'avatarIndex': avatarIndex,
      if (avatarImage != null) 'avatarImage': avatarImage,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PlayerProfileInclude include() {
    return PlayerProfileInclude._();
  }

  static PlayerProfileIncludeList includeList({
    _i1.WhereExpressionBuilder<PlayerProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PlayerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PlayerProfileTable>? orderByList,
    PlayerProfileInclude? include,
  }) {
    return PlayerProfileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PlayerProfile.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PlayerProfile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PlayerProfileImpl extends PlayerProfile {
  _PlayerProfileImpl({
    int? id,
    required String userId,
    required String displayName,
    required int avatarIndex,
    String? avatarImage,
  }) : super._(
         id: id,
         userId: userId,
         displayName: displayName,
         avatarIndex: avatarIndex,
         avatarImage: avatarImage,
       );

  /// Returns a shallow copy of this [PlayerProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PlayerProfile copyWith({
    Object? id = _Undefined,
    String? userId,
    String? displayName,
    int? avatarIndex,
    Object? avatarImage = _Undefined,
  }) {
    return PlayerProfile(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarImage: avatarImage is String? ? avatarImage : this.avatarImage,
    );
  }
}

class PlayerProfileUpdateTable extends _i1.UpdateTable<PlayerProfileTable> {
  PlayerProfileUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<int, int> avatarIndex(int value) => _i1.ColumnValue(
    table.avatarIndex,
    value,
  );

  _i1.ColumnValue<String, String> avatarImage(String? value) => _i1.ColumnValue(
    table.avatarImage,
    value,
  );
}

class PlayerProfileTable extends _i1.Table<int?> {
  PlayerProfileTable({super.tableRelation})
    : super(tableName: 'player_profile') {
    updateTable = PlayerProfileUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
    );
    avatarIndex = _i1.ColumnInt(
      'avatarIndex',
      this,
    );
    avatarImage = _i1.ColumnString(
      'avatarImage',
      this,
    );
  }

  late final PlayerProfileUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnInt avatarIndex;

  late final _i1.ColumnString avatarImage;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    displayName,
    avatarIndex,
    avatarImage,
  ];
}

class PlayerProfileInclude extends _i1.IncludeObject {
  PlayerProfileInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PlayerProfile.t;
}

class PlayerProfileIncludeList extends _i1.IncludeList {
  PlayerProfileIncludeList._({
    _i1.WhereExpressionBuilder<PlayerProfileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PlayerProfile.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PlayerProfile.t;
}

class PlayerProfileRepository {
  const PlayerProfileRepository._();

  /// Returns a list of [PlayerProfile]s matching the given query parameters.
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
  Future<List<PlayerProfile>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PlayerProfileTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PlayerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PlayerProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PlayerProfile>(
      where: where?.call(PlayerProfile.t),
      orderBy: orderBy?.call(PlayerProfile.t),
      orderByList: orderByList?.call(PlayerProfile.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PlayerProfile] matching the given query parameters.
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
  Future<PlayerProfile?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PlayerProfileTable>? where,
    int? offset,
    _i1.OrderByBuilder<PlayerProfileTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PlayerProfileTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PlayerProfile>(
      where: where?.call(PlayerProfile.t),
      orderBy: orderBy?.call(PlayerProfile.t),
      orderByList: orderByList?.call(PlayerProfile.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PlayerProfile] by its [id] or null if no such row exists.
  Future<PlayerProfile?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PlayerProfile>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PlayerProfile]s in the list and returns the inserted rows.
  ///
  /// The returned [PlayerProfile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PlayerProfile>> insert(
    _i1.DatabaseSession session,
    List<PlayerProfile> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PlayerProfile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PlayerProfile] and returns the inserted row.
  ///
  /// The returned [PlayerProfile] will have its `id` field set.
  Future<PlayerProfile> insertRow(
    _i1.DatabaseSession session,
    PlayerProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PlayerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PlayerProfile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PlayerProfile>> update(
    _i1.DatabaseSession session,
    List<PlayerProfile> rows, {
    _i1.ColumnSelections<PlayerProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PlayerProfile>(
      rows,
      columns: columns?.call(PlayerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PlayerProfile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PlayerProfile> updateRow(
    _i1.DatabaseSession session,
    PlayerProfile row, {
    _i1.ColumnSelections<PlayerProfileTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PlayerProfile>(
      row,
      columns: columns?.call(PlayerProfile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PlayerProfile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PlayerProfile?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PlayerProfileUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PlayerProfile>(
      id,
      columnValues: columnValues(PlayerProfile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PlayerProfile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PlayerProfile>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PlayerProfileUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<PlayerProfileTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PlayerProfileTable>? orderBy,
    _i1.OrderByListBuilder<PlayerProfileTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PlayerProfile>(
      columnValues: columnValues(PlayerProfile.t.updateTable),
      where: where(PlayerProfile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PlayerProfile.t),
      orderByList: orderByList?.call(PlayerProfile.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PlayerProfile]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PlayerProfile>> delete(
    _i1.DatabaseSession session,
    List<PlayerProfile> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PlayerProfile>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PlayerProfile].
  Future<PlayerProfile> deleteRow(
    _i1.DatabaseSession session,
    PlayerProfile row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PlayerProfile>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PlayerProfile>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PlayerProfileTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PlayerProfile>(
      where: where(PlayerProfile.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PlayerProfileTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PlayerProfile>(
      where: where?.call(PlayerProfile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PlayerProfile] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PlayerProfileTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PlayerProfile>(
      where: where(PlayerProfile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
