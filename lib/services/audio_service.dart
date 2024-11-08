import 'package:just_audio/just_audio.dart';

class AudioService {
  final player = AudioPlayer();

  Future<void> playAudio(String url) async {
    try {
      await player.setUrl(url);
      await player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> stopAudio() async {
    await player.stop();
  }

  void dispose() {
    player.dispose();
  }
}
