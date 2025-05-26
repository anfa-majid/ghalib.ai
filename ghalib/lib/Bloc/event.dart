import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class LoginWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmailPasswordRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterWithEmailPasswordRequested extends AuthEvent {
  final String email;
  final String password;
  final String userName;

  const RegisterWithEmailPasswordRequested({
    required this.email,
    required this.password,
    required this.userName,
  });

  @override
  List<Object?> get props => [email, password, userName];
}

class RegisterWithGoogleRequested extends AuthEvent {}

class LocalErrorOccurred extends AuthEvent {
  final String message;
  const LocalErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}

class AddPoemToFavorites extends AuthEvent {
  final String userEmail;
  final String poemId;

  const AddPoemToFavorites({required this.userEmail, required this.poemId});

  @override
  List<Object?> get props => [userEmail, poemId];
}

class LoadFavorites extends AuthEvent {
  final String userEmail;

  const LoadFavorites(this.userEmail);

  @override
  List<Object?> get props => [userEmail];
}

class RemovePoemFromFavorites extends AuthEvent {
  final String userEmail;
  final String poemId;

  const RemovePoemFromFavorites({required this.userEmail, required this.poemId});

  @override
  List<Object?> get props => [userEmail, poemId];
}




class LoadFavoritesFromCache extends AuthEvent {
  final List<Map<String, dynamic>> cachedFavorites;

  const LoadFavoritesFromCache(this.cachedFavorites);

  @override
  List<Object?> get props => [cachedFavorites];
}
