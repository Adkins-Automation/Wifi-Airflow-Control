import 'package:test/test.dart';
import 'package:wifi_airflow_control/dto/last_change.dart';
import 'package:wifi_airflow_control/dto/schedule.dart';
import 'package:wifi_airflow_control/dto/damper.dart'; // Assuming your Damper class is in this file

void main() {
  group('Damper Tests', () {
    late Damper damper;
    setUp(() {
      // Create a new instance of Damper before each test
      var scheduleMap = {
        123456: Schedule(1330, 5, 75),
        7891011: Schedule(745, 2, 50),
      };
      damper = Damper(
        '1',
        'Main Damper',
        0,
        DateTime.now().millisecondsSinceEpoch ~/
            1000, // Assuming a recent heartbeat
        false,
        scheduleMap,
        null,
      );
    });

    test('scheduleForFirebase returns correct mapping', () {
      // Arrange is done by setUp

      // Act
      var firebaseSchedule = damper.scheduleForFirebase();

      // Assert
      expect(firebaseSchedule.keys, equals(['t123456', 't7891011']));
      expect(firebaseSchedule['t123456'],
          equals({'time': 123456, 'days': 5, 'position': 75}));
      expect(firebaseSchedule['t7891011'],
          equals({'time': 7891011, 'days': 2, 'position': 50}));
    });

    test('isOnline returns true for recent heartbeat', () {
      // Arrange is done by setUp

      // Act
      var isDamperOnline = damper.isOnline();

      // Assert
      expect(isDamperOnline, isTrue);
    });

    test('isOnline returns false for old heartbeat', () {
      // Arrange
      damper.lastHeartbeat =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 8; // 8 seconds ago

      // Act
      var isDamperOnline = damper.isOnline();

      // Assert
      expect(isDamperOnline, isFalse);
    });
  });
}
