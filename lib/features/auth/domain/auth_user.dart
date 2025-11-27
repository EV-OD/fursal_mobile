class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String role; // 'user', 'manager', 'admin'

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.role = 'user',
  });

  factory AuthUser.fromMap(Map<String, dynamic> map, String uid) {
    return AuthUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
    };
  }
  
  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? role,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
    );
  }
}
