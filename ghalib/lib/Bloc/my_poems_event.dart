import 'package:equatable/equatable.dart';

abstract class MyPoemsEvent extends Equatable {
  const MyPoemsEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyPoems extends MyPoemsEvent {
  final String userEmail;
  const LoadMyPoems(this.userEmail);
}

class DeletePoem extends MyPoemsEvent {
  final String userEmail;
  final String poemId;
  const DeletePoem({required this.userEmail, required this.poemId});
}

class LoadMyPoemsFromCache extends MyPoemsEvent {
  final List<Map<String, dynamic>> poems;
  const LoadMyPoemsFromCache(this.poems);
}

