class Damper {
  String id;
  String label;
  int currentPosition;
  int? lastHeartbeat;
  Map<int, Map<int, int>>? schedule; // day of week, time, position

  Damper(this.id, this.label, this.currentPosition, this.lastHeartbeat,
      this.schedule);

  bool isOnline() {
    if (lastHeartbeat == null) {
      return false;
    }

    var tmpHb = lastHeartbeat! * 1000;
    var now = DateTime.now().millisecondsSinceEpoch;
    var sixSeconds = 6 * 1000;
    print("lastHeartbeat: $tmpHb");
    print("          now: $now");
    print(
        "         diff: ${now - tmpHb} ms or ${(now - tmpHb) / 1000} seconds");
    print(" diff < 6 sec: ${now - tmpHb <= sixSeconds}");
    print("_____________________________");

    return ((lastHeartbeat != null) &&
        ((DateTime.now().millisecondsSinceEpoch - (lastHeartbeat! * 1000)) <=
            sixSeconds));
  }

  @override
  String toString() {
    return "$id, $label, $currentPosition";
  }
}
