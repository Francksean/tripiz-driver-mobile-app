/// Utilitaire de logs colorés (ANSI) pour repérer facilement
/// les erreurs et succès au milieu de logs nombreux.
class Log {
  static const _reset = '\x1B[0m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _cyan = '\x1B[36m';

  static void error(String msg) => print('$_red🔴 ERREUR: $msg$_reset');
  static void success(String msg) => print('$_green✅ SUCCÈS: $msg$_reset');
  static void warning(String msg) => print('$_yellow⚠️  $msg$_reset');
  static void info(String msg) => print('$_cyan ℹ️  $msg$_reset');
}