class Damper {
  String label;
  int currentPosition;

  Damper(this.label, this.currentPosition);

  @override
  String toString() {
    return "$label, $currentPosition";
  }
}
