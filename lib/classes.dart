import 'package:nyxx/nyxx.dart';
import 'package:suggestions_plus/data.dart';

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
  Map raw;
  Database({required this.servers, required this.bot, required this.raw});

  Future<void> save() async {
    raw["servers"] = servers.map((Server server) {
      return {
        "id": server.id.value,
        "users": server.users.map((ServerUser user) => user.toMap()),
      };
    });

    await saveRawData(raw);
  }

  Server getServer(Snowflake id) {
    Server? server;
    for (var s in servers) if (s.id == id) server = s;
    if (server != null) return server;

    server = Server(id, settings: ServerSettings.initial, users: []);
    servers.add(server);
    save();
    return server;
  }
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
  Snowflake id;
  Server(this.id, {required this.settings, required this.users});
}

class ServerSettings {
  Snowflake? suggestionsChannel;
  ServerSettings({required this.suggestionsChannel});

  static ServerSettings get initial => ServerSettings(suggestionsChannel: null);

  Map toMap() {
    return {
      "suggestionsChannel": suggestionsChannel,
    };
  }
}

class ServerUser {
  Snowflake id;
  ServerUser(this.id);

  Map toMap() {
    return {
      "id": id.value,
    };
  }
}