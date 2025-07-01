import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:suggestions_plus/classes.dart';
import 'package:suggestions_plus/main.dart';
import 'package:hotreloader/hotreloader.dart';

bool showingInput = false;
HotReloader? reloader;

Future<void> setupStdinListener() async {
  stdin.echoMode = false;
  stdin.lineMode = false;

  try {
    reloader = await HotReloader.create();
  } catch (e) {
    log([Log("Failed to load HotReloader: "), Log(e, effects: [1])]);
  }

  stdin.listen((List<int> data) async {
    for (int byte in data) {
      String char = utf8.decode([byte]);
      switch (char) {
        case "q": quit(0);
        case "r": if (reloader != null) reload(); break;
      }
    }
  });
}

Future<Uri?> getServiceUri() async {
  Uri? uri = (await Service.getInfo()).serverUri;
  if (uri == null) warn([Log("No service URI was found.")]);
  return uri;
}

Future<void> reload() async {
  try {
    log([Log("Starting reload...")]);
    DateTime start = DateTime.now();
    await reloader!.reloadCode();
    log([Log("Reloaded in "), Log(DateTime.now() - start, effects: [1]), Log(" milliseconds")]);
  } catch (e) {
    error([Log("Error reloading: "), Log(e, effects: [1])]);
  }
}

extension on DateTime {
  int operator -(DateTime other) {
    return millisecondsSinceEpoch - other.millisecondsSinceEpoch;
  }
}

String logsToString(List<Log> logs, [List<int> effects = const []]) {
  return logs.map((Log item) => (item..effects.addAll(effects)).toString()).join("");
}

String buildPrefix(String prefix, List<String> from) {
  return "[${DateTime.now().toIso8601String().replaceFirst('T', ' ')}] [${prefix.toUpperCase()}] [${from.join(".")}]";
}

void log(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${buildPrefix("info", from)} ${logsToString(logs)}");
}

void warn(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${buildPrefix("warn", from)} ${logsToString(logs, [33])}");
}

void error(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${buildPrefix("errr", from)} ${logsToString(logs, [1, 31])}");
}

String? ask(List<Log> question, {bool bold = false, bool newline = true}) {
  showingInput = true;
  if (newline) linebreak();
  stdout.write("${logsToString(question, [if (bold) 1])} > ");
  String? out = stdin.readLineSync();
  if (newline) linebreak();
  showingInput = false;
  return out?.trim();
}

bool yesNo(List<Log> question, {bool bold = false, bool newline = true}) {
  showingInput = true;
  bool status = false;
  if (newline) linebreak();
  stdout.write("${logsToString([...question, Log(" (y/n)")], [if (bold) 1])} > ");
  String? input = stdin.readLineSync();
  if (newline) linebreak();

  if (input == null) {
    status = false;
  } else {
    status = true;
    switch (input.toLowerCase()) {
      case "y":
      case "1":
      case "yes":
        break;
      default:
        status = false;
        break;
    }
  }

  showingInput = false;
  return status;
}

void linebreak() {
  stdout.writeln("");
}

Future<Never> quit([int code = 0]) async {
  warn([Log("Closing process with code "), Log(code, effects: [1, (code == 0 ? 32 : 33)]), Log("...")], ["Quit"]);
  await client.close();
  exit(code);
}