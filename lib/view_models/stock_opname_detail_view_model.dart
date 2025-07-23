import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/stock_opname_label_model.dart';

class StockOpnameDetailViewModel extends ChangeNotifier {
  String noSO = '';
  String? currentFilter;
  String? currentIdLokasi; // Tambahkan field untuk idLokasi

  List<StockOpnameLabel> labels = [];

  int page = 1;
  int pageSize = 50;
  int totalData = 0;
  bool hasMoreData = true;

  bool isInitialLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchInitialData(String selectedNoSO, {String filterBy = 'all', String? idLokasi}) async {
    noSO = selectedNoSO;
    currentFilter = filterBy;
    currentIdLokasi = idLokasi; // Simpan idLokasi yang dipilih
    page = 1;
    hasMoreData = true;
    labels.clear();
    isInitialLoading = true;
    notifyListeners();

    await _fetchData();
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;
    page++;
    isLoadingMore = true;
    notifyListeners();

    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final token = await _getToken();

      final url = Uri.parse(
        ApiConstants.labelSOList(
          selectedNoSO: noSO,
          page: page,
          pageSize: pageSize,
          filterBy: currentFilter,
          idLokasi: currentIdLokasi, // Pass idLokasi ke API constants
        ),
      );

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> labelData = data['data'];
        final int total = data['totalData'];

        final fetched = labelData.map((e) => StockOpnameLabel.fromJson(e)).toList();

        labels.addAll(fetched);
        totalData = total;
        hasMoreData = labels.length < total;
        hasError = false;
        errorMessage = '';
      } else {
        hasError = true;
        errorMessage = 'Gagal mengambil data (status: ${response.statusCode})';
        print('❌ ERROR: $errorMessage');
      }
    } catch (e) {
      hasError = true;
      errorMessage = 'Kesalahan jaringan: $e';
      print('❌ EXCEPTION: $errorMessage');
    } finally {
      isInitialLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void reset() {
    labels.clear();
    page = 1;
    totalData = 0;
    hasMoreData = true;
    errorMessage = '';
    currentIdLokasi = null; // Reset idLokasi
    notifyListeners();
  }
}