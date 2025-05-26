import 'package:equatable/equatable.dart';

abstract class MyPoemsState extends Equatable {
  const MyPoemsState();
  @override
  List<Object?> get props => [];
}

class MyPoemsInitial extends MyPoemsState {}

class MyPoemsLoading extends MyPoemsState {}

class MyPoemsLoaded extends MyPoemsState {
  final List<Map<String, dynamic>> poems;
  const MyPoemsLoaded(this.poems);
  @override
  List<Object?> get props => [poems];
}

class MyPoemsError extends MyPoemsState {
  final String message;
  const MyPoemsError(this.message);
  @override
  List<Object?> get props => [message];
}


