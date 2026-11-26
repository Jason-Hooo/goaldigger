import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';

/// Error returned by the backend (HTTP status >= 400) or a malformed payload.
class ApiException extends AppException {
  const ApiException(super.message, [this.statusCode]);

  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : '$message (HTTP $statusCode)';
}

typedef JsonMap = Map<String, dynamic>;

/// Thin HTTP wrapper around the GoalDigger REST API.
///
/// Responsible only for transport concerns: URL building, JSON encoding,
/// status-code handling and error extraction. Endpoint knowledge lives in the
/// repositories.
class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
      _http = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _http;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  Future<Object?> get(String path, {Map<String, String>? query}) {
    return _send(() => _http.get(_uri(path, query)));
  }

  Future<Object?> post(String path, {Object? body, Map<String, String>? query}) {
    return _send(
      () => _http.post(
        _uri(path, query),
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Object?> put(String path, {Object? body, Map<String, String>? query}) {
    return _send(
      () => _http.put(
        _uri(path, query),
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Object?> delete(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) {
    return _send(
      () => _http.delete(
        _uri(path, query),
        headers: _jsonHeaders,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  void close() => _http.close();

  Uri _uri(String path, Map<String, String>? query) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Object?> _send(Future<http.Response> Function() request) async {
    final response = await request();
    final body = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(_extractMessage(body), response.statusCode);
    }
    return body;
  }

  Object? _decode(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return response.body;
    }
  }

  String _extractMessage(Object? body) {
    if (body is JsonMap) {
      return body['detail']?.toString() ??
          body['message']?.toString() ??
          'Request failed.';
    }
    return 'Request failed.';
  }
}

/// Helpers for interpreting decoded response bodies.
extension JsonBody on Object? {
  /// Treats the body as a JSON array of objects; anything else is empty.
  List<JsonMap> get asJsonList {
    final self = this;
    if (self is! List) {
      return const [];
    }
    return self.whereType<JsonMap>().toList();
  }

  /// Returns the body as a JSON object or throws [ApiException].
  JsonMap asJsonObject(String errorMessage) {
    final self = this;
    if (self is JsonMap) {
      return self;
    }
    throw ApiException(errorMessage);
  }

  /// Returns the `data` envelope of a JSON object or throws [ApiException].
  JsonMap dataEnvelope(String errorMessage) {
    final data = asJsonObject(errorMessage)['data'];
    if (data is JsonMap) {
      return data;
    }
    throw ApiException(errorMessage);
  }
}
