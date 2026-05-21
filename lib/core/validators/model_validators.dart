class ModelValidators {
  static void validateRating(double rating, String fieldName) {
    if (rating < 0 || rating > 5) {
      throw ArgumentError('$fieldName deve estar entre 0 e 5');
    }
  }

  static void validateCoordinates(double? lat, double? lon) {
    if (lat != null && (lat < -90 || lat > 90)) {
      throw ArgumentError('Latitude deve estar entre -90 e 90');
    }
    if (lon != null && (lon < -180 || lon > 180)) {
      throw ArgumentError('Longitude deve estar entre -180 e 180');
    }
  }

  static void validateDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null && end.isBefore(start)) {
      throw ArgumentError('Data final não pode ser anterior à data inicial');
    }
  }

  static void validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Email inválido');
    }
  }

  static void validatePositiveNumber(double value, String fieldName) {
    if (value < 0) {
      throw ArgumentError('$fieldName deve ser positivo');
    }
  }

  static void validateNonEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName não pode estar vazio');
    }
  }

  static void validatePercentage(double value, String fieldName) {
    if (value < 0 || value > 100) {
      throw ArgumentError('$fieldName deve estar entre 0 e 100');
    }
  }

  static void validateSplits(Map<String, double> splits, String splitType) {
    if (splits.isEmpty) {
      throw ArgumentError('Divisão não pode estar vazia');
    }

    if (splitType == 'percentage') {
      final total = splits.values.reduce((a, b) => a + b);
      if ((total - 100).abs() > 0.01) {
        throw ArgumentError('Soma das porcentagens deve ser 100%');
      }
    }

    for (var value in splits.values) {
      if (value < 0) {
        throw ArgumentError('Valores de divisão devem ser positivos');
      }
    }
  }
}
