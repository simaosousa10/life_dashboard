import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserMessageException implements Exception {
  const AppUserMessageException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyErrorMessage(Object error) {
  if (error is AppUserMessageException) {
    return error.message;
  }

  if (error is AuthException) {
    return _authErrorMessage(error.message);
  }

  if (error is PostgrestException) {
    return _databaseErrorMessage(error);
  }

  if (error is FormatException) {
    return 'Ha dados num formato inesperado. Atualiza a pagina e tenta novamente.';
  }

  return 'Nao foi possivel concluir a operacao. Verifica a ligacao e tenta novamente.';
}

String _authErrorMessage(String message) {
  final normalized = message.toLowerCase();

  if (normalized.contains('invalid login credentials')) {
    return 'Email ou password incorretos.';
  }
  if (normalized.contains('email not confirmed')) {
    return 'Confirma o email antes de entrar.';
  }
  if (normalized.contains('user already registered') ||
      normalized.contains('already registered')) {
    return 'Ja existe uma conta com este email.';
  }
  if (normalized.contains('password')) {
    return 'A password nao cumpre os requisitos.';
  }
  if (normalized.contains('rate limit')) {
    return 'Foram feitas demasiadas tentativas. Espera um pouco e tenta novamente.';
  }

  return message;
}

String _databaseErrorMessage(PostgrestException error) {
  final code = error.code;
  final message = error.message.toLowerCase();

  if (code == '42501' || message.contains('row-level security')) {
    return 'Sem permissao para aceder a estes dados. Volta a entrar na conta.';
  }
  if (code == '23514') {
    return 'Alguns valores nao sao validos. Revê o formulario e tenta novamente.';
  }
  if (code == '23503') {
    return 'A sessao ja nao e valida. Volta a entrar na conta.';
  }
  if (code == '23505') {
    return 'Este registo ja existe.';
  }
  if (message.contains('jwt') || message.contains('token')) {
    return 'A sessao ja nao e valida. Volta a entrar na conta.';
  }

  return 'Erro ao comunicar com a base de dados. Tenta novamente.';
}
