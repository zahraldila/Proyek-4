class LoginController {
  // Multiple users (username -> password)
  final Map<String, String> _users = {
    "admin": "123",
    "user": "123",
    // kamu bisa tambah lagi:
    // "budi": "passbudi",
  };

  bool login(String username, String password) {
    final user = username.trim();
    final pass = password.trim();

    // cek user ada dan password cocok
    return _users.containsKey(user) && _users[user] == pass;
  }
}
