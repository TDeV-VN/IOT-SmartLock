import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;
  final String broker = 'b51a9ea272b54ffe828ac0fd37e4b087.s1.eu.hivemq.cloud';
  final String clientIdentifier = 'flutter_client';

  Future<void> connect() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.secure = true;
    client.setProtocolV311();
    client.port = 8883;
    client.keepAlivePeriod = 60;

    final connMess = MqttConnectMessage()
        .authenticateAs('flutter_client', '12345678Tt')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMess;


    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      disconnect();
    }
  }

  void onConnected() => print('Connected to MQTT broker');
  void onDisconnected() => print('Disconnected');
  void onSubscribed(String topic) => print('Subscribed to topic: $topic');

  void disconnect() {
    client.disconnect();
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void Function(String)? onMessageReceived;

  void listenToTopic(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
      MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received on ${c[0].topic}: $payload');

      if (onMessageReceived != null) {
        onMessageReceived!(payload);
      }
    });
  }

}
