import '../../../core/network/api_client.dart';
import '../../../core/network/api_errors.dart';
import '../model/so_v2_models.dart';

class SoV2Repository {
  SoV2Repository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<SoV2Kategori>> fetchKategori() async {
    try {
      final response = await _apiClient.getJson(
        '/api/stock-opname-v2/kategori',
        useAuth: true,
      );
      return _mapList(response['data']).map(SoV2Kategori.fromJson).toList();
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<List<SoV2Blok>> fetchBlok(String stockOpnameNo) async {
    try {
      final response = await _apiClient.getJson(
        '/api/stock-opname-v2/transaksi/${Uri.encodeComponent(stockOpnameNo)}/blok',
        useAuth: true,
      );
      return _mapList(response['data']).map(SoV2Blok.fromJson).toList();
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<SoV2LokasiPage> fetchLokasi(String stockOpnameNo, String blok) async {
    try {
      final response = await _apiClient.getJson(
        '/api/stock-opname-v2/transaksi/${Uri.encodeComponent(stockOpnameNo)}/blok/${Uri.encodeComponent(blok)}/lokasi',
        useAuth: true,
      );
      return SoV2LokasiPage.fromJson(_map(response['data']));
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) {
        return const SoV2LokasiPage(
          categoryCode: '',
          categoryName: '',
          isComplete: false,
          items: [],
        );
      }
      rethrow;
    }
  }

  Future<SoV2LabelPage> fetchLabels({
    required String stockOpnameNo,
    required String blok,
    required int locationId,
    required int page,
    int pageSize = 20,
    String? search,
  }) async {
    final query = Uri(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    ).query;
    try {
      final response = await _apiClient.getJson(
        '/api/stock-opname-v2/transaksi/${Uri.encodeComponent(stockOpnameNo)}/blok/${Uri.encodeComponent(blok)}/lokasi/$locationId/label?$query',
        useAuth: true,
      );
      return SoV2LabelPage.fromJson(_map(response['data']));
    } on ApiFailure catch (error) {
      if (error.statusCode == 404) {
        return SoV2LabelPage(
          categoryCode: '',
          isComplete: false,
          groups: const [],
          currentPage: page,
          totalPages: page,
          totalRecords: 0,
          totalScanned: 0,
          totalQuantity: 0,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitResult({
    required String stockOpnameNo,
    required String labelNo,
    required String palletNo,
    required String blok,
    required int locationId,
  }) async {
    final response = await _apiClient.postJson(
      '/api/stock-opname-v2/transaksi/${Uri.encodeComponent(stockOpnameNo)}/hasil',
      body: {
        'labelNo': labelNo.trim(),
        'palletNo': palletNo.trim(),
        'blok': blok,
        'locationId': locationId,
      },
      useAuth: true,
    );
    return {
      'message': response['message']?.toString() ?? 'Label berhasil dicatat',
      'data': _map(response['data']),
    };
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
