part of 'trip_gate_cubit.dart';

abstract class TripGateState {}

class TripGateLoading extends TripGateState {}

class TripGateAllowed extends TripGateState {}

class TripGateBlocked extends TripGateState {}

class TripGateError extends TripGateState {
  final String message;
  TripGateError(this.message);
}