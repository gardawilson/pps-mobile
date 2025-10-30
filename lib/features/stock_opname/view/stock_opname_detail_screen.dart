import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../shared/lokasi/lokasi_dropdown.dart';
import '../../../shared/lokasi/lokasi_model.dart';
import '../../../shared/lokasi/lokasi_view_model.dart';
import '../view_model/stock_opname_detail_view_model.dart';
import '../view_model/stock_opname_scan_view_model.dart';
import '../../../widgets/loading_skeleton.dart';
import 'barcode_qr_scan_stock_opname_screen.dart';
import '../model/label_validation_result.dart';
import '../widget/confirmation_label_stock_opname_dialog.dart';
import '../widget/input_detail_label_stock_opname_dialog.dart';
import '../../../widgets/error_status_dialog.dart';
import '../../../widgets/success_status_dialog.dart';
import '../../../widgets/loading_dialog.dart';
import '../widget/input_id_label_stock_opname_dialog.dart';


class StockOpnameDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameDetailScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameDetailScreenState createState() => _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  final ScrollController _scrollController = ScrollController();
// state
  String? _selectedFilter;
  String? _selectedBlok;     // ← baru
  int? _selectedIdLokasi;    // ← ganti ke int?
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<StockOpnameDetailViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LokasiViewModel>().fetchLokasiList(); // ← penting
      viewModel.fetchInitialData(widget.noSO); // lokasi VM fetch di provider/ensureLoaded
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        final vm = context.read<StockOpnameDetailViewModel>();
        if (!isLoadingMore && vm.hasMoreData) {
          isLoadingMore = true;
          vm.loadMoreData().then((_) => isLoadingMore = false);
        }
      }
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tgl} ( ${widget.noSO} )', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLokasiDropdown(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildSummarySection(context), // <== Tambahkan di sini
              ],
            ),
          ),
          Expanded(
            child: Consumer<StockOpnameDetailViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isInitialLoading && viewModel.labels.isEmpty) {
                  return const LoadingSkeleton();
                }

                if (viewModel.errorMessage.isNotEmpty) {
                  return Center(child: Text(viewModel.errorMessage, style: const TextStyle(color: Colors.red)));
                }

                if (viewModel.labels.isEmpty) {
                  return const Center(child: Text('Data Tidak Ditemukan', style: TextStyle(fontSize: 16)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: viewModel.labels.length + (viewModel.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == viewModel.labels.length) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final label = viewModel.labels[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section - Nomor Label & Type
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF2196F3).withOpacity(0.1),
                                                  const Color(0xFF2196F3).withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.qr_code_2_rounded,
                                              color: Color(0xFF2196F3),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label.nomorLabel,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1A1A1A),
                                                letterSpacing: -0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF2196F3),
                                            Color(0xFF1976D2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        label.labelType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Gradient Divider
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF2196F3).withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Info Section
                                Column(
                                  children: [
                                    // Informasi Sak
                                    _buildInfoRow(
                                      icon: Icons.inventory_2_rounded,
                                      label: 'Sak',
                                      value: '${label.jmlhSak}',
                                      iconColor: const Color(0xFF00BCD4),
                                    ),

                                    const SizedBox(height: 10),

                                    // Informasi Berat
                                    _buildInfoRow(
                                      icon: Icons.monitor_weight_rounded,
                                      label: 'Berat',
                                      value: '${label.berat.toStringAsFixed(2)} kg',
                                      iconColor: const Color(0xFFFF9800),
                                    ),

                                    const SizedBox(height: 10),

                                    // Informasi Lokasi
                                    _buildInfoRow(
                                      icon: Icons.place_rounded,
                                      label: 'Lokasi',
                                      value: _formatLokasi(blok: label.blok, idLokasi: label.idLokasi), // ✅
                                      iconColor: const Color(0xFFE91E63),
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );


                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        curve: Curves.linear,
        spaceBetweenChildren: 16,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Scan QR',
            onTap: () {
              _showScanBarQRCode(context);
            },
          ),

          SpeedDialChild(
            child: const Icon(Icons.edit_note),
            label: 'Input Manual',
            onTap: () {
              _showAddManualDialog(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatLokasi({String? blok, int? idLokasi}) {
    final hasBlok = blok != null && blok.isNotEmpty;
    final hasId   = idLokasi != null && idLokasi! > 0;
    if (!hasBlok && !hasId) return '-';
    final sb = StringBuffer();
    if (hasBlok) sb.write(blok);
    if (hasId) sb.write(idLokasi.toString());
    return sb.toString();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        hint: const Text('Filter'),
        isExpanded: true,
        onChanged: (value) {
          setState(() => _selectedFilter = value);
          context.read<StockOpnameDetailViewModel>().fetchInitialData(
            widget.noSO,
            filterBy: value ?? 'all',
            blok: _selectedBlok,
            idLokasi: _selectedIdLokasi,
          );
        },
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Semua')),
          DropdownMenuItem(value: 'bahanbaku', child: Text('Bahan Baku')),
          DropdownMenuItem(value: 'washing', child: Text('Washing')),
          DropdownMenuItem(value: 'broker', child: Text('Broker')),
          DropdownMenuItem(value: 'crusher', child: Text('Crusher')),
          DropdownMenuItem(value: 'bonggolan', child: Text('Bonggolan')),
          DropdownMenuItem(value: 'gilingan', child: Text('Gilingan')),
          DropdownMenuItem(value: 'mixer', child: Text('Mixer')),
          DropdownMenuItem(value: 'furniturewip', child: Text('Furniture WIP')),
          DropdownMenuItem(value: 'barangjadi', child: Text('Barang Jadi')),
          DropdownMenuItem(value: 'reject', child: Text('Reject')),
        ],
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget buildSummarySection(BuildContext context) {
    final viewModel = Provider.of<StockOpnameDetailViewModel>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          border: Border.all(
            color: const Color(0xFF2196F3).withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Summary Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        icon: Icons.label_rounded,
                        label: 'Label',
                        value: '${viewModel.totalData}',
                        iconColor: const Color(0xFF2196F3),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.grey.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      _buildSummaryItem(
                        icon: Icons.monitor_weight_rounded,
                        label: 'Total Berat',
                        value: '${viewModel.totalBerat.toStringAsFixed(2)} kg',
                        iconColor: const Color(0xFFFF9800),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.grey.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      _buildSummaryItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Total Sak',
                        value: '${viewModel.totalSak}',
                        iconColor: const Color(0xFF00BCD4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }


  Widget _buildLokasiDropdown() {
    Lokasi? currentValue() {
      if (_selectedBlok == null && _selectedIdLokasi == null) {
        return const Lokasi(idLokasi: '__SEMUA__', blok: '-', enable: true);
      }
      if (_selectedBlok != null && (_selectedIdLokasi == null || _selectedIdLokasi == 0)) {
        return Lokasi(idLokasi: '', blok: _selectedBlok!, enable: true);
      }
      if (_selectedBlok != null && _selectedIdLokasi != null) {
        return Lokasi(
          idLokasi: _selectedIdLokasi!.toString(),
          blok: _selectedBlok!,
          enable: true,
        );
      }
      return const Lokasi(idLokasi: '__SEMUA__', blok: '-', enable: true);
    }

    return SizedBox(
      width: 180,
      child: LokasiDropdown(
        value: currentValue(),
        includeSemua: true,
        onChanged: (Lokasi? picked) {
          String? blok;
          int? id;

          if (picked == null || picked.idLokasi == '__SEMUA__') {
            blok = null;
            id = null;
          } else {
            blok = picked.blok.isEmpty ? null : picked.blok;
            id   = picked.idLokasi.isEmpty ? null : int.tryParse(picked.idLokasi);
          }

          setState(() {
            _selectedBlok = blok;
            _selectedIdLokasi = id;
          });

          final vm = context.read<StockOpnameDetailViewModel>();
          vm.fetchInitialData(
            widget.noSO,
            filterBy: _selectedFilter ?? 'all',
            blok: _selectedBlok,         // String?
            idLokasi: _selectedIdLokasi, // int?
          );
        },
      ),
    );
  }


  void _showScanBarQRCode(BuildContext context) {
    if (_selectedIdLokasi == null || _selectedIdLokasi == 0) {
      showErrorStatusDialog(context, 'Lokasi belum dipilih!', 'Silakan pilih lokasi terlebih dahulu.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeQrScanStockOpnameScreen(
          noSO: widget.noSO,
          selectedFilter: _selectedFilter ?? 'all',
          idLokasi: _selectedIdLokasi!, // kalau screen ini masih butuh String, ubah param screen ke int
          blok: _selectedBlok,
        ),
      ),
    );
  }


  void _showAddManualDialog(BuildContext context) {
    final scanVM = context.read<StockOpnameScanViewModel>();

    if (_selectedIdLokasi == null || _selectedIdLokasi == 'all') {
      showErrorStatusDialog(context, 'Lokasi belum dipilih!', 'Silakan pilih lokasi terlebih dahulu.');
      return; // Hentikan proses jika belum pilih lokasi
    }

    showDialog(
      context: context,
      builder: (context) => InputIdLabelStockOpnameDialog(
        onSubmit: (label) async {
          final result = await scanVM.validateLabel(label, _selectedBlok!, _selectedIdLokasi!, widget.noSO);

          if (result == null || result.labelType == null || result.labelType.isEmpty) {
            showErrorStatusDialog(context, 'Validasi gagal', 'Tidak dapat memvalidasi label: $label');
            return;
          }

          if (result.isDuplicate) {
            showErrorStatusDialog(context, 'Label Duplikat', '${result.message} Label: $label');
            return;
          }

          if (!result.isValidCategory) {
            showErrorStatusDialog(context, 'Kategori Tidak Valid', '${result.message} Label: $label');
            return;
          }

          await _showConfirmDialog(label, result); // Tampilkan dialog konfirmasi
        },
      ),
    );
  }


  void showErrorStatusDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorStatusDialog(title: title, message: message),
    );
  }


  Future<void> _showConfirmDialog(String label, LabelValidationResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ConfirmationLabelStockOpnameSheet(
          label: label,
          result: result,
          onConfirm: () async {
            Navigator.of(ctx).pop();
            // avoid NPE if server didn’t send values
            await _saveLabel(label, result.jmlhSak ?? 0, result.berat ?? 0);
          },
          onManualInput: () async {
            Navigator.of(ctx).pop();
            await _showManualInputSheet(label);
          },
        );
      },
    );
  }

  Future<void> _showManualInputSheet(String label) async {
    await showInputLabelStockOpnameBottomSheet(
      context: context,
      label: label,
      onSave: (jmlhSak, berat) async {
        await _saveLabel(label, jmlhSak, berat);
      },
    );
  }



  Future<void> _saveLabel(String label, int jmlhSak, double berat) async {
    final scanVM = Provider.of<StockOpnameScanViewModel>(context, listen: false);
    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);

    // Tampilkan dialog loading Lottie
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: 'Menyimpan data label...'),
    );


    try {
      final success = await scanVM.insertLabel(
        label: label,
        noSO: widget.noSO,
        jmlhSak: jmlhSak,
        berat: berat,
        blok: _selectedBlok ?? '',
        idLokasi: _selectedIdLokasi!,
      );

      Navigator.of(context).pop(); // close loading

      if (success) {
        detailVM.fetchInitialData(widget.noSO, filterBy: _selectedFilter ?? 'all');

        showDialog(
          context: context,
          builder: (_) => SuccessStatusDialog(
            title: 'Berhasil!',
            message: 'Label berhasil disimpan.',
            extraContent: _buildLabelSummary(label, jmlhSak, berat),
          ),
        );

      } else {
        Navigator.of(context).pop(); // make sure loading is closed
        showErrorStatusDialog(
          context,
          'Gagal menyimpan data',
          'Label: $label\nSilakan coba lagi.',
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // close loading
      showErrorStatusDialog(
        context,
        'Terjadi kesalahan',
        'Error: ${e.toString()}',
      );
    }
  }

  Widget _buildLabelSummary(String label, int jmlhSak, double berat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDataRow('Label', label),
        _buildDataRow('Jumlah Sak', '$jmlhSak'),
        _buildDataRow('Berat', '${berat.toStringAsFixed(2)} kg'),
      ],
    );
  }

  Widget _buildDataRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Titik dua
          const Text(':'),
          const SizedBox(width: 8),
          // Value
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
