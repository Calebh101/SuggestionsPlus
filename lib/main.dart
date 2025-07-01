import 'package:nyxx/nyxx.dart';
import 'classes.dart';
import 'data.dart';
import 'functions.dart';

late NyxxGateway client;

void main(List<String> arguments) async {
  log([Log("Starting server...")]);
  setupStdinListener();
  await loadData();

  log([Log("Authentication URL: "), Log("https://discord.com/oauth2/authorize?client_id=${database.bot.applicationId}", effects: [1])], ["UriHandler"]);
  log([Log("VM service URL: "), Log((await getServiceUri()), effects: [1])], ["UriHandler"]);

  client = await Nyxx.connectGateway(
    database.bot.botToken,
    GatewayIntents.allUnprivileged,
    options: GatewayClientOptions(plugins: [logging, cliIntegration]),
  );

  User bot = await client.users.fetchCurrentUser();

  client.onMessageCreate.listen((event) async {
    if (event.mentions.contains(bot)) {
      event.message.react(ReactionBuilder(name: "🗿", id: null));
    }
  });
}