import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pps_mobile/shared/components/app_drawer.dart';

import '../../../constants/kategori_constants.dart';
import '../model/so_v2_models.dart';
import '../view_model/so_v2_my_lokasi_view_model.dart';
import 'so_v2_category_style.dart';
import 'so_v2_detail_screen.dart';

class SoV2MyLokasiScreen extends StatefulWidget {
  const SoV2MyLokasiScreen({super.key});

  @override
  State<SoV2MyLokasiScreen> createState() => _SoV2MyLokasiScreenState();
}

class _SoV2MyLokasiScreenState extends State<SoV2MyLokasiScreen> {
  late final SoV2MyLokasiViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SoV2MyLokasiViewModel()..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openDetail(SoV2MyLokasi myLokasi) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoV2DetailScreen(myLokasi: myLokasi),
      ),
    );
    if (mounted) {
      await _viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SoV2MyLokasiViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          drawer: const AppDrawer(currentRoute: '/stockopname-v2'),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            title: const Text(
              'Stock Opname V2',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: viewModel.load,
            child: _buildBody(viewModel),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SoV2MyLokasiViewModel viewModel) {
    if (viewModel.isLoading && viewModel.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null && viewModel.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(viewModel.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: viewModel.load,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }
    if (viewModel.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada lokasi stock opname.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          'Lokasi Anda',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih salah satu lokasi di bawah untuk mulai scan label.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        for (final myLokasi in viewModel.items) ...[
          _MyLokasiCard(
            myLokasi: myLokasi,
            onTap: () => _openDetail(myLokasi),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _MyLokasiCard extends StatelessWidget {
  const _MyLokasiCard({required this.myLokasi, required this.onTap});

  final SoV2MyLokasi myLokasi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = myLokasi.location;
    final progress = location.progress.clamp(0.0, 1.0);
    final complete =
        location.labelCount > 0 && location.scannedCount >= location.labelCount;
    final icon = soV2IconForCategory(myLokasi.categoryCode);
    final categoryName = KategoriConstants.getLabel(myLokasi.categoryCode);
    final locationName = location.isUnknown
        ? 'Lokasi Tidak Diketahui'
        : '${location.blok}${location.locationId}';
    final unit = myLokasi.categoryCode.toLowerCase() == 'furniturewip'
        ? 'pcs'
        : 'kg';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: soV2ThemeBlue.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner header: nama lokasi sebagai judul utama.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [soV2ThemeBlue, soV2ThemeBlueLight],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -12,
                      top: -18,
                      child: Icon(
                        icon,
                        size: 92,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            locationName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    categoryName,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (complete) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 13,
                                      color: soV2CompleteGreen,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Selesai',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: soV2CompleteGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Detail: progress dan ringkasan label.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${location.scannedCount}/${location.labelCount} label discan',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: soV2ThemeBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: complete ? soV2CompleteGreen : soV2ThemeBlue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.scale_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${soV2FormatQuantity(location.totalQuantity)} $unit total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          myLokasi.stockOpnameNo,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
