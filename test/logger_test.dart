import 'dart:math';

import 'package:logger_test/logger.dart';
import 'package:test/test.dart';

typedef PrinterCallback = List<String> Function(
  Level level,
  dynamic message,
  Object? error,
  StackTrace? stackTrace,
);

class _AlwaysFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _NeverFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class _CallbackPrinter extends LogPrinter {
  final PrinterCallback callback;

  _CallbackPrinter(this.callback);

  @override
  List<String> log(LogEvent event) {
    return callback(
      event.level,
      event.message,
      event.error,
      event.stackTrace,
    );
  }
}

class _AsyncFilter extends LogFilter {
  final Duration delay;
  bool initialized = false;

  _AsyncFilter(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  bool shouldLog(LogEvent event) => false;
}

class _AsyncPrinter extends LogPrinter {
  final Duration delay;
  bool initialized = false;

  _AsyncPrinter(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  List<String> log(LogEvent event) => [event.message.toString()];
}

class _AsyncOutput extends LogOutput {
  final Duration delay;
  bool initialized = false;

  _AsyncOutput(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  void output(OutputEvent event) {
    // No-op.
  }
}

/// Test class for the lazy-initialization of variables.
class LazyLogger {
  static bool? printed;
  static final filter = ProductionFilter();
  static final printer = _CallbackPrinter((l, m, e, s) {
    printed = true;
    return [];
  });
  static final logger_test = Logger(filter: filter, printer: printer);
}

void main() {
  Level? printedLevel;
  dynamic printedMessage;
  dynamic printedError;
  StackTrace? printedStackTrace;
  var callbackPrinter = _CallbackPrinter((l, m, e, s) {
    printedLevel = l;
    printedMessage = m;
    printedError = e;
    printedStackTrace = s;
    return [];
  });

  setUp(() {
    printedLevel = null;
    printedMessage = null;
    printedError = null;
    printedStackTrace = null;
  });

  test('Logger.log', () {
    var logger_test = Logger(filter: _NeverFilter(), printer: callbackPrinter);
    logger_test.log(Level.debug, 'Some message');

    expect(printedMessage, null);

    logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);

    var levels = [
      Level.trace,
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.fatal,
    ];
    for (var level in levels) {
      var message = Random().nextInt(999999999).toString();
      logger_test.log(level, message);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, null);
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      logger_test.log(level, message, error: 'MyError');
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      var stackTrace = StackTrace.current;
      logger_test.log(level, message, error: 'MyError', stackTrace: stackTrace);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, stackTrace);
    }

    expect(
        () => logger_test.log(Level.trace, 'Test', error: StackTrace.current),
        throwsArgumentError);
    expect(() => logger_test.log(Level.off, 'Test'), throwsArgumentError);
    expect(() => logger_test.log(Level.all, 'Test'), throwsArgumentError);
  });

  test('Multiple Loggers', () {
    var logger_test = Logger(level: Level.info, printer: callbackPrinter);
    var secondLogger = Logger(level: Level.debug, printer: callbackPrinter);

    logger_test.log(Level.debug, 'Test');
    expect(printedLevel, null);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);

    secondLogger.log(Level.debug, 'Test');
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Logger.t', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.t('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.trace);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.d', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.d('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.i', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.i('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.info);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.w', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.w('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.warning);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.e', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.e('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.error);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.f', () {
    var logger_test = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger_test.f('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('setting log level above log level of message', () {
    printedMessage = null;
    var logger_test = Logger(
      filter: ProductionFilter(),
      printer: callbackPrinter,
      level: Level.warning,
    );

    logger_test.d('This isn\'t logged');
    expect(printedMessage, isNull);

    logger_test.w('This is');
    expect(printedMessage, 'This is');
  });

  test('Setting filter Levels', () {
    var filter = ProductionFilter();
    expect(filter.level, Logger.level);

    final initLevel = Level.warning;
    // ignore: unused_local_variable
    var logger_test = Logger(
      filter: filter,
      printer: callbackPrinter,
      level: initLevel,
    );
    expect(filter.level, initLevel);

    filter.level = Level.fatal;
    expect(filter.level, Level.fatal);
  });

  test('Logger.close', () async {
    var logger_test = Logger();
    expect(logger_test.isClosed(), false);
    await logger_test.close();
    expect(logger_test.isClosed(), true);
  });

  test('Lazy Logger Initialization', () {
    expect(LazyLogger.printed, isNull);
    LazyLogger.filter.level = Level.warning;
    LazyLogger.logger_test.i("This is an info message and should not show");
    expect(LazyLogger.printed, isNull);
  });

  test('Async Filter Initialization', () async {
    var comp = _AsyncFilter(const Duration(milliseconds: 100));
    var logger_test = Logger(
      filter: comp,
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger_test.init;
    expect(comp.initialized, true);
  });

  test('Async Printer Initialization', () async {
    var comp = _AsyncPrinter(const Duration(milliseconds: 100));
    var logger_test = Logger(
      printer: comp,
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger_test.init;
    expect(comp.initialized, true);
  });

  test('Async Output Initialization', () async {
    var comp = _AsyncOutput(const Duration(milliseconds: 100));
    var logger_test = Logger(
      output: comp,
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger_test.init;
    expect(comp.initialized, true);
  });
}
