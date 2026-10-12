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

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class RoomPulse implements _i1.SerializableModel {
  RoomPulse._({required this.code});

  factory RoomPulse({required String code}) = _RoomPulseImpl;

  factory RoomPulse.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomPulse(code: jsonSerialization['code'] as String);
  }

  String code;

  /// Returns a shallow copy of this [RoomPulse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomPulse copyWith({String? code});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomPulse',
      'code': code,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RoomPulseImpl extends RoomPulse {
  _RoomPulseImpl({required String code}) : super._(code: code);

  /// Returns a shallow copy of this [RoomPulse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomPulse copyWith({String? code}) {
    return RoomPulse(code: code ?? this.code);
  }
}
