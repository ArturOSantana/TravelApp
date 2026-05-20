/// Exceções customizadas para o Travel App
///
/// Este arquivo centraliza todas as exceções do aplicativo,
/// facilitando o tratamento de erros e debugging.

/// Exceção base para todas as exceções do app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exceções de autenticação
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});

  factory AuthException.invalidCredentials() {
    return AuthException(
      'Email ou senha incorretos',
      code: 'invalid-credentials',
    );
  }

  factory AuthException.userNotFound() {
    return AuthException(
      'Usuário não encontrado',
      code: 'user-not-found',
    );
  }

  factory AuthException.emailAlreadyInUse() {
    return AuthException(
      'Este email já está em uso',
      code: 'email-already-in-use',
    );
  }

  factory AuthException.weakPassword() {
    return AuthException(
      'A senha deve ter pelo menos 6 caracteres',
      code: 'weak-password',
    );
  }

  factory AuthException.invalidEmail() {
    return AuthException(
      'Email inválido',
      code: 'invalid-email',
    );
  }

  factory AuthException.userDisabled() {
    return AuthException(
      'Esta conta foi desabilitada',
      code: 'user-disabled',
    );
  }

  factory AuthException.tooManyRequests() {
    return AuthException(
      'Muitas tentativas. Tente novamente mais tarde',
      code: 'too-many-requests',
    );
  }

  factory AuthException.networkError() {
    return AuthException(
      'Erro de conexão. Verifique sua internet',
      code: 'network-error',
    );
  }
}

/// Exceções de validação
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
  });

  factory ValidationException.invalidDate(String field) {
    return ValidationException(
      'Data inválida',
      fieldErrors: {field: 'Data inválida'},
      code: 'invalid-date',
    );
  }

  factory ValidationException.dateRangeInvalid() {
    return ValidationException(
      'A data de início deve ser anterior à data de término',
      code: 'invalid-date-range',
    );
  }

  factory ValidationException.emptyField(String field) {
    return ValidationException(
      'Campo obrigatório',
      fieldErrors: {field: 'Este campo é obrigatório'},
      code: 'empty-field',
    );
  }

  factory ValidationException.invalidValue(String field, String reason) {
    return ValidationException(
      'Valor inválido',
      fieldErrors: {field: reason},
      code: 'invalid-value',
    );
  }
}

/// Exceções de rede/API
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  factory NetworkException.timeout() {
    return NetworkException(
      'Tempo de conexão esgotado',
      code: 'timeout',
    );
  }

  factory NetworkException.noConnection() {
    return NetworkException(
      'Sem conexão com a internet',
      code: 'no-connection',
    );
  }

  factory NetworkException.serverError([int? statusCode]) {
    return NetworkException(
      'Erro no servidor. Tente novamente mais tarde',
      statusCode: statusCode,
      code: 'server-error',
    );
  }

  factory NetworkException.notFound() {
    return NetworkException(
      'Recurso não encontrado',
      statusCode: 404,
      code: 'not-found',
    );
  }

  factory NetworkException.unauthorized() {
    return NetworkException(
      'Não autorizado',
      statusCode: 401,
      code: 'unauthorized',
    );
  }

  factory NetworkException.apiKeyInvalid() {
    return NetworkException(
      'Chave de API inválida',
      statusCode: 403,
      code: 'invalid-api-key',
    );
  }

  factory NetworkException.rateLimitExceeded() {
    return NetworkException(
      'Limite de requisições excedido. Tente novamente mais tarde',
      statusCode: 429,
      code: 'rate-limit-exceeded',
    );
  }
}

/// Exceções de armazenamento
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});

  factory StorageException.uploadFailed() {
    return StorageException(
      'Falha ao enviar arquivo',
      code: 'upload-failed',
    );
  }

  factory StorageException.deleteFailed() {
    return StorageException(
      'Falha ao deletar arquivo',
      code: 'delete-failed',
    );
  }

  factory StorageException.fileTooLarge() {
    return StorageException(
      'Arquivo muito grande',
      code: 'file-too-large',
    );
  }

  factory StorageException.invalidFileType() {
    return StorageException(
      'Tipo de arquivo não suportado',
      code: 'invalid-file-type',
    );
  }
}

/// Exceções de permissão
class PermissionException extends AppException {
  PermissionException(super.message, {super.code});

  factory PermissionException.locationDenied() {
    return PermissionException(
      'Permissão de localização negada',
      code: 'location-denied',
    );
  }

  factory PermissionException.cameraDenied() {
    return PermissionException(
      'Permissão de câmera negada',
      code: 'camera-denied',
    );
  }

  factory PermissionException.notificationsDenied() {
    return PermissionException(
      'Permissão de notificações negada',
      code: 'notifications-denied',
    );
  }
}

/// Exceções de limite/assinatura
class SubscriptionException extends AppException {
  SubscriptionException(super.message, {super.code});

  factory SubscriptionException.limitReached(String feature) {
    return SubscriptionException(
      'Limite de $feature atingido. Faça upgrade para Premium',
      code: 'limit-reached',
    );
  }

  factory SubscriptionException.featureNotAvailable() {
    return SubscriptionException(
      'Este recurso está disponível apenas para usuários Premium',
      code: 'premium-only',
    );
  }
}

/// Exceções de cache
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.originalError});

  factory CacheException.readFailed() {
    return CacheException(
      'Falha ao ler cache',
      code: 'cache-read-failed',
    );
  }

  factory CacheException.writeFailed() {
    return CacheException(
      'Falha ao salvar cache',
      code: 'cache-write-failed',
    );
  }
}

/// Exceção genérica para erros não categorizados
class GenericException extends AppException {
  GenericException(super.message, {super.code, super.originalError});
}

// Made with Bob
