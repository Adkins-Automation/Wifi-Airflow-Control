class Damper {
  String id;
  String label;
  int currentPosition;
  int? lastHeartbeat;

  Damper(this.id, this.label, this.currentPosition, this.lastHeartbeat);

  bool isOnline() {
    return (lastHeartbeat != null &&
        (DateTime.now().millisecondsSinceEpoch - lastHeartbeat!) <=
            6 * 60 * 1000);
  }

  @override
  String toString() {
    return "$id, $label, $currentPosition";
  }
}
