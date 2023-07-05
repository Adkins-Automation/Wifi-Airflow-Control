class Damper {
  String label;
  List<String> positions;
  int currentPosition;

  Damper(this.label, this.positions, this.currentPosition);

  @override
  String toString() {
    return "$label, ${positions[currentPosition]}";
  }
}
