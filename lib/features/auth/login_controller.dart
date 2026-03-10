class LoginController {
  final List<Map<String, dynamic>> _users = [
    {
      'uid': 'admin',
      'username': 'admin',
      'password': '123',
      'role': 'Ketua',
      'teamId': 'TEAM_094',
    },
    {
      'uid': 'user',
      'username': 'user',
      'password': '123',
      'role': 'Anggota',
      'teamId': 'TEAM_094',
    },
    {
      'uid': 'budi',
      'username': 'budi',
      'password': '123',
      'role': 'Anggota',
      'teamId': 'TEAM_094',
    },
  ];

  /// Return data user jika login berhasil, null jika gagal
  Map<String, dynamic>? login(String username, String password) {
    final user = username.trim();
    final pass = password.trim();

    try {
      return _users.firstWhere(
        (u) => u['username'] == user && u['password'] == pass,
      );
    } catch (_) {
      return null;
    }
  }
}