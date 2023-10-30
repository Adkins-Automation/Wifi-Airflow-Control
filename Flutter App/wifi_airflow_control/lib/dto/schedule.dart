class Schedule {
  int time, days, position;
  Schedule(this.time, this.days, this.position);

  // Bitwise values for each day
  static const int monday = 1; // 2^0
  static const int tuesday = 2; // 2^1
  static const int wednesday = 4; // 2^2
  static const int thursday = 8; // 2^3
  static const int friday = 16; // 2^4
  static const int saturday = 32; // 2^5
  static const int sunday = 64; // 2^6
  static const int everyday = 127; // 2^7 - 1

  // Helper function to get bitwise values for each day
  static int getDay(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return monday;
      case 1:
        return tuesday;
      case 2:
        return wednesday;
      case 3:
        return thursday;
      case 4:
        return friday;
      case 5:
        return saturday;
      case 6:
        return sunday;
      case 7:
        return everyday;
      default:
        return 0;
    }
  }

  // Helper function to set a specific day
  void setDay(int dayValue) {
    days = days | dayValue;
  }

  // Helper function to check if a specific day is set
  bool isDaySet(int dayValue) {
    return (days & dayValue) == dayValue;
  }

  // Helper function to unset a specific day
  void unsetDay(int dayValue) {
    days = days & ~dayValue;
  }
}
