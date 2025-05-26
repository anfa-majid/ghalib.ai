import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {}

class Unauthenticated extends AuthState {}

class UserNotRegistered extends AuthState {}

class LoginFailed extends AuthState {
  final String message;
  const LoginFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class Loading extends AuthState {}

class ShowError extends AuthState {
  final String message;
  const ShowError(this.message);

  @override
  List<Object?> get props => [message];
}

class ShowLoading extends AuthState {}

class FavoriteAdded extends AuthState {}

class FavoriteAddFailed extends AuthState {
  final String message;
  const FavoriteAddFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class FavoritesLoading extends AuthState {}

class FavoritesLoaded extends AuthState {
  final List<Map<String, dynamic>> poems;

  const FavoritesLoaded(this.poems);

  @override
  List<Object?> get props => [poems];
}

class FavoritesError extends AuthState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

