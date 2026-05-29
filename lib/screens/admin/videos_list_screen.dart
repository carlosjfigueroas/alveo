import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../services/app_provider.dart';
import '../../services/app_localizations.dart';
import '../../services/supabase_service.dart';
import '../../models/instructional_video.dart';
import '../../widgets/admin_drawer.dart';
import '../../services/app_themes.dart';

class VideosListScreen extends StatefulWidget {
  const VideosListScreen({super.key});

  @override
  State<VideosListScreen> createState() => _VideosListScreenState();
}

class _VideosListScreenState extends State<VideosListScreen> {
  final _service = SupabaseService();
  List<InstructionalVideo> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final list = await _service.getInstructionalVideos();
      setState(() => _videos = list);
    } catch (e) {
      debugPrint('[VideosListScreen] Error loading videos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('error_generic')} $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _playVideo(InstructionalVideo video) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VideoPlayerDialog(video: video),
    );
  }

  void _showEditorDialog({InstructionalVideo? video}) {
    showDialog(
      context: context,
      builder: (context) => _VideoEditorDialog(
        video: video,
        onSaved: _loadVideos,
      ),
    );
  }

  Future<void> _deleteVideo(InstructionalVideo video) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_video_q')),
        content: Text(l10n.get('delete_video_body', [video.title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteInstructionalVideo(video.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('video_deleted_success')), backgroundColor: Colors.green),
          );
        }
        _loadVideos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.get('error_generic')} $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final isSuperAdmin = appProvider.isSuperAdmin;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSpanish = appProvider.locale.languageCode == 'es';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('videos_tutoriales')),
        centerTitle: true,
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showEditorDialog(),
              icon: const Icon(Icons.add),
              label: Text(l10n.get('new_video')),
              backgroundColor: AppThemes.primaryGreen,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.get('no_videos'),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: GridView.builder(
                        itemCount: _videos.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.4,
                        ),
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Thumbnail area with play button overlay
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!]
                                            : [Colors.grey[200]!, Colors.grey[350]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.video_collection,
                                          size: 64,
                                          color: isDark ? Colors.white12 : Colors.black12,
                                        ),
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _playVideo(video),
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    size: 40,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isSuperAdmin)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: Colors.black54,
                                                  radius: 18,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                                    onPressed: () => _showEditorDialog(video: video),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                CircleAvatar(
                                                  backgroundColor: Colors.black54,
                                                  radius: 18,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                    onPressed: () => _deleteVideo(video),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Nº ${video.orderIndex}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Text area
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        video.description ?? (isSpanish ? 'Sin descripción.' : 'No description.'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REPRODUCTOR DE VIDEO
// ═════════════════════════════════════════════════════════════════════════════

class _VideoPlayerDialog extends StatefulWidget {
  final InstructionalVideo video;

  const _VideoPlayerDialog({required this.video});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _errorMessage;
  bool _isFullscreen = false;

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Move initialization here to safely access AppLocalizations context
    if (!_initialized && _errorMessage == null) {
      final l10n = AppLocalizations.of(context);
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            _controller.addListener(_videoListener);
            setState(() {
              _initialized = true;
              _controller.play();
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _errorMessage = l10n.get('video_load_error', [error.toString()]);
            });
          }
        });
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.removeListener(_videoListener);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: _isFullscreen ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_isFullscreen ? 0 : 16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: _isFullscreen ? size.width : null,
        height: _isFullscreen ? size.height : null,
        constraints: _isFullscreen ? null : const BoxConstraints(maxWidth: 900),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_initialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const CircularProgressIndicator(color: Colors.white),

              // Buffering indicator overlay
              if (_initialized && _controller.value.isBuffering)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 30,
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  ),
                ),

              // Controls overlay
              if (_initialized)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          if (!_controller.value.isPlaying && !_controller.value.isBuffering)
                            const Center(
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 30,
                                child: Icon(Icons.play_arrow, size: 40, color: Colors.white),
                              ),
                            ),
                          // Bottom bar with play progress and timers
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isFullscreen = !_isFullscreen;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                                    child: VideoProgressIndicator(
                                      _controller,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.green,
                                        bufferedColor: Colors.white30,
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Close button top-right
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FORMULARIO DE EDICIÓN/CREACIÓN
// ═════════════════════════════════════════════════════════════════════════════

class _VideoEditorDialog extends StatefulWidget {
  final InstructionalVideo? video;
  final VoidCallback onSaved;

  const _VideoEditorDialog({this.video, required this.onSaved});

  @override
  State<_VideoEditorDialog> createState() => _VideoEditorDialogState();
}

class _VideoEditorDialogState extends State<_VideoEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _titleCtrl.text = widget.video!.title;
      _descCtrl.text = widget.video!.description ?? '';
      _urlCtrl.text = widget.video!.videoUrl;
      _orderCtrl.text = widget.video!.orderIndex.toString();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _isSaving = true);
    final service = SupabaseService();
    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'video_url': _urlCtrl.text.trim(),
      'order_index': int.tryParse(_orderCtrl.text) ?? 0,
    };

    try {
      if (widget.video == null) {
        await service.createInstructionalVideo(data);
      } else {
        await service.updateInstructionalVideo(widget.video!.id, data);
      }
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('video_saved_success')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.get('save_error')} $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.video == null ? l10n.get('new_video_title') : l10n.get('edit_video_title')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: l10n.get('video_title_label'), border: const OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? l10n.get('required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.get('video_description_label'), border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: l10n.get('video_url_label'),
                  hintText: 'https://github.com/.../releases/download/.../video.mp4',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.get('required');
                  if (!v.startsWith('http')) return l10n.get('invalid_url');
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.get('video_order_label'), border: const OutlineInputBorder()),
                validator: (v) => (v == null || int.tryParse(v) == null) ? l10n.get('enter_integer') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.get('cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen),
          child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.get('save')),
        ),
      ],
    );
  }
}
