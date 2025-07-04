import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:suggestions_plus/classes.dart';
import 'package:suggestions_plus/main.dart';
import 'package:hotreloader/hotreloader.dart';

bool useReloader = false;
bool showingInput = false;
HotReloader? reloader;

Future<void> setupStdinListener() async {
  stdin.echoMode = false;
  stdin.lineMode = false;

  try {
    if (useReloader) {
      reloader = await HotReloader.create();
    } else {
      throw Exception("Reloader is disabled.");
    }
  } catch (e) {
    log([Log("Not using reloader: "), Log(e, effects: [1])], ["Stdin", "Listener"]);
  }

  stdin.listen((List<int> data) async {
    for (int byte in data) {
      String char = utf8.decode([byte]);
      switch (char) {
        case "q": quit(0);
        case "r": 
          if (useReloader) {
            reloadApplication();
          } else {
            restartApplication();
          }
          break;
        case "R":
          await restartApplication();
      }
    }
  });
}

Future<Uri?> getServiceUri() async {
  Uri? uri = (await Service.getInfo()).serverUri;
  if (uri == null) warn([Log("No service URI was found.")]);
  return uri;
}

Future<Never> restartApplication() async {
  log([Log("Starting restart...")], ["Reloader"]);
  await quit(249);
}

Future<void> reloadApplication() async {
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

List<Log> buildPrefix(Log prefix, List<String> from) {
  return [Log("[${DateTime.now().toIso8601String().replaceFirst('T', ' ')}] ["), Log(prefix.input.toString().toUpperCase(), effects: [...prefix.effects]), Log("] [${from.join(".")}]")];
}

void log(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${logsToString(buildPrefix(Log("info"), from))} ${logsToString(logs)}");
}

void warn(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${logsToString(buildPrefix(Log("warn", effects: [33]), from))} ${logsToString(logs, [33])}");
}

void error(List<Log> logs, [List<String> from = const ["Main"]]) {
  print("${logsToString(buildPrefix(Log("errr", effects: [31]), from))} ${logsToString(logs, [1, 31])}");
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
  warn([Log("Closing process with code "), Log(code, effects: [1, (code == 0 ? 32 : 33)]), Log("...")], ["Closer"]);
  await reloader?.stop();
  try {
    await client.close();
  } catch (e) {
    log([Log("Unable to close client: "), Log(e, effects: [1])], ["Closer"]);
  }
  exit(code);
}