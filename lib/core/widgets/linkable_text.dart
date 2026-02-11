import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:math/features/shared/presentation/screens/web_view_screen.dart';

class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> children = [];
    final RegExp urlRegex = RegExp(
      r'((https?:\/\/)|(www\.))[^\s]+',
      caseSensitive: false,
    );
    final RegExp hashtagRegex = RegExp(r'#(\w+)');

    text.splitMapJoin(
      RegExp(
        '${urlRegex.pattern}|${hashtagRegex.pattern}',
        caseSensitive: false,
      ),
      onMatch: (Match match) {
        final matchString = match.group(0)!;

        if (urlRegex.hasMatch(matchString)) {
          String url = matchString;
          if (!url.startsWith('http')) {
            url = 'https://$url';
          }
          children.add(
            TextSpan(
              text: matchString,
              style: (style ?? const TextStyle()).copyWith(
                color: Colors.blue,
                decoration: TextDecoration.none,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  WebViewScreen.show(context, url);
                },
            ),
          );
        } else if (hashtagRegex.hasMatch(matchString)) {
          final tag = match.group(match.groupCount)!; // The word after #
          children.add(
            TextSpan(
              text: matchString,
              style: (style ?? const TextStyle()).copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  GoRouter.of(context).push('/tags/$tag');
                },
            ),
          );
        }
        return matchString;
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return text;
      },
    );

    return Text.rich(
      TextSpan(children: children),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class LinkableTextEditingController extends TextEditingController {
  final RegExp urlRegex = RegExp(
    r'((https?:\/\/)|(www\.))[^\s]+',
    caseSensitive: false,
  );
  final RegExp hashtagRegex = RegExp(r'#(\w+)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final String text = this.text;

    text.splitMapJoin(
      RegExp(
        '${urlRegex.pattern}|${hashtagRegex.pattern}',
        caseSensitive: false,
      ),
      onMatch: (Match match) {
        final matchString = match.group(0)!;
        if (urlRegex.hasMatch(matchString)) {
          children.add(
            TextSpan(
              text: matchString,
              style: (style ?? const TextStyle()).copyWith(
                color: Colors.blue,
                decoration: TextDecoration.none,
              ),
            ),
          );
        } else if (hashtagRegex.hasMatch(matchString)) {
          children.add(
            TextSpan(
              text: matchString,
              style: (style ?? const TextStyle()).copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        return matchString;
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return text;
      },
    );

    return TextSpan(children: children, style: style);
  }
}
