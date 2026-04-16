import 'package:equatable/equatable.dart';

enum SubscriptionGateStatus { unknown, active, inactive }

class SubscriptionState extends Equatable {
  final SubscriptionGateStatus status;

  const SubscriptionState({this.status = SubscriptionGateStatus.unknown});

  bool get isActive => status == SubscriptionGateStatus.active;
  bool get isInactive => status == SubscriptionGateStatus.inactive;

  SubscriptionState copyWith({SubscriptionGateStatus? status}) =>
      SubscriptionState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
