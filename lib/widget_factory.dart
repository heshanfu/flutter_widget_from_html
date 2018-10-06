import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

final _baseUriTrimmingRegExp = RegExp(r'/+$');
final _dataUriRegExp = RegExp(r'^data:image/\w+;base64,');
final _httpSchemeRegExp = RegExp(r'^https?://');
final _spacingRegExp = RegExp(r'\s+');
final _textIsUselessRegExp = RegExp(r'^\s*$');

class WidgetFactory {
  final Config config;

  const WidgetFactory({this.config = const Config()});

  Widget buildColumn({List<Widget> children, String url}) {
    Widget widget = Column(
      children: children,
      crossAxisAlignment: CrossAxisAlignment.stretch,
    );

    if (url != null && url.isNotEmpty) {
      widget = GestureDetector(
        child: widget,
        onTap: prepareGestureTapCallbackToLaunchUrl(buildFullUrl(url)),
      );
    }

    return widget;
  }

  String buildFullUrl(String url) {
    var imageUrl = url;

    if (!url.startsWith(_httpSchemeRegExp)) {
      final baseUrl = config.baseUrl;
      if (baseUrl == null) {
        return null;
      }

      if (url.startsWith('/')) {
        imageUrl = baseUrl.scheme +
            '://' +
            baseUrl.host +
            (baseUrl.hasPort ? ":${baseUrl.port}" : '') +
            url;
      } else {
        final baseUrlTrimmed =
            baseUrl.toString().replaceAll(_baseUriTrimmingRegExp, '');
        imageUrl = "$baseUrlTrimmed/$url";
      }
    }

    return imageUrl;
  }

  List buildImageBytes(String dataUri) {
    final match = _dataUriRegExp.matchAsPrefix(dataUri);
    if (match == null) {
      return null;
    }

    final prefix = match.group(0);
    final bytes = base64.decode(dataUri.substring(prefix.length));
    if (bytes.length == 0) {
      return null;
    }

    return bytes;
  }

  Widget buildImageWidget(String src) {
    if (src.startsWith('data:image')) {
      return buildImageWidgetFromDataUri(src);
    } else {
      return buildImageWidgetFromUrl(src);
    }
  }

  Widget buildImageWidgetFromDataUri(String dataUri) {
    final bytes = buildImageBytes(dataUri);
    if (bytes == null) {
      return null;
    }

    return Image.memory(bytes, fit: BoxFit.cover);
  }

  Widget buildImageWidgetFromUrl(String url) {
    final imageUrl = buildFullUrl(url);
    if (imageUrl == null) {
      return null;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
    );
  }

  TextSpan buildTextSpan(
      {List<TextSpan> children, TextStyle style, String text, String url}) {
    if (!(children?.isEmpty == false) && text?.isEmpty != false) {
      return null;
    }

    TapGestureRecognizer recognizer;
    if (url != null && url.isNotEmpty) {
      final onTap = prepareGestureTapCallbackToLaunchUrl(buildFullUrl(url));
      recognizer = TapGestureRecognizer()..onTap = onTap;
    }

    return TextSpan(
      children: children,
      style: style,
      recognizer: recognizer,
      text: text.replaceAll(_spacingRegExp, ' '),
    );
  }

  Widget buildTextWidgetSimple({
    @required String text,
    TextAlign textAlign,
  }) =>
      _checkTextIsUseless(text)
          ? null
          : Text(
              text.trim(),
              textAlign: textAlign ?? TextAlign.start,
            );

  Widget buildTextWidgetWithStyling({
    @required TextSpan text,
    TextAlign textAlign,
  }) =>
      text == null
          ? null
          : RichText(
              text: text,
              textAlign: textAlign ?? TextAlign.start,
            );

  GestureTapCallback prepareGestureTapCallbackToLaunchUrl(String url) {
    return () async {
      if (await canLaunch(url)) {
        await launch(url);
      }
    };
  }

  bool _checkTextIsUseless(String text) =>
      _textIsUselessRegExp.firstMatch(text) != null;
}