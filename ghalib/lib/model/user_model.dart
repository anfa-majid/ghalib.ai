class AppUser {
  final String uid;
  final String email;
  final String userName;
  final List<String> favorites;
  final String mood;

  AppUser({
    required this.uid,
    required this.email,
    required this.userName,
    required this.favorites,
    required this.mood,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      userName: data['user_name'] ?? '',
      favorites: List<String>.from(data['favorites'] ?? []),
      mood: data['mood'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'user_name': userName,
      'favorites': favorites,
      'mood': mood,
    };
  }
}
