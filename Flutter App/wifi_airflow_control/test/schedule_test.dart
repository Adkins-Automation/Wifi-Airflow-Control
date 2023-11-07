import 'package:test/test.dart';
import 'package:wifi_airflow_control/dto/schedule.dart';

void main() {
  group('Schedule', () {
    // Test the constructor
    test('constructor initializes values correctly', () {
      int time = 10;
      int days = 5; // Suppose this means Monday and Tuesday (1 + 4)
      int position = 1;
      var schedule = Schedule(time, days, position);

      expect(schedule.time, time);
      expect(schedule.days, days);
      expect(schedule.position, position);
    });

    // Test the getDay static method
    test('getDay returns correct bitwise value for each day', () {
      expect(Schedule.getDay(0), Schedule.monday);
      expect(Schedule.getDay(1), Schedule.tuesday);
      expect(Schedule.getDay(2), Schedule.wednesday);
      expect(Schedule.getDay(3), Schedule.thursday);
      expect(Schedule.getDay(4), Schedule.friday);
      expect(Schedule.getDay(5), Schedule.saturday);
      expect(Schedule.getDay(6), Schedule.sunday);
      expect(Schedule.getDay(7), Schedule.everyday);
    });

    // Test the setDay method
    test('setDay updates the days property correctly', () {
      var schedule = Schedule(0, 0, 0);
      schedule.setDay(Schedule.monday);
      expect(schedule.days & Schedule.monday, Schedule.monday);

      schedule.setDay(Schedule.tuesday);
      expect(schedule.days & Schedule.tuesday, Schedule.tuesday);

      // Further tests can be added for each day, or for combinations of days
    });

    // Test the isDaySet method
    test('isDaySet returns true if the day is set', () {
      var schedule = Schedule(0, Schedule.monday | Schedule.tuesday, 0);
      expect(schedule.isDaySet(Schedule.monday), isTrue);
      expect(schedule.isDaySet(Schedule.tuesday), isTrue);
      expect(schedule.isDaySet(Schedule.wednesday), isFalse);
    });

    // Test the unsetDay method
    test('unsetDay clears the day from the days property', () {
      var schedule = Schedule(0, Schedule.everyday, 0);
      schedule.unsetDay(Schedule.monday);
      expect(schedule.days & Schedule.monday, isNot(Schedule.monday));
      expect(schedule.days & Schedule.tuesday, Schedule.tuesday);

      schedule.unsetDay(Schedule.tuesday);
      expect(schedule.days & Schedule.tuesday, isNot(Schedule.tuesday));
    });
  });
}
