import 'package:logger/logger.dart';

/// 🚀 GLOBAL LOGGER
/// Custom configured logger for the entire application.
/// Uses the 'logger' package to provide beautiful, color-coded console output.
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2, // Number of method calls in the stack trace
    errorMethodCount: 8, // Stack trace depth for errors
    lineLength: 100, // Width of the output
    colors: true, // Enable colors for better readability
    printEmojis: true, // Use emojis to distinguish log levels
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  // Only log if we are in debug mode to protect production performance
  filter: DevelopmentFilter(),
);

/// 📈 APP LOG CLASS
/// A wrapper for more structured logging across the app.
class AppLog {
  static void d(String message) => logger.d(message);
  static void i(String message) => logger.i(message);
  static void w(String message) => logger.w(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) =>
      logger.e(message, error: error, stackTrace: stackTrace);
  static void t(String message) => logger.t(message);
  static void f(String message) => logger.f(message);
}
