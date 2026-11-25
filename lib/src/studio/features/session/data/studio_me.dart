// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/roles/studio_role.dart';

part 'studio_me.freezed.dart';
part 'studio_me.g.dart';

/// The answer of `jarz_social.api.studio.session.me`.
@freezed
abstract class StudioMe with _$StudioMe {
  const StudioMe._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory StudioMe({
    required String user,
    @Default('') String fullName,
    @Default(<String>[]) List<String> roles,
    @Default(false) bool isFounder,
    @Default('live') String mode,
    @Default('') String serverTime,
  }) = _StudioMe;

  factory StudioMe.fromJson(Map<String, dynamic> json) =>
      _$StudioMeFromJson(json);

  /// The role whose layout this user gets, or null with no Studio role.
  StudioRole? get primaryRole => StudioRole.primaryOf(roles);

  bool get hasStudioAccess => primaryRole != null;
}
