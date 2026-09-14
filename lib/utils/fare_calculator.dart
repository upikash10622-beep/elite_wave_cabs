class FareCalculator {
  // ============================================================
  // 1. ACTING DRIVER
  // ============================================================

  static double actingDriverFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 8;
  }

  static double actingDriverWaitingFare(
    double waitingHours,
  ) {
    if (waitingHours <= 0) {
      return 0;
    }

    return waitingHours * 20;
  }

  static double actingDriverTotalFare(
    double distanceKm, {
    double waitingHours = 0,
  }) {
    return actingDriverFare(distanceKm) +
        actingDriverWaitingFare(
          waitingHours,
        );
  }

  static String actingDriverFareText(
    double distanceKm,
  ) {
    return '₹${actingDriverFare(distanceKm).toStringAsFixed(0)}';
  }

  static String actingDriverWaitingFareText(
    double waitingHours,
  ) {
    return '₹${actingDriverWaitingFare(waitingHours).toStringAsFixed(0)}';
  }

  static String actingDriverTotalFareText(
    double distanceKm, {
    double waitingHours = 0,
  }) {
    return '₹${actingDriverTotalFare(
      distanceKm,
      waitingHours: waitingHours,
    ).toStringAsFixed(0)}';
  }

  // ============================================================
  // 2. MINI - LOCAL
  //
  // First 3 KM = ₹100
  // Every additional 1 KM = ₹20
  // ============================================================

  static double calculateMiniFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    if (distanceKm <= 3) {
      return 100;
    }

    final int additionalKm =
        (distanceKm - 3).ceil();

    return 100 + (additionalKm * 20);
  }

  static String miniFareText(
    double distanceKm,
  ) {
    return '₹${calculateMiniFare(distanceKm).toStringAsFixed(0)}';
  }

  // ============================================================
  // 3. SEDAN - LOCAL
  // ============================================================

  static double sedanLocalFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 25;
  }

  static String sedanLocalFareText(
    double distanceKm,
  ) {
    return '₹${sedanLocalFare(distanceKm).toStringAsFixed(0)}';
  }

  // ============================================================
  // 4. SEDAN - OUTSTATION
  // ============================================================

  static double sedanAcFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 16;
  }

  static double sedanNonAcFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 15;
  }

  static String sedanAcFareText(
    double distanceKm,
  ) {
    return '₹${sedanAcFare(distanceKm).toStringAsFixed(0)}';
  }

  static String sedanNonAcFareText(
    double distanceKm,
  ) {
    return '₹${sedanNonAcFare(distanceKm).toStringAsFixed(0)}';
  }

  // ============================================================
  // 5. SUV - OUTSTATION
  // ============================================================

  static double suvAcFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 19;
  }

  static double suvNonAcFare(
    double distanceKm,
  ) {
    if (distanceKm <= 0) {
      return 0;
    }

    return distanceKm * 18;
  }

  static String suvAcFareText(
    double distanceKm,
  ) {
    return '₹${suvAcFare(distanceKm).toStringAsFixed(0)}';
  }

  static String suvNonAcFareText(
    double distanceKm,
  ) {
    return '₹${suvNonAcFare(distanceKm).toStringAsFixed(0)}';
  }
}