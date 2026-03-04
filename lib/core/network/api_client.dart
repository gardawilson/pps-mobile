// lib/core/network/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_errors.dart';
import '../../constants/api_constants.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const Duration defaultTimeout = Duration(seconds: 10);

  Uri _buildUri(String urlOrPath) {
    // kalau sudah absolute URL -> pakai langsung
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return Uri.parse(urlOrPath);
    }

    // kalau relative -> gabung baseUrl
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');
    final path = urlOrPath.startsWith('/') ? urlOrPath : '/$urlOrPath';
    return Uri.parse('$base$path');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> postJson(
    String urlOrPath, {
    required Map<String, dynamic> body,
    bool useAuth = false,
    Duration timeout = defaultTimeout,
  }) async {
    final uri = _buildUri(urlOrPath);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (useAuth) {
        final token = await _getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final res = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      return _handleJsonResponse(res);
    } on SocketException catch (e) {
      final code = ApiFailure.socketDetail(e);
      throw ApiFailure(
        type: ApiFailureType.network,
        message: _socketMessage(code),
        detailCode: code,
      );
    } on TimeoutException {
      throw ApiFailure(
        type: ApiFailureType.network,
        message: 'Server tidak merespons (timeout).',
        detailCode: 'timeout',
      );
    } on http.ClientException catch (e) {
      throw ApiFailure(
        type: ApiFailureType.network,
        message: 'Tidak dapat terhubung ke server. (${e.message})',
        detailCode: 'network_error',
      );
    } catch (e) {
      throw ApiFailure(
        type: ApiFailureType.unknown,
        message: 'Terjadi kesalahan tidak terduga: $e',
        detailCode: 'unknown',
      );
    }
  }

  Future<Map<String, dynamic>> getJson(
    String urlOrPath, {
    bool useAuth = false,
    Duration timeout = defaultTimeout,
  }) async {
    final uri = _buildUri(urlOrPath);
    try {
      final headers = <String, String>{'Accept': 'application/json'};

      if (useAuth) {
        final token = await _getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final res = await _client.get(uri, headers: headers).timeout(timeout);
      return _handleJsonResponse(res);
    } on SocketException catch (e) {
      final code = ApiFailure.socketDetail(e);
      throw ApiFailure(
        type: ApiFailureType.network,
        message: _socketMessage(code),
        detailCode: code,
      );
    } on TimeoutException {
      throw ApiFailure(
        type: ApiFailureType.network,
        message: 'Server tidak merespons (timeout).',
        detailCode: 'timeout',
      );
    } catch (e) {
      throw ApiFailure(
        type: ApiFailureType.unknown,
        message: 'Terjadi kesalahan tidak terduga: $e',
        detailCode: 'unknown',
      );
    }
  }

  Map<String, dynamic> _handleJsonResponse(http.Response res) {
    final body = res.body.trim();

    if (body.isEmpty) {
      throw ApiFailure.fromStatus(
        statusCode: res.statusCode,
        message: 'Response kosong dari server (status ${res.statusCode}).',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw ApiFailure.fromStatus(
        statusCode: res.statusCode,
        message: 'Response server bukan JSON valid.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiFailure.fromStatus(
        statusCode: res.statusCode,
        message: 'Format JSON tidak sesuai (bukan object).',
      );
    }

    // kalau status bukan 2xx, map error berdasarkan payload
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (decoded['message'] ?? 'Terjadi kesalahan').toString();
      final et = (decoded['errorType'] ?? '').toString();
      throw ApiFailure.fromStatus(
        statusCode: res.statusCode,
        message: msg,
        backendErrorType: et,
      );
    }

    return decoded;
  }

  String _socketMessage(String code) {
    switch (code) {
      case 'backend_offline':
        return 'Backend offline / port server tertutup (connection refused).';
      case 'dns':
        return 'Alamat server tidak ditemukan (DNS/host salah).';
      case 'no_route':
        return 'Jaringan tidak bisa menjangkau server (no route/unreachable).';
      case 'timeout':
        return 'Koneksi ke server timeout.';
      default:
        return 'Tidak dapat terhubung ke server.';
    }
  }
}
