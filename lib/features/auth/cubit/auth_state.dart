import 'package:equatable/equatable.dart';

enum UserType { admin, ugc, normal }

UserType userTypeFromString(String? s) {
  switch (s) {
    case 'admin':
      return UserType.admin;
    case 'ugc':
      return UserType.ugc;
    default:
      return UserType.normal;
  }
}

enum ReferralRedeemStatus { idle, submitting, success, invalid, exhausted, error }

class AuthState extends Equatable {
  final UserType userType;
  final bool isLoaded;
  final ReferralRedeemStatus redeemStatus;

  const AuthState({
    this.userType = UserType.normal,
    this.isLoaded = false,
    this.redeemStatus = ReferralRedeemStatus.idle,
  });

  /// Admin and UGC users skip the paywall.
  bool get skipsPaywall =>
      userType == UserType.admin || userType == UserType.ugc;

  AuthState copyWith({
    UserType? userType,
    bool? isLoaded,
    ReferralRedeemStatus? redeemStatus,
  }) =>
      AuthState(
        userType: userType ?? this.userType,
        isLoaded: isLoaded ?? this.isLoaded,
        redeemStatus: redeemStatus ?? this.redeemStatus,
      );

  @override
  List<Object?> get props => [userType, isLoaded, redeemStatus];
}
