import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String base64Audio, String mimeType, int durationSeconds) onRecordingComplete;
  final VoidCallback onCancel;
  final int maxDurationSeconds;
  final Color primaryColor;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
    this.maxDurationSeconds = 30,
    required this.primaryColor,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // Automatically start recording when widget is built
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _audioRecorder.start(
        RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc),
        path: kIsWeb ? '' : '${Directory.systemTemp.path}/ava_audio_temp.m4a',
      );

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        setState(() => _recordDuration++);
        if (_recordDuration >= widget.maxDurationSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (!_isRecording) return;
    
    setState(() => _isRecording = false);
    
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        Uint8List audioBytes;
        if (kIsWeb) {
          // For web, path is a blob URL
          final response = await http.get(Uri.parse(path));
          audioBytes = response.bodyBytes;
        } else {
          audioBytes = await File(path).readAsBytes();
          // Clean up temp file
          try { File(path).deleteSync(); } catch (_) {}
        }
        
        final base64String = base64Encode(audioBytes);
        // audio/webm for Opus on web, audio/mp4 for AAC on mobile
        widget.onRecordingComplete(base64String, kIsWeb ? 'audio/webm' : 'audio/mp4', _recordDuration);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    setState(() => _isRecording = false);
    try {
      final path = await _audioRecorder.stop();
      if (!kIsWeb && path != null) {
        try { File(path).deleteSync(); } catch (_) {}
      }
    } catch (_) {}
    widget.onCancel();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Blinking mic icon
          FadeTransition(
            opacity: _animationController,
            child: Icon(Icons.mic, color: widget.primaryColor),
          ),
          const SizedBox(width: 8),
          
          // Duration
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              color: widget.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Cancel button (slide to cancel hint)
          TextButton(
            onPressed: _cancelRecording,
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          
          // Stop/Send button
          IconButton(
            icon: Icon(Icons.send, color: widget.primaryColor),
            onPressed: _stopRecording,
          ),
        ],
      ),
    );
  }
}
