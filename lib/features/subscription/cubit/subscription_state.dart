import 'package:equatable/equatable.dart';

enum SubscriptionGateStatus { unknown, active, inactive }

enum UserType { admin, ugc, apple, normal }

UserType userTypeFromString(String? s) {
  switch (s) {
    case 'admin':
      return UserType.admin;
    case 'ugc':
      return UserType.ugc;
    case 'apple':
      return UserType.apple;
    default:
      return UserType.normal;
  }
}

enum ReferralRedeemStatus { idle, submitting, success, invalid, exhausted, error }

class SubscriptionState extends Equatable {
  final SubscriptionGateStatus status;
  final UserType userType;
  final bool isLoaded;
  final ReferralRedeemStatus redeemStatus;

  const SubscriptionState({
    this.status = SubscriptionGateStatus.unknown,
    this.userType = UserType.normal,
    this.isLoaded = false,
    this.redeemStatus = ReferralRedeemStatus.idle,
  });

  bool get isActive => status == SubscriptionGateStatus.active;
  bool get isInactive => status == SubscriptionGateStatus.inactive;

  /// Admin, UGC, and Apple users skip the paywall.
  bool get skipsPaywall =>
      userType == UserType.admin ||
      userType == UserType.ugc ||
      userType == UserType.apple;

  /// True when the user can use gated features (admin/ugc OR active sub).
  bool get hasAccess => skipsPaywall || isActive;

  SubscriptionState copyWith({
    SubscriptionGateStatus? status,
    UserType? userType,
    bool? isLoaded,
    ReferralRedeemStatus? redeemStatus,
  }) =>
      SubscriptionState(
        status: status ?? this.status,
        userType: userType ?? this.userType,
        isLoaded: isLoaded ?? this.isLoaded,
        redeemStatus: redeemStatus ?? this.redeemStatus,
      );

  @override
  List<Object?> get props => [status, userType, isLoaded, redeemStatus];
}
