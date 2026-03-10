class AccessPolicy {
  static bool canEdit({
    required String currentUserId,
    required String currentUserRole,
    required String authorId,
  }) {
    if (currentUserRole == 'Ketua') return true;
    if (currentUserRole == 'Anggota' && currentUserId == authorId) return true;
    return false;
  }

  static bool canDelete({
    required String currentUserId,
    required String currentUserRole,
    required String authorId,
  }) {
    if (currentUserRole == 'Ketua') return true;
    if (currentUserRole == 'Anggota' && currentUserId == authorId) return true;
    return false;
  }

  static bool canCreate({
    required String currentUserRole,
  }) {
    return currentUserRole == 'Ketua' || currentUserRole == 'Anggota';
  }
}