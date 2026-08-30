import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'newpipe_service.dart';

class AudioPlayerController extends ValueNotifier<int> {
  AudioPlayerController._() : super(0) {
    _player.playerStateStream.listen((state) {
      _playing = state.playing;
      _buffering = state.processingState == ProcessingState.buffering;
      notifyListeners();
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < songs.length) {
        _current = songs[index];
        notifyListeners();
      }
    });
    _player.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });
    _player.durationStream.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });
  }

  static final AudioPlayerController instance = AudioPlayerController._();

  final AudioPlayer _player = AudioPlayer();

  List<Song> songs = [];
  Song? _current;
  bool _playing = false;
  bool _buffering = false;
  bool _loading = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Song? get current => _current;
  bool get isPlaying => _playing;
  bool get isBuffering => _buffering;
  bool get isLoading => _loading;
  String? get error => _error;
  Duration get position => _position;
  Duration get duration => _duration;

  /// Loads [list] as the play queue and starts playing [startIndex].
  Future<void> playQueue(List<Song> list, int startIndex) async {
    if (list.isEmpty) {
      return;
    }
    songs = List.of(list);
    _current = list[startIndex.clamp(0, list.length - 1)];
    _error = null;
    _loading = true;
    notifyListeners();
    await _resolveAndPlay(_current!);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_current == null) {
      return;
    }
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> playNext() async {
    if (songs.isEmpty || _current == null) {
      return;
    }
    final index = songs.indexWhere((s) => s.id == _current!.id);
    final next = (index + 1) % songs.length;
    await _resolveAndPlay(songs[next]);
  }

  Future<void> playPrevious() async {
    if (songs.isEmpty || _current == null) {
      return;
    }
    final index = songs.indexWhere((s) => s.id == _current!.id);
    final prev = (index - 1 + songs.length) % songs.length;
    await _resolveAndPlay(songs[prev]);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> _resolveAndPlay(Song song) async {
    _current = song;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final streamUrl = await NewPipeService.getPlayableUrl(song.watchUrl);
      if (streamUrl == null) {
        _error = 'No audio stream available for "${song.title}".';
        _loading = false;
        notifyListeners();
        return;
      }
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      await _player.play();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to play "${song.title}".';
      _loading = false;
      notifyListeners();
    }
  }
}
