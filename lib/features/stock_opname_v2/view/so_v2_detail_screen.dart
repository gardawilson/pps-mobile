import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/so_v2_models.dart';
import '../view_model/so_v2_detail_view_model.dart';
import 'so_v2_scan_screen.dart';

class SoV2DetailScreen extends StatefulWidget {
  const SoV2DetailScreen({
    super.key,
    required this.stockOpnameNo,
    required this.categoryCode,
    required this.categoryName,
  });

  final String stockOpnameNo;
  final String categoryCode;
  final String categoryName;

  @override
  State<SoV2DetailScreen> createState() => _SoV2DetailScreenState();
}

class _SoV2DetailScreenState extends State<SoV2DetailScreen> {
  late final SoV2DetailViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _labelScrollController = ScrollController();
  Timer? _searchDebounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _viewModel = SoV2DetailViewModel(
      stockOpnameNo: widget.stockOpnameNo,
      categoryCode: widget.categoryCode,
    )..loadLocations();
    _labelScrollController.addListener(_onLabelScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _labelScrollController
      ..removeListener(_onLabelScroll)
      ..dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onLabelScroll() {
    if (!_labelScrollController.hasClients ||
        _viewModel.selectedLocation == null ||
        !_viewModel.canLoadMore ||
        _viewModel.isLoadingLabels ||
        _viewModel.isLoadingMore) {
      return;
    }

    final position = _labelScrollController.position;
    _loadMoreIfNeeded(position.extentAfter);
  }

  void _loadMoreIfNeeded(double extentAfter) {
    if (_viewModel.selectedLocation == null ||
        !_viewModel.canLoadMore ||
        _viewModel.isLoadingLabels ||
        _viewModel.isLoadingMore) {
      return;
    }

    const loadMoreThreshold = 300.0;
    if (extentAfter <= loadMoreThreshold) {
      _viewModel.loadLabels(reset: false);
    }
  }

  bool _onLabelScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _loadMoreIfNeeded(notification.metrics.extentAfter);
    }
    return false;
  }

  void _handleBack(SoV2DetailViewModel viewModel) {
    if (_isSearching) {
      _closeSearch(viewModel);
      return;
    }
    if (viewModel.selectedLocation != null) {
      _searchController.clear();
      viewModel.backToLocations();
      return;
    }
    Navigator.of(context).pop();
  }

  void _openSearch() {
    setState(() => _isSearching = true);
  }

  void _closeSearch(SoV2DetailViewModel viewModel) {
    setState(() => _isSearching = false);
    _searchDebounce?.cancel();
    _searchController.clear();
    viewModel.setSearch('');
  }

  Future<void> _openScanner(SoV2DetailViewModel viewModel) async {
    final location = viewModel.selectedLocation;
    if (location == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SoV2ScanScreen(
          stockOpnameNo: widget.stockOpnameNo,
          blok: location.blok,
          locationId: location.locationId,
        ),
      ),
    );
    await viewModel.loadLabels(reset: true);
  }

  void _onSearchChanged(String value, SoV2DetailViewModel viewModel) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => viewModel.setSearch(value),
    );
  }

  Future<void> _refreshCurrentStep(SoV2DetailViewModel viewModel) {
    if (viewModel.selectedLocation != null) {
      return viewModel.loadLabels(reset: true);
    }
    return viewModel.loadLocations();
  }

  String _appBarTitle(SoV2DetailViewModel viewModel) {
    final location = viewModel.selectedLocation;
    if (location == null) return widget.categoryName;
    final locationText = location.isUnknown
        ? 'Lokasi Tidak Diketahui'
        : '${location.blok}${location.locationId}';
    return '${widget.categoryName} ($locationText)';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SoV2DetailViewModel>(
        builder: (context, viewModel, _) {
          final isLabelStep = viewModel.selectedLocation != null;
          return PopScope(
            canPop: viewModel.selectedLocation == null,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _handleBack(viewModel);
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FA),
              appBar: AppBar(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () => _handleBack(viewModel),
                  icon: const Icon(Icons.arrow_back),
                ),
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: 'Cari nomor label...',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) =>
                            _onSearchChanged(value, viewModel),
                      )
                    : Text(
                        _appBarTitle(viewModel),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                actions: isLabelStep
                    ? [
                        IconButton(
                          onPressed: _isSearching
                              ? () => _closeSearch(viewModel)
                              : _openSearch,
                          icon: Icon(_isSearching ? Icons.close : Icons.search),
                        ),
                      ]
                    : null,
              ),
              body: RefreshIndicator(
                onRefresh: () => _refreshCurrentStep(viewModel),
                child: _buildCurrentStep(viewModel),
              ),
              floatingActionButton: isLabelStep && !viewModel.isComplete
                  ? FloatingActionButton(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      onPressed: () => _openScanner(viewModel),
                      child: const Icon(Icons.qr_code_scanner),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(SoV2DetailViewModel viewModel) {
    if (viewModel.selectedLocation != null) {
      return _buildLabelStep(viewModel);
    }
    return _buildLocationStep(viewModel);
  }

  Widget _buildLocationStep(SoV2DetailViewModel viewModel) {
    if (viewModel.isLoadingLocations && viewModel.locations.isEmpty) {
      return const _LoadingList(message: 'Memuat daftar lokasi...');
    }
    if (viewModel.error != null && viewModel.locations.isEmpty) {
      return _ErrorList(
        message: viewModel.error!,
        onRetry: viewModel.loadLocations,
      );
    }
    if (viewModel.locations.isEmpty) {
      return const _EmptyList(
        icon: Icons.location_off_outlined,
        message: 'Belum ada lokasi pada stock opname ini.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        for (final location in viewModel.locations)
          _LocationMenuCard(
            location: location,
            onTap: () => viewModel.selectLocation(location),
          ),
      ],
    );
  }

  Widget _buildLabelStep(SoV2DetailViewModel viewModel) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onLabelScrollNotification,
      child: ListView(
        controller: _labelScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (viewModel.isComplete) ...[
            const _CompletedBanner(),
            const SizedBox(height: 12),
          ],
          _LabelSummary(viewModel: viewModel),
          const SizedBox(height: 12),
          if (viewModel.isLoadingLabels)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (viewModel.groups.isEmpty)
            const _InlineEmpty(message: 'Belum ada label pada lokasi ini.')
          else ...[
            for (final group in viewModel.groups)
              _LabelGroupCard(group: group, unit: viewModel.unit),
            if (viewModel.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                viewModel.error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationMenuCard extends StatelessWidget {
  const _LocationMenuCard({required this.location, required this.onTap});

  final SoV2Lokasi location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = location.progress.clamp(0.0, 1.0);
    final complete =
        location.labelCount > 0 && location.scannedCount >= location.labelCount;
    final locationName = location.isUnknown
        ? 'Lokasi Tidak Diketahui'
        : '${location.blok}${location.locationId}';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      color: complete
                          ? Colors.green.shade600
                          : const Color(0xFF0D47A1),
                    ),
                    complete
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.green.shade700,
                          )
                        : Text(
                            '${(progress * 100).round()}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locationName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${location.scannedCount}/${location.labelCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: complete
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelSummary extends StatelessWidget {
  const _LabelSummary({required this.viewModel});

  final SoV2DetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Progress',
            value: '${viewModel.totalScanned}/${viewModel.totalRecords}',
            icon: Icons.fact_check_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: viewModel.unit == 'pcs' ? 'Total Pcs' : 'Total Berat',
            value:
                '${soV2FormatQuantity(viewModel.totalQuantity)} ${viewModel.unit}',
            icon: viewModel.unit == 'pcs'
                ? Icons.numbers
                : Icons.monitor_weight_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelGroupCard extends StatelessWidget {
  const _LabelGroupCard({required this.group, required this.unit});

  final SoV2LabelGroup group;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final complete =
        group.labelCount > 0 && group.scannedCount >= group.labelCount;
    final accentColor = complete
        ? Colors.green.shade600
        : const Color(0xFF0D47A1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          childrenPadding: EdgeInsets.zero,
          iconColor: accentColor,
          collapsedIconColor: Colors.grey.shade500,
          title: Text(
            group.typeName.isEmpty ? 'Jenis tidak diketahui' : group.typeName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Text(
                  '${group.scannedCount}/${group.labelCount} label',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${soV2FormatQuantity(group.totalQuantity)} $unit',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          children: [
            Container(height: 1, color: Colors.grey.shade100),
            for (final label in group.labels)
              _LabelRow(label: label, unit: unit),
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.unit});

  final SoV2LabelRow label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final quantity = label.quantityDisplay(unit);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(
            label.isScanned
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 18,
            color: label.isScanned
                ? Colors.green.shade600
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.primaryValue,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: label.isScanned
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          if (quantity != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: label.isScanned
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                quantity,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: label.isScanned
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Transaksi stock opname sudah selesai.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Center(child: Text(message)),
      ],
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Icon(icon, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
