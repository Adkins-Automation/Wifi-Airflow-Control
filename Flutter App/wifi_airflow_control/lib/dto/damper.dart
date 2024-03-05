import 'package:wifi_airflow_control/dto/last_change.dart';
import 'package:wifi_airflow_control/dto/schedule.dart';

class Damper {
  String id;
  String label;
  int currentPosition;
  int lastHeartbeat;
  bool pauseSchedule;
  Map<int, Schedule> schedule;
  LastChange? lastChange;

  Damper(this.id, this.label, this.currentPosition, this.lastHeartbeat,
      this.pauseSchedule, this.schedule, this.lastChange);

  Map<String, Map<String, int>> scheduleForFirebase() {
    return schedule.map((time, schedule) {
      return MapEntry("t$time",
          {'time': time, 'days': schedule.days, 'position': schedule.position});
    });
  }

  bool isOnline() {
    var thirtySeconds = 30 * 1000;

    // var tmpHb = lastHeartbeat * 1000;
    // var now = DateTime.now().millisecondsSinceEpoch;
    // print("lastHeartbeat: $tmpHb");
    // print("          now: $now");
    // print(
    //     "         diff: ${now - tmpHb} ms or ${(now - tmpHb) / 1000} seconds");
    // print(" diff < 7 sec: ${now - tmpHb <= thirtySeconds}");
    // print("_____________________________");

    return ((DateTime.now().millisecondsSinceEpoch - (lastHeartbeat * 1000)) <=
        thirtySeconds);
  }

  @override
  String toString() {
    return "id: $id, label: $label, position: $currentPosition, lastHeartbeat: $lastHeartbeat, pauseSchedule: $pauseSchedule, schedule: $schedule";
  }
}
