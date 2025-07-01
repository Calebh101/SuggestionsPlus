import 'package:nyxx/nyxx.dart';

enum LogType {
  standard,
  tab,
}

class Log {
  dynamic input;
  List<int> effects;
  bool _tab;

  LogType get type => _tab ? LogType.tab : LogType.standard;
  Log(this.input, {List<int>? effects}) : effects = List.from(effects ?? []), _tab = false;
  Log.tab() : input = null, effects = [], _tab = true;

  @override
  String toString() {
    return _tab ? "\t" : "${effects.map((int item) => "\x1b[${item}m").join("")}$input${"\x1b[0m"}";
  }
}

class Database {
  List<Server> servers;
  Bot bot;
  Database({required this.servers, required this.bot});
}

class Bot {
  final String applicationId;
  final String publicKey;
  final String botToken;
  final Uri redirectUri;
  const Bot({required this.applicationId, required this.publicKey, required this.botToken, required this.redirectUri});
}

class Server {
  ServerSettings settings;
  List<ServerUser> users;
  String id;
  Server(this.id, {required this.settings, required this.users});
}

class ServerSettings {
  ServerSettings();
}

class ServerUser {
  User user;
  ServerUser(this.user);
}