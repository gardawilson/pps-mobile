import 'package:flutter/foundation.dart';

import '../../../core/network/api_errors.dart';
import '../model/so_v2_models.dart';
import '../repository/so_v2_repository.dart';

class SoV2DetailViewModel extends ChangeNotifier {
  SoV2DetailViewModel({
    required this.stockOpnameNo,
    required this.categoryCode,
    SoV2Repository? repository,
  }) : repository = repository ?? SoV2Repository();

  final String stockOpnameNo;
  String categoryCode;
  final SoV2Repository repository;

  List<SoV2Lokasi> locations = [];
  List<SoV2LabelGroup> groups = [];

  SoV2Lokasi? selectedLocation;

  bool isLoadingLocations = false;
  bool isLoadingLabels = false;
  bool isLoadingMore = false;
  bool isComplete = false;
  String? error;

  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int totalScanned = 0;
  double totalQuantity = 0;
  String search = '';

  String get unit =>
      categoryCode.toLowerCase() == 'furniturewip' ? 'pcs' : 'kg';
  int get loadedLabelCount =>
      groups.fold<int>(0, (total, group) => total + group.labels.length);
  bool get canLoadMore =>
      currentPage < totalPages || loadedLabelCount < totalRecords;

  Future<void> loadLocations() async {
    selectedLocation = null;
    groups = [];
    _resetLabelSummary();
    isLoadingLocations = true;
    error = null;
    notifyListeners();
    try {
      final page = await repository.fetchLokasi(stockOpnameNo);
      locations = page.items;
      isComplete = page.isComplete;
      if (categoryCode.isEmpty) categoryCode = page.categoryCode;
      locations.sort((a, b) {
        if (a.blok == soV2UnknownBlok) return 1;
        if (b.blok == soV2UnknownBlok) return -1;
        final blokCompare = a.blok.compareTo(b.blok);
        if (blokCompare != 0) return blokCompare;
        return a.locationId.compareTo(b.locationId);
      });
    } catch (e) {
      error = _message(e);
    } finally {
      isLoadingLocations = false;
      notifyListeners();
    }
  }

  Future<void> selectLocation(SoV2Lokasi location) async {
    selectedLocation = location;
    search = '';
    await loadLabels(reset: true);
  }

  Future<void> setSearch(String value) async {
    search = value.trim();
    await loadLabels(reset: true);
  }

  Future<void> loadLabels({required bool reset}) async {
    final location = selectedLocation;
    if (location == null) return;

    final requestedPage = reset ? 1 : currentPage + 1;
    if (reset) {
      currentPage = 1;
      groups = [];
      isLoadingLabels = true;
    } else {
      if (!canLoadMore || isLoadingMore) return;
      isLoadingMore = true;
    }
    error = null;
    notifyListeners();

    try {
      final page = await repository.fetchLabels(
        stockOpnameNo: stockOpnameNo,
        blok: location.blok,
        locationId: location.locationId,
        page: requestedPage,
        search: search,
      );
      if (reset) {
        groups = page.groups;
      } else {
        groups = _mergeGroups(groups, page.groups);
      }
      // Gunakan halaman yang benar-benar diminta. Ini tetap bekerja apabila
      // backend tidak mengirim currentPage atau mengirim nilai fallback.
      currentPage = requestedPage;
      totalPages = page.totalPages;
      totalRecords = page.totalRecords;
      totalScanned = page.totalScanned;
      totalQuantity = page.totalQuantity;
      isComplete = page.isComplete;
      if (categoryCode.isEmpty) categoryCode = page.categoryCode;
    } catch (e) {
      error = _message(e);
    } finally {
      isLoadingLabels = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  List<SoV2LabelGroup> _mergeGroups(
    List<SoV2LabelGroup> existing,
    List<SoV2LabelGroup> incoming,
  ) {
    final merged = [...existing];
    for (final next in incoming) {
      final index = merged.indexWhere(
        (current) => current.typeId != null && next.typeId != null
            ? current.typeId == next.typeId
            : current.typeName == next.typeName,
      );
      if (index < 0) {
        merged.add(next);
        continue;
      }

      final current = merged[index];
      merged[index] = SoV2LabelGroup(
        typeId: current.typeId ?? next.typeId,
        typeName: current.typeName.isNotEmpty
            ? current.typeName
            : next.typeName,
        labelCount: next.labelCount,
        totalQuantity: next.totalQuantity,
        labels: [...current.labels, ...next.labels],
      );
    }
    return merged;
  }

  void backToLocations() {
    selectedLocation = null;
    groups = [];
    search = '';
    _resetLabelSummary();
    error = null;
    notifyListeners();
  }

  void _resetLabelSummary() {
    currentPage = 1;
    totalPages = 1;
    totalRecords = 0;
    totalScanned = 0;
    totalQuantity = 0;
  }

  static String _message(Object error) {
    if (error is ApiFailure) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
