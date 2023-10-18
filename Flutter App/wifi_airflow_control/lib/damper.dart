class Damper {
  String id;
  String label;
  int currentPosition;

  Damper(this.id, this.label, this.currentPosition);

  @override
  String toString() {
    return "$id, $label, $currentPosition";
  }
}
