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

  final Map<String, UrlMetadata> _cache = {};

  Future<UrlMetadata> fetchMetadata(String urlString) async {
    if (_cache.containsKey(urlString)) {
      return _cache[urlString]!;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null || !uri.hasScheme) {
      final fallback = UrlMetadata(title: urlString, faviconUrl: null);
      _cache[urlString] = fallback;
      return fallback;
    }

    // Google Favicon service provides a reliable high-res favicon fallback
    final domainFavicon = 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=64';

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false, dotAll: true)
            .firstMatch(body);
        
        String resolvedTitle = uri.host;
        if (titleMatch != null && titleMatch.group(1) != null) {
          resolvedTitle = titleMatch.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
        }

        final metadata = UrlMetadata(
          title: resolvedTitle.isNotEmpty ? resolvedTitle : uri.host,
          faviconUrl: domainFavicon,
        );
        _cache[urlString] = metadata;
        return metadata;
      }
    } catch (_) {
      // Fallback on network or parsing error
    }

    final fallback = UrlMetadata(
      title: uri.host.isNotEmpty ? uri.host : urlString,
      faviconUrl: domainFavicon,
    );
    _cache[urlString] = fallback;
    return fallback;
  }
}