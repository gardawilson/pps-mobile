import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/label_validation_result.dart';

class StockOpnameScanViewModel extends ChangeNotifier {
  bool isSaving = false;
  String saveMessage = '';
  int? lastStatusCode;

  /// Ambil token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Validasi label
  Future<LabelValidationResult?> validateLabel(String label, String noSO) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('❌ Token tidak tersedia');
      return null;
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/validate-label');
    debugPrint('📤 Request validate-label => $url | label: $label');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'label': label}),
      );

      debugPrint('📥 Response [${response.statusCode}]: ${response.body}');

      final jsonResponse = json.decode(response.body);
      return LabelValidationResult.fromJson(jsonResponse);

    } catch (e) {
      debugPrint('❌ Exception validateLabel: $e');
      return null;
    }
  }

  /// Insert label ke stock opname
  Future<bool> insertLabel({
    required String label,
    required String noSO,
    required int jmlhSak,
    required double berat,
    required String idLokasi,
  }) async {
    final token = await _getToken();
    if (token == null) {
      debugPrint('❌ Token tidak tersedia untuk insert');
      return false;
    }

    isSaving = true;
    notifyListeners();

    final url = Uri.parse('${ApiConstants.baseUrl}/api/no-stock-opname/$noSO/insert-label');
    debugPrint('📤 Request insert-label => $url');
    debugPrint('📤 Body: label=$label, jmlhSak=$jmlhSak, berat=$berat, idlokasi=$idLokasi');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'label': label,
          'jmlhSak': jmlhSak,
          'berat': berat,
          'idlokasi': idLokasi,
        }),
      );

      debugPrint('📥 Insert Response [${response.statusCode}]: ${response.body}');

      final success = response.statusCode == 200 || response.statusCode == 201;
      lastStatusCode = response.statusCode;

      if (success) {
        saveMessage = 'Data berhasil disimpan.';
      } else {
        saveMessage = 'Gagal menyimpan data. (${response.statusCode})';
        // Log response body untuk debugging
        debugPrint('❌ Insert failed response body: ${response.body}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Insert error: $e');
      saveMessage = 'Terjadi kesalahan: ${e.toString()}';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}