import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  const LinkableText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
  });

  @override
  State<LinkableText> createState() => _LinkableTextState();
}

class _LinkableTextState extends State<LinkableText> {
  final List<TapGestureRecognizer> _gestureRecognizers = [];

  @override
  void dispose() {
    for (final recognizer in _gestureRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _launchUrl(String rawUrl) async {
    String cleanUrl = rawUrl.trim();
    while (cleanUrl.endsWith('.') ||
        cleanUrl.endsWith(',') ||
        cleanUrl.endsWith('!') ||
        cleanUrl.endsWith('?') ||
        cleanUrl.endsWith(')')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    if (cleanUrl.isEmpty) return;

    String urlToLaunch = cleanUrl;
    if (!urlToLaunch.startsWith('http://') &&
        !urlToLaunch.startsWith('https://')) {
      urlToLaunch = 'https://$urlToLaunch';
    }

    try {
      final uri = Uri.parse(urlToLaunch);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching URL ($cleanUrl): $e');
    }
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    final defaultStyle = widget.style ??
        TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        );

    final linkStyle = widget.linkStyle ??
        TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        );

    final RegExp urlRegex = RegExp(
      r'((?:https?://|www\.)[^\s<>()]+|(?:[a-zA-Z0-9-]+\.)+(?:com|org|net|io|co|dev|app|edu|gov|in|me|ai|tech|info|xyz|online|site|store)(?:/[^\s<>()]*)?)',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    final String text = widget.text;

    for (final recognizer in _gestureRecognizers) {
      recognizer.dispose();
    }
    _gestureRecognizers.clear();

    int start = 0;
    for (final Match match in urlRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: defaultStyle,
        ));
      }

      final String matchedUrl = match.group(0)!;
      String displayUrl = matchedUrl;
      String targetUrl = matchedUrl;

      if (displayUrl.endsWith('.') ||
          displayUrl.endsWith(',') ||
          displayUrl.endsWith('!') ||
          displayUrl.endsWith('?')) {
        String trailing = displayUrl.substring(displayUrl.length - 1);
        displayUrl = displayUrl.substring(0, displayUrl.length - 1);
        targetUrl = displayUrl;

        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launchUrl(targetUrl);
        _gestureRecognizers.add(recognizer);

        spans.add(TextSpan(
          text: displayUrl,
          style: linkStyle,
          recognizer: recognizer,
        ));
        spans.add(TextSpan(
          text: trailing,
          style: defaultStyle,
        ));
      } else {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launchUrl(targetUrl);
        _gestureRecognizers.add(recognizer);

        spans.add(TextSpan(
          text: displayUrl,
          style: linkStyle,
          recognizer: recognizer,
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: _buildSpans(context)),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
