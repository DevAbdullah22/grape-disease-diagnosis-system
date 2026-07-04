import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class AppMarkdownBody extends StatelessWidget {
  final String content;
  final bool enableTtsHighlight;

  const AppMarkdownBody({
    super.key,
    required this.content,
    this.enableTtsHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final styleSheet = MarkdownStyleSheet(
      p: const TextStyle(fontSize: 16, height: 1.5),
      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      listBullet: const TextStyle(fontSize: 16),
    );

    return MarkdownBody(
      data: content,
      styleSheet: styleSheet,
      inlineSyntaxes: enableTtsHighlight
          ? <md.InlineSyntax>[TtsHighlightSyntax()]
          : null,
      builders: enableTtsHighlight
          ? <String, MarkdownElementBuilder>{
              'tts-hl': _TtsHighlightBuilder(),
            }
          : const <String, MarkdownElementBuilder>{},
    );
  }
}

class TtsHighlightSyntax extends md.InlineSyntax {
  TtsHighlightSyntax()
    : super(
        r'<tts-hl>([\s\S]*?)</tts-hl>',
        startCharacter: 60, // '<'
        caseSensitive: false,
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final inner = match.group(1) ?? '';
    parser.addNode(md.Element.text('tts-hl', inner));
    return true;
  }
}

class _TtsHighlightBuilder extends MarkdownElementBuilder {
  _TtsHighlightBuilder();

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final style = (parentStyle ?? preferredStyle ?? const TextStyle()).copyWith(
      backgroundColor: const Color(0xFFE9D0FF),
    );
    return Text.rich(
      TextSpan(text: element.textContent, style: style),
      textAlign: TextAlign.right,
    );
  }
}
