import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import '../services/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import 'photo_gallery_dialog.dart';
import '../services/supabase_service.dart';
import '../models/property.dart';

/// A single chat message bubble widget.
/// User messages align right; assistant messages align left with Markdown-like rendering.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Color primaryColor;
  final bool isDark;
  final AppLocalizations l10n;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.primaryColor,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isVoice = message.inputType == ChatInputType.voice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Ava avatar
            Builder(
              builder: (context) {
                final companyProv = context.watch<CompanyProvider>();
                final country = companyProv.country?.toLowerCase();
                String? avatarAsset;
                if (companyProv.isDemo || country == null) {
                  avatarAsset = 'assets/images/avatars/avatar_venezuela.png';
                } else {
                  if (country.contains('venezuela')) avatarAsset = 'assets/images/avatars/avatar_venezuela.png';
                  else if (country.contains('bolivia')) avatarAsset = 'assets/images/avatars/avatar_bolivia.png';
                  else if (country.contains('colombia')) avatarAsset = 'assets/images/avatars/avatar_colombia.png';
                  else if (country.contains('usa') || country.contains('estados unidos')) avatarAsset = 'assets/images/avatars/avatar_usa.png';
                }

                if (avatarAsset != null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Image.asset(avatarAsset, fit: BoxFit.contain),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                );
              }
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voice indicator for user voice messages
                  if (isUser && isVoice) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          message.audioDurationSeconds != null
                              ? '0:${message.audioDurationSeconds.toString().padLeft(2, '0')}'
                              : '🎤',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Message content
                  if (isUser)
                    Text(
                      message.content,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  else
                    _buildAssistantContent(context),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAssistantContent(BuildContext context) {
    final textColor = isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87;

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 14, height: 1.5),
        listBullet: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        strong: const TextStyle(fontWeight: FontWeight.bold),
        h2: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
        h3: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        a: TextStyle(color: Colors.blue.shade700, decoration: TextDecoration.underline),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          final uri = Uri.tryParse(href);
          if (uri != null) {
            // Check path segments
            var lastSegment = '';
            if (uri.pathSegments.isNotEmpty) {
              lastSegment = uri.pathSegments.last.toLowerCase();
            } else if (uri.fragment.isNotEmpty) {
              // Handle hash-routed URLs like #/ref041
              final fragUri = Uri.tryParse(uri.fragment);
              if (fragUri != null && fragUri.pathSegments.isNotEmpty) {
                lastSegment = fragUri.pathSegments.last.toLowerCase();
              }
            }
            
            if (lastSegment.startsWith('ref')) {
              final refStr = lastSegment.replaceAll('ref', '');
              final refNum = int.tryParse(refStr);
              if (refNum != null) {
                _openPropertyGallery(context, refNum);
                return;
              }
            }
          }
          _launchUrl(href);
        }
      },
    );
  }

  Future<void> _openPropertyGallery(BuildContext context, int refNum) async {
    // Show a simple fullscreen loading indicator to prevent double-tap issues
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final companyId = companyProvider.companyId;
      final service = SupabaseService();
      
      final response = await service.client
          .from('properties')
          .select('*, property_details(*), gallery(image_url, is_main), listing_agent:profiles!properties_listing_agent_id_fkey(full_name)')
          .eq('company_id', companyId)
          .eq('ref_number', refNum)
          .maybeSingle();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
      }

      if (response != null) {
        final property = Property.fromJson(response);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => PhotoGalleryDialog(property: property),
          );
        }
      } else {
        // Fallback: try global search
        final globalResponse = await service.client
            .from('properties')
            .select('*, property_details(*), gallery(image_url, is_main), listing_agent:profiles!properties_listing_agent_id_fkey(full_name)')
            .eq('ref_number', refNum)
            .maybeSingle();
            
        if (globalResponse != null && context.mounted) {
          final property = Property.fromJson(globalResponse);
          showDialog(
            context: context,
            builder: (_) => PhotoGalleryDialog(property: property),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading if open
      }
      debugPrint('Error opening property from chat link: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
