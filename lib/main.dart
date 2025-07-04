import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'classes.dart';
import 'data.dart';
import 'functions.dart';

late NyxxGateway client;
late CommandsPlugin commandsPlugin;

List<Command> buildCommands([Server? server]) {
  return [
    ChatCommand(
      'ping',
      "Get the bot's latency",
      (ChatContext context) async {
        String format(Duration latency) {
          return "${(latency.inMicroseconds / Duration.microsecondsPerMillisecond).toStringAsFixed(3)}ms";
        }

        await context.respond(MessageBuilder(embeds: [EmbedBuilder(
          title: "*${context.user.globalName}*, Pong!",
          fields: [
            EmbedFieldBuilder(name: "Basic Latency", value: format(context.client.httpHandler.latency), isInline: false),
            EmbedFieldBuilder(name: "Real Latency", value: format(context.client.httpHandler.realLatency), isInline: false),
            EmbedFieldBuilder(name: "Gateway Latency", value: format(context.client.gateway.latency), isInline: false),
          ],
          timestamp: DateTime.now(),
        )]));
      },
    ),
  ];
}

CommandsPlugin buildCommandsPlugin() {
  log([Log("Building commands for server "), Log("none", effects: [1])]);
  List<Command> commands = buildCommands();
  CommandsPlugin plugin = CommandsPlugin(prefix: null);

  for (Command command in commands) {
    plugin.addCommand(command);
  }

  log([Log("Generated commands plugin of ${commands.length} commands")]);
  return plugin;
}

void main(List<String> arguments) async {
  log([Log("Starting server...")]);
  setupStdinListener();
  await loadData();
  commandsPlugin = buildCommandsPlugin();

  log([Log("Authentication URL: "), Log("https://discord.com/oauth2/authorize?client_id=${database.bot.applicationId}", effects: [1])], ["UriHandler"]);
  log([Log("VM service URL: "), Log((await getServiceUri()), effects: [1])], ["UriHandler"]);

  try {
    client = await Nyxx.connectGateway(
      database.bot.botToken,
      GatewayIntents.allUnprivileged,
      options: GatewayClientOptions(plugins: [logging, cliIntegration, commandsPlugin]),
    );
  } catch (e) {
    error([Log("Error connecting gateway: "), Log(e, effects: [1])]);
    autherror(e, database.raw);
    await quit(-1);
  }

  User bot = await client.users.fetchCurrentUser();

  client.onMessageCreate.listen((event) async {
    if (event.mentions.contains(bot)) {
      event.message.react(ReactionBuilder(name: "🗿", id: null));
    }
  });
}