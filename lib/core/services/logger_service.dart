import 'package:logger/logger.dart';

// Create a global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1, // Number of method calls to be displayed
    errorMethodCount: 5, // Number of method calls if stacktrace is provided
    lineLength: 120, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    dateTimeFormat:
        DateTimeFormat.none, // Should each log print contain a timestamp
  ),
);
