import '../../../core/roles/studio_role.dart';
import '../../../data/models/studio_models.dart';

/// Role helpers on the generated [MeProfile].
///
/// Every client-side "may this person see this button" check lives here, in
/// one place. The server holds each write too (NOT_PERMITTED), and the aim is
/// that the server returns an `actions` list for these as it does for
/// versions, pieces and posts: then each getter below is replaced by a look
/// at that list and nothing else changes.
extension MeProfileX on MeProfile {
  /// The role whose layout this user gets, or null with no Studio role.
  StudioRole? get primaryRole => StudioRole.primaryOf(roles);

  bool get hasStudioAccess => primaryRole != null;

  /// `references.create`: Founder and Marketing Lead.
  bool get canAddReferences =>
      primaryRole == StudioRole.founder || primaryRole == StudioRole.lead;

  /// Adding a version to the paid queue is the founder's write.
  bool get canAddToPaidQueue => isFounder;

  /// Settings can be changed by the founder; everyone else reads them.
  bool get canEditSettings => isFounder;

  /// Planning a shoot: Founder and Marketing Lead (the contract has no
  /// list-level action for it).
  bool get canPlanShoots =>
      primaryRole == StudioRole.founder || primaryRole == StudioRole.lead;

  /// A new link for the public prep page is the founder's.
  bool get canRegeneratePrep => isFounder;

  /// `assets.create`: every Studio role.
  bool get canAddAssets => hasStudioAccess;
}
