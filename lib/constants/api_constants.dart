import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/auth/login';
  static String get checkLabel => '$baseUrl/api/label-list/check';
  static String get saveChanges => '$baseUrl/api/label-list/save-changes';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get listNyangkut => '$baseUrl/api/nyangkut-list';
  static String get mstLokasi => '$baseUrl/api/mst-lokasi';

  static String scanLabel(String noSO) => '$baseUrl/api/no-stock-opname/$noSO/scan';

  static String labelData(String noLabel) => '$baseUrl/api/label-data/$noLabel';

  static String labelSOList({
    required String selectedNoSO,
    required int page,
    required int pageSize,
    String? filterBy,
    String? blok,         // opsional
    int? idLokasi,        // int? biar konsisten dengan model/VM
    String? search,       // opsional
  }) {
    final params = <String, String>{
      'page'         : '$page',
      'pageSize'     : '$pageSize',
      'filterBy'     : filterBy ?? 'all',
      'idLokasi'     : (idLokasi == null || idLokasi == 0) ? 'all' : idLokasi.toString(),
      'filterbyuser' : 'true', // hardcode di sini
      if (blok != null && blok.isNotEmpty) 'blok': blok,
      if (search != null && search.isNotEmpty) 'search': Uri.encodeQueryComponent(search),
    };

    final query = Uri(queryParameters: params).query;
    return '$baseUrl/api/no-stock-opname/$selectedNoSO/hasil?$query';
  }

  static String labelList({
    required int page,
    required int pageSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$pageSize&filterBy=$filter&idlokasi=$lokasi';
  }

  static String labelListLoadMore({
    required int page,
    required int loadMoreSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final currentFilter = filterBy ?? 'all';
    final currentLocation = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$loadMoreSize&filterBy=$currentFilter&idlokasi=$currentLocation';
  }

}
