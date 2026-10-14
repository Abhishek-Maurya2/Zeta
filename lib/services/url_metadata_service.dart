import 'dart:convert';
import 'package:http/http.dart' as http;

class UrlMetadata {
  final String title;
  final String? faviconUrl;

  const UrlMetadata({required this.title, this.faviconUrl});
}

class UrlMetadataService {
  UrlMetadataService._();
  static final UrlMetadataService instance = UrlMetadataService._();

  static const int _maxCacheSize = 100;
  static final RegExp _titleRegExp = RegExp(
    r'<title>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _whitespaceRegExp = RegExp(r'\s+');

  final Map<String, UrlMetadata> _cache = {};

  void _putCache(String key, UrlMetadata value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  Future<UrlMetadata> fetchMetadata(String urlString) async {
    if (_cache.containsKey(urlString)) {
      return _cache[urlString]!;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      final fallback = UrlMetadata(title: urlString, faviconUrl: null);
      _putCache(urlString, fallback);
      return fallback;
    }

    // Google Favicon service provides a reliable high-res favicon fallback
    final domainFavicon =
        'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final titleMatch = _titleRegExp.firstMatch(body);

        String resolvedTitle = uri.host;
        if (titleMatch != null && titleMatch.group(1) != null) {
          resolvedTitle =
              titleMatch.group(1)!.trim().replaceAll(_whitespaceRegExp, ' ');
        }

        final metadata = UrlMetadata(
          title: resolvedTitle.isNotEmpty ? resolvedTitle : uri.host,
          faviconUrl: domainFavicon,
        );
        _putCache(urlString, metadata);
        return metadata;
      }
    } catch (_) {
      // Fallback on network or parsing error
    }

    final fallback = UrlMetadata(
      title: uri.host.isNotEmpty ? uri.host : urlString,
      faviconUrl: domainFavicon,
    );
    _putCache(urlString, fallback);
    return fallback;
  }
}