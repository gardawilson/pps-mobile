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
  });

  final String stockOpnameNo;
  final String categoryCode;

  @override
  State<SoV2DetailScreen> createState() => _SoV2DetailScreenState();
}

class _SoV2DetailScreenState extends State<SoV2DetailScreen> {
  late final SoV2DetailViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _labelScrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _viewModel = SoV2DetailViewModel(
      stockOpnameNo: widget.stockOpnameNo,
      categoryCode: widget.categoryCode,
    )..loadBlocks();
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
    if (viewModel.selectedLocation != null) {
      _searchController.clear();
      viewModel.backToLocations();
      return;
    }
    if (viewModel.selectedBlock != null) {
      viewModel.backToBlocks();
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openScanner(SoV2DetailViewModel viewModel) async {
    final block = viewModel.selectedBlock;
    final location = viewModel.selectedLocation;
    if (block == null || location == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SoV2ScanScreen(
          stockOpnameNo: widget.stockOpnameNo,
          blok: block.blok,
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
    if (viewModel.selectedBlock != null) {
      return viewModel.selectBlock(viewModel.selectedBlock!);
    }
    return viewModel.loadBlocks();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SoV2DetailViewModel>(
        builder: (context, viewModel, _) {
          final isLabelStep = viewModel.selectedLocation != null;
          return PopScope(
            canPop:
                viewModel.selectedBlock == null &&
                viewModel.selectedLocation == null,
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
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pageTitle(viewModel),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _pageSubtitle(viewModel),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              body: RefreshIndicator(
                onRefresh: () => _refreshCurrentStep(viewModel),
                child: _buildCurrentStep(viewModel),
              ),
              floatingActionButton: isLabelStep && !viewModel.isComplete
                  ? FloatingActionButton.extended(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      onPressed: () => _openScanner(viewModel),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Label'),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _pageTitle(SoV2DetailViewModel viewModel) {
    if (viewModel.selectedLocation != null) return 'Daftar Label';
    if (viewModel.selectedBlock != null) return 'Pilih Lokasi';
    return 'Pilih Blok';
  }

  String _pageSubtitle(SoV2DetailViewModel viewModel) {
    final block = viewModel.selectedBlock;
    final location = viewModel.selectedLocation;
    if (location != null && block != null) {
      final locationText = location.isUnknown
          ? 'Lokasi tidak diketahui'
          : '${block.blok}${location.locationId}';
      return '${widget.stockOpnameNo} · $locationText';
    }
    if (block != null) {
      final blockText = block.blok == soV2UnknownBlok
          ? 'Tanpa blok'
          : 'Blok ${block.blok}';
      return '${widget.stockOpnameNo} · $blockText';
    }
    return widget.stockOpnameNo;
  }

  Widget _buildCurrentStep(SoV2DetailViewModel viewModel) {
    if (viewModel.selectedLocation != null) {
      return _buildLabelStep(viewModel);
    }
    if (viewModel.selectedBlock != null) {
      return _buildLocationStep(viewModel);
    }
    return _buildBlockStep(viewModel);
  }

  Widget _buildBlockStep(SoV2DetailViewModel viewModel) {
    if (viewModel.isLoadingBlocks && viewModel.blocks.isEmpty) {
      return const _LoadingList(message: 'Memuat daftar blok...');
    }
    if (viewModel.error != null && viewModel.blocks.isEmpty) {
      return _ErrorList(
        message: viewModel.error!,
        onRetry: viewModel.loadBlocks,
      );
    }
    if (viewModel.blocks.isEmpty) {
      return const _EmptyList(
        icon: Icons.grid_view_outlined,
        message: 'Belum ada blok pada stock opname ini.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _StepHeader(
          step: 1,
          title: 'Pilih Blok',
          description: 'Pilih blok tempat proses stock opname dilakukan.',
        ),
        const SizedBox(height: 14),
        for (final block in viewModel.blocks)
          _BlockMenuCard(
            block: block,
            onTap: () => viewModel.selectBlock(block),
          ),
      ],
    );
  }

  Widget _buildLocationStep(SoV2DetailViewModel viewModel) {
    if (viewModel.isLoadingLocations && viewModel.locations.isEmpty) {
      return const _LoadingList(message: 'Memuat daftar lokasi...');
    }
    if (viewModel.error != null && viewModel.locations.isEmpty) {
      return _ErrorList(
        message: viewModel.error!,
        onRetry: () => viewModel.selectBlock(viewModel.selectedBlock!),
      );
    }
    if (viewModel.locations.isEmpty) {
      return const _EmptyList(
        icon: Icons.location_off_outlined,
        message: 'Belum ada lokasi pada blok ini.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _StepHeader(
          step: 2,
          title: 'Pilih Lokasi',
          description: 'Pilih lokasi untuk melihat label yang harus discan.',
        ),
        const SizedBox(height: 14),
        for (final location in viewModel.locations)
          _LocationMenuCard(
            block: viewModel.selectedBlock!,
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
          const _StepHeader(
            step: 3,
            title: 'Scan Label',
            description: 'Periksa daftar label, lalu tekan tombol Scan Label.',
          ),
          const SizedBox(height: 14),
          if (viewModel.isComplete) ...[
            const _CompletedBanner(),
            const SizedBox(height: 12),
          ],
          _LabelSummary(viewModel: viewModel),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => _onSearchChanged(value, viewModel),
            decoration: InputDecoration(
              hintText: 'Cari nomor label...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        viewModel.setSearch('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
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

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.title,
    required this.description,
  });

  final int step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockMenuCard extends StatelessWidget {
  const _BlockMenuCard({required this.block, required this.onTap});

  final SoV2Blok block;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unknown = block.blok == soV2UnknownBlok;
    final progress = block.progress.clamp(0.0, 1.0);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: unknown
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      unknown ? Icons.location_off : Icons.grid_view_rounded,
                      color: unknown
                          ? Colors.orange.shade700
                          : const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unknown ? 'Tanpa Blok' : 'Blok ${block.blok}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${block.locationCount} lokasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${block.scannedCount}/${block.labelCount} label',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationMenuCard extends StatelessWidget {
  const _LocationMenuCard({
    required this.block,
    required this.location,
    required this.onTap,
  });

  final SoV2Blok block;
  final SoV2Lokasi location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = location.progress.clamp(0.0, 1.0);
    final complete =
        location.labelCount > 0 && location.scannedCount >= location.labelCount;
    final locationName = location.isUnknown
        ? 'Lokasi Tidak Diketahui'
        : '${block.blok}${location.locationId}';

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: location.isUnknown
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      location.isUnknown
                          ? Icons.location_off
                          : Icons.location_on_outlined,
                      color: location.isUnknown
                          ? Colors.orange.shade700
                          : const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                locationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (complete) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.green.shade700,
                              ),
                            ],
                          ],
                        ),
                        if (location.description.isNotEmpty)
                          Text(
                            location.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${location.scannedCount}/${location.labelCount} label',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: complete
                          ? Colors.green.shade700
                          : const Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.grey.shade200,
                color: complete ? Colors.green.shade600 : null,
              ),
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
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          group.typeName.isEmpty ? 'Jenis tidak diketahui' : group.typeName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${group.scannedCount}/${group.labelCount} label · '
          '${soV2FormatQuantity(group.totalQuantity)} $unit',
        ),
        children: group.labels
            .map(
              (label) => Container(
                color: label.isScanned ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    label.isScanned
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: label.isScanned
                        ? Colors.green.shade700
                        : Colors.grey,
                    size: 20,
                  ),
                  title: Text(
                    label.primaryValue,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: label.isScanned
                          ? Colors.green.shade800
                          : Colors.black87,
                    ),
                  ),
                  trailing: label.quantityDisplay(unit) == null
                      ? null
                      : Text(label.quantityDisplay(unit)!),
                ),
              ),
            )
            .toList(),
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
