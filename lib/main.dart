import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const AudioEnhancerApp());
}

class AudioEnhancerApp extends StatelessWidget {
  const AudioEnhancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrystalClear AI Audio Enhancer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const AudioEnhancerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AudioEnhancerScreen extends StatefulWidget {
  const AudioEnhancerScreen({super.key});

  @override
  State<AudioEnhancerScreen> createState() => _AudioEnhancerScreenState();
}

class _AudioEnhancerScreenState extends State<AudioEnhancerScreen> with SingleTickerProviderStateMixin {
  // File management
  PlatformFile? _currentFile;
  PlatformFile? _enhancedFile;
  
  // Audio playback
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  
  // Enhancement
  bool _isEnhancing = false;
  double _progress = 0.0;
  CancelToken? _cancelToken;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Waveform data
  List<double> _waveformData = [];
  bool _isWaveformLoading = false;

  static const String _apiUrl = 'https://abid1012-audio-enhancement.hf.space/direct-enhance';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    // Setup player state listener
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    
    // Listen to position updates
    _player.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
    
    // Listen to duration updates
    _player.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration ?? Duration.zero;
        });
      }
    });
    
    // Listen for audio completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
        _player.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.dispose();
    _animationController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && mounted) {
        // Stop any current playback
        await _player.stop();
        _currentPosition = Duration.zero;
        
        setState(() {
          _currentFile = result.files.first;
          _enhancedFile = null;
          _waveformData = [];
          _totalDuration = Duration.zero;
        });
        
        // Load the new audio file
        await _player.setFilePath(_currentFile!.path!);
        
        // Generate waveform data
        await _generateWaveformData(_currentFile!.path!);
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
    }
  }

  Future<void> _generateWaveformData(String filePath) async {
    setState(() {
      _isWaveformLoading = true;
    });
    
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      // Simple waveform generation - in production, use a proper audio processing library
      // This creates simulated waveform data based on file size
      final sampleCount = 100;
      final random = math.Random(42); // Fixed seed for consistency
      
      final data = List<double>.generate(sampleCount, (_) {
        return random.nextDouble();
      });
      
      if (mounted) {
        setState(() {
          _waveformData = data;
          _isWaveformLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating waveform: $e');
      if (mounted) {
        setState(() {
          _isWaveformLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_currentFile == null && _enhancedFile == null) {
        _showSnackBar('No audio loaded');
        return;
      }
      await _player.play();
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    setState(() {
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _showSnackBar('Microphone permission required');
        return;
      }

      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
        
        _showSnackBar('Recording started');
      }
    } catch (e) {
      _showSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      
      if (path != null && mounted) {
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          
          // Stop any current playback before loading new recording
          await _player.stop();
          _currentPosition = Duration.zero;
          
          setState(() {
            _currentFile = PlatformFile(
              name: 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
              path: path,
              size: fileSize,
            );
            _enhancedFile = null;
            _isRecording = false;
            _waveformData = [];
            _totalDuration = Duration.zero;
          });
          
          await _player.setFilePath(path);
          await _generateWaveformData(path);
          _showSnackBar('Recording saved');
        }
      } else {
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _enhance() async {
    if (_currentFile == null) {
      _showSnackBar('Please select an audio file first');
      return;
    }

    setState(() {
      _isEnhancing = true;
      _progress = 0.0;
    });

    _cancelToken = CancelToken();
    final dio = Dio();

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_currentFile!.path!, filename: _currentFile!.name),
      });

      final response = await dio.post<List<int>>(
        _apiUrl,
        data: formData,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: _cancelToken!,
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = sent / total);
          }
        },
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (response.data != null && mounted) {
        final bytes = response.data!;
        final tempDir = await getTemporaryDirectory();
        final enhancedPath = '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.wav';
        final file = await File(enhancedPath).writeAsBytes(bytes);
        
        setState(() {
          _enhancedFile = PlatformFile(
            name: 'enhanced_audio.wav',
            path: enhancedPath,
            size: file.lengthSync(),
          );
        });
        
        _showSnackBar('Enhancement complete!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Enhance failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }

  Future<void> _saveToDownloads() async {
    if (_enhancedFile == null) return;

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSnackBar('Storage permission required');
          return;
        }
      }

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        // For Android, use the Downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          // Fallback to external storage
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        // For iOS, use documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        _showSnackBar('Could not access downloads folder');
        return;
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'enhanced_audio_$timestamp.wav';
      final savePath = '${downloadsDir.path}/$fileName';

      // Copy file to downloads
      final sourceFile = File(_enhancedFile!.path!);
      final destFile = await sourceFile.copy(savePath);

      if (await destFile.exists()) {
        _showSnackBar('File saved to Downloads folder: $fileName');
      } else {
        _showSnackBar('Failed to save file');
      }
    } catch (e) {
      _showSnackBar('Error saving file: $e');
    }
  }

  void _loadEnhancedAudio() async {
    if (_enhancedFile == null) return;
    
    // Stop current playback
    await _player.stop();
    _currentPosition = Duration.zero;
    
    // Load enhanced audio
    await _player.setFilePath(_enhancedFile!.path!);
    await _generateWaveformData(_enhancedFile!.path!);
    
    setState(() {
      _totalDuration = Duration.zero; // Will be updated by stream
    });
    
    _showSnackBar('Enhanced audio loaded');
  }

  Widget _buildWaveform() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Waveform visualization
            if (_isWaveformLoading)
              const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_waveformData.isNotEmpty)
              CustomPaint(
                painter: WaveformPainter(
                  waveformData: _waveformData,
                  currentPosition: _currentPosition,
                  totalDuration: _totalDuration,
                  isPlaying: _isPlaying,
                ),
                size: const Size(double.infinity, 120),
              )
            else if (_currentFile != null)
              const Center(
                child: Text(
                  'Waveform preview not available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              const Center(
                child: Text(
                  'No audio loaded',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            
            // Recording indicator
            if (_isRecording)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: Color.lerp(Colors.red, Colors.orange, _animation.value),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'REC',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            // Playback position indicator
            if (_totalDuration.inMilliseconds > 0 && _waveformData.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: _totalDuration.inMilliseconds > 0 
                          ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
                          : 0,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    // Time indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: const TextStyle(color: Colors.blue, fontSize: 10),
                        ),
                        Text(
                          _formatDuration(_totalDuration),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _cancelEnhance() {
    _cancelToken?.cancel();
    setState(() => _isEnhancing = false);
    _showSnackBar('Enhancement cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CrystalClear AI Audio Enhancer'),
        backgroundColor: const Color(0xFF0B1120),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInputCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEnhanceCard()),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInputCard(),
                    const SizedBox(height: 16),
                    _buildEnhanceCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Input Audio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select File'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
                    ),
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(_isRecording ? 'Stop' : 'Record'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: (_currentFile != null || _enhancedFile != null) ? _togglePlay : null,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: (_currentFile != null || _enhancedFile != null) ? Colors.blue : Colors.grey,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _isPlaying ? _stopPlayback : null,
                  icon: Icon(
                    Icons.stop_circle,
                    color: _isPlaying ? Colors.red : Colors.grey,
                    size: 48,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWaveform(),
            if (_currentFile != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audio_file, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentFile!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(_currentFile!.size! / 1024 / 1024).toStringAsFixed(1)} MB',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Enhancement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isEnhancing || _currentFile == null ? null : _enhance,
                    icon: _isEnhancing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isEnhancing ? 'Enhancing...' : 'Enhance Audio'),
                  ),
                ),
                if (_isEnhancing) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _cancelEnhance,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ],
              ],
            ),
            if (_isEnhancing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_enhancedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Enhanced Audio Ready',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${(_enhancedFile!.size! / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loadEnhancedAudio,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Load & Play'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveToDownloads,
                            icon: const Icon(Icons.download),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;

  WaveformPainter({
    required this.waveformData,
    required this.currentPosition,
    required this.totalDuration,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final playedPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;

    // Calculate played percentage
    final playedPercentage = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final barHeight = waveformData[i] * size.height * 0.4;
      
      // Determine if this bar is in the played portion
      final barPosition = i / waveformData.length;
      final isPlayed = barPosition <= playedPercentage;
      
      // Draw bar
      final barPaint = isPlayed ? playedPaint : paint;
      
      canvas.drawRect(
        Rect.fromLTRB(
          x + 1,
          centerY - barHeight / 2,
          x + barWidth - 1,
          centerY + barHeight / 2,
        ),
        barPaint,
      );
    }

    // Draw playhead if playing
    if (isPlaying && playedPercentage > 0) {
      final playheadPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final playheadX = size.width * playedPercentage;
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.currentPosition != currentPosition ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.isPlaying != isPlaying;
  }
}