import 'dart:convert';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:path/path.dart' as p;

import 'classes.dart';
import 'functions.dart';

Directory root = Directory.current;
File dataFile = File("${root.path}/data/data.json");
late Database database;

Database getData() {
  return database;
}

Future<Database> loadData() async {
  File pubspec = File(p.join(root.path, "pubspec.yaml"));
  Map<String, dynamic> defaultData = {"servers": [], "client" : {}};

  try {
    if (!(await pubspec.exists())) {
      throw Exception("Directory ${root.path} was not found as a valid Dart project. ($pubspec)");
    }

    if (!(await dataFile.exists())) {
      log([Log("Creating missing data file...")]);
      await dataFile.parent.create(recursive: true);
      await dataFile.create();
      await dataFile.writeAsString(jsonEncode(defaultData));
    }

    Map data = await (() async {
      try {
        return jsonDecode(await dataFile.readAsString()) ?? defaultData;
      } catch (e) {
        return defaultData;
      }
    })();

    Map client = data["client"];

    Bot bot = await (() async {
      try {
        List<String> nullKeys = ["Application.applicationId", "Auth.clientSecret", "Application.publicKey", "Bot.botToken", "Auth.redirectUri"].where((item) => client[item.split(".")[1]] == null).toList();
        if (nullKeys.isNotEmpty) linebreak();

        for (List<String> key in nullKeys.map((String item) => item.split("."))) {
          client[key[1]] = ask([Log("Please enter the credential "), Log("${key[0]}.${key[1]}", effects: [1])], newline: false);
          File("${root.path}/data/backupCredentials.json").writeAsString(jsonEncode(client));
        }

        if (nullKeys.isNotEmpty) linebreak();
        data["client"] = client;
        saveRawData(data);
        return Bot(applicationId: client["applicationId"]!, publicKey: client["publicKey"]!, botToken: client["botToken"]!, redirectUri: Uri.parse(client["redirectUri"]!));
      } catch (e) {
        error([Log("Client verification failed: $e")]);
        autherror(e, data);
        await quit(1);
      }
    })();

    Database db = Database(servers: [], bot: bot, raw: data);

    for (Map<String, dynamic> server in data["servers"]) {
      Map settings = server["settings"];
      db.servers.add(Server(Snowflake(server["id"]), settings: ServerSettings(suggestionsChannel: settings["suggestionsChannel"] == null ? null : Snowflake(settings["suggestionsChannel"])), users: (server["users"] as List<Map>).map((Map user) => ServerUser(Snowflake(user["id"]))).toList()));
    }

    database = db;
    return db;
  } catch (e) {
    error([Log("Unable to load data: $e")]);
    await quit(1);
  }
}

Future<void> saveRawData(Map data) async {
  dataFile.writeAsString(jsonEncode(data));
}

Future<void> autherror(Object? error, Map data) async {
  if (yesNo([Log("Client verification may have failed. Do you want to clear client authentication credentials?")])) {
    data["client"] = {};
    await saveRawData(data);
  }
}