import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pps_mobile/shared/components/app_drawer.dart';

import '../model/so_v2_models.dart';
import '../view_model/so_v2_category_view_model.dart';
import 'so_v2_detail_screen.dart';

class SoV2CategoryScreen extends StatefulWidget {
  const SoV2CategoryScreen({super.key});

  @override
  State<SoV2CategoryScreen> createState() => _SoV2CategoryScreenState();
}

class _SoV2CategoryScreenState extends State<SoV2CategoryScreen> {
  late final SoV2CategoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SoV2CategoryViewModel()..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openCategory(SoV2Kategori category) async {
    if (category.status != SoV2Status.inProgress) return;

    final stockOpnameNo = category.stockOpnameNo;
    if (stockOpnameNo == null || stockOpnameNo.isEmpty) {
      _showMessage('Nomor stock opname tidak tersedia.');
      return;
    }
    await _openDetail(
      stockOpnameNo: stockOpnameNo,
      categoryCode: category.categoryCode,
      categoryName: category.categoryName,
    );
  }

  Future<void> _openDetail({
    required String stockOpnameNo,
    required String categoryCode,
    required String categoryName,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoV2DetailScreen(
          stockOpnameNo: stockOpnameNo,
          categoryCode: categoryCode,
          categoryName: categoryName,
        ),
      ),
    );
    if (mounted) {
      await _viewModel.load();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SoV2CategoryViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          drawer: const AppDrawer(currentRoute: '/stockopname-v2'),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Opname V2',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
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

  Widget _buildBody(SoV2CategoryViewModel viewModel) {
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
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('Belum ada kategori', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = viewModel.items[index];
        return _CategoryCard(
          category: category,
          onTap: () => _openCategory(category),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final SoV2Kategori category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = category.progress.clamp(0.0, 1.0);
    final clickable = category.status == SoV2Status.inProgress;
    return Opacity(
      opacity: clickable ? 1 : 0.6,
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: clickable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: category.status.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            category.stockOpnameNo ?? category.categoryCode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.status.label,
                      style: TextStyle(
                        color: category.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${category.scannedCount}/${category.labelCount} label',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    color: category.status.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
