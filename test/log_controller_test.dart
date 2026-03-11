import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_094/features/logbook/log_controller.dart';
import 'package:logbook_app_094/features/logbook/models/log_model.dart';

void main() {
  group('RBAC Security Check', () {
    test('Private logs should NOT be visible to teammates', () {
      final allLogs = [
        LogModel(
          id: '1',
          title: 'Catatan Private',
          description: 'Ini hanya untuk pemilik',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          category: 'Pribadi',
          authorId: 'userA',
          teamId: 'TEAM_094',
          isSynced: true,
          isPublic: false,
        ),
        LogModel(
          id: '2',
          title: 'Catatan Public',
          description: 'Ini bisa dilihat tim',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          category: 'Pekerjaan',
          authorId: 'userA',
          teamId: 'TEAM_094',
          isSynced: true,
          isPublic: true,
        ),
      ];

      final visibleLogs = LogController.filterVisibleLogs(allLogs, 'userB');

      expect(visibleLogs.length, 1);
      expect(visibleLogs.first.title, 'Catatan Public');
      expect(visibleLogs.first.isPublic, true);
    });
  });
}