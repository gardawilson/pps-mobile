import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_models/stock_opname_detail_view_model.dart';
import '../view_models/lokasi_view_model.dart';
import '../view_models/stock_opname_scan_view_model.dart';
import '../widgets/loading_skeleton.dart';
import '../views/barcode_qr_scan_stock_opname_screen.dart';
import '../models/label_validation_result.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../widgets/confirmation_label_stock_opname_dialog.dart';
import '../widgets/input_detail_label_stock_opname_dialog.dart';
import '../widgets/error_status_dialog.dart';
import '../widgets/success_status_dialog.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/input_id_label_stock_opname_dialog.dart';



class StockOpnameDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameDetailScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameDetailScreenState createState() => _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedFilter;
  String? _selectedIdLokasi;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final lokasiVM = Provider.of<LokasiViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchInitialData(widget.noSO);
      lokasiVM.fetchLokasi();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
        if (!isLoadingMore && viewModel.hasMoreData) {
          isLoadingMore = true;
          viewModel.loadMoreData().then((_) {
            isLoadingMore = false;
          });
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
            child: Row(
              children: [
                _buildFilterDropdown(),
                const SizedBox(width: 12),
                _buildLokasiDropdown(), // Tambahkan dropdown lokasi
                const SizedBox(width: 12),
                _buildCountText(),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bagian Nomor Label (Judul)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label.nomorLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    label.labelType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Informasi Sak
                            Row(
                              children: [
                                const Icon(Icons.shopping_bag, size: 18, color: Colors.teal),
                                const SizedBox(width: 6),
                                Text('Sak: ${label.jmlhSak}'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Informasi Berat
                            Row(
                              children: [
                                const Icon(Icons.scale, size: 18, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text('Berat: ${label.berat.toStringAsFixed(2)} kg'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Informasi Lokasi
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Text('Lokasi: ${label.idLokasi}'),
                              ],
                            ),
                          ],
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
          setState(() {
            _selectedFilter = value;
          });
          final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
          viewModel.fetchInitialData(
            widget.noSO,
            filterBy: value ?? 'all',
            idLokasi: _selectedIdLokasi, // Pertahankan idLokasi saat filter berubah
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
        ],
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCountText() {
    final count = Provider.of<StockOpnameDetailViewModel>(context).totalData;
    return Text(
      '$count Label',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLokasiDropdown() {
    return Consumer<LokasiViewModel>(
      builder: (context, lokasiVM, child) {
        if (lokasiVM.isLoading) {
          return const SizedBox(
            width: 125,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // List item dengan value dan label
        final lokasiItems = [
          const MapEntry('all', 'Semua'), // Value = 'all', Label = 'Semua'
          ...lokasiVM.lokasiList.map(
                (e) => MapEntry(e.idLokasi, e.idLokasi),
          ),
        ];

        // Temukan item yang sedang dipilih berdasarkan value _selectedIdLokasi
        final selectedEntry = lokasiItems.firstWhere(
              (item) => item.key == (_selectedIdLokasi ?? 'all'),
          orElse: () => lokasiItems.first,
        );

        return Container(
          width: 125,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownSearch<MapEntry<String, String>>(
            items: lokasiItems,
            selectedItem: selectedEntry,
            itemAsString: (item) => item.value, // Tampilkan label (e.g., 'Semua')
            popupProps: const PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Cari lokasi...",
                ),
              ),
            ),
            dropdownButtonProps: const DropdownButtonProps(
              icon: Icon(Icons.arrow_drop_down),
              padding: EdgeInsets.zero,
            ),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                hintText: "Lokasi",
              ),
            ),
            onChanged: (selectedEntry) {
              final selectedId = selectedEntry?.key;

              setState(() {
                _selectedIdLokasi = selectedId;
              });

              final viewModel = Provider.of<StockOpnameDetailViewModel>(
                context,
                listen: false,
              );

              viewModel.fetchInitialData(
                widget.noSO,
                filterBy: _selectedFilter ?? 'all',
                idLokasi: selectedId == 'all' ? null : selectedId,
              );
            },
          ),
        );
      },
    );
  }


  void _showScanBarQRCode(BuildContext context) {
    if (_selectedIdLokasi == null || _selectedIdLokasi!.isEmpty || _selectedIdLokasi == 'all') {
      showErrorStatusDialog(context, 'Lokasi belum dipilih!', 'Silakan pilih lokasi terlebih dahulu.');
      return; // Hentikan proses jika belum pilih lokasi
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeQrScanStockOpnameScreen(
          noSO: widget.noSO,
          selectedFilter: _selectedFilter ?? 'all',
          idLokasi: _selectedIdLokasi!,
        ),
      ),
    );
  }


  void _showAddManualDialog(BuildContext context) {
    final scanVM = context.read<StockOpnameScanViewModel>();

    if (_selectedIdLokasi == null || _selectedIdLokasi!.isEmpty || _selectedIdLokasi == 'all') {
      showErrorStatusDialog(context, 'Lokasi belum dipilih!', 'Silakan pilih lokasi terlebih dahulu.');
      return; // Hentikan proses jika belum pilih lokasi
    }

    showDialog(
      context: context,
      builder: (context) => InputIdLabelStockOpnameDialog(
        onSubmit: (label) async {
          final result = await scanVM.validateLabel(label, widget.noSO);

          if (result == null || result.labelType == null || result.labelType!.isEmpty) {
            showErrorStatusDialog(context, 'Validasi gagal', 'Tidak dapat memvalidasi label: $label');
            return;
          }

          if (result.isDuplicate) {
            showErrorStatusDialog(context, 'Label Duplikat', 'Label sudah pernah dipakai: $label');
            return;
          }

          if (!result.isValidCategory) {
            showErrorStatusDialog(context, 'Kategori Tidak Valid', 'Kategori tidak sesuai: $label');
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmationLabelStockOpnameDialog(
        label: label,
        result: result,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await _saveLabel(label, result.jmlhSak!, result.berat!);
        },
        onManualInput: () async {
          Navigator.of(ctx).pop();
          await _showManualInputDialog(label);
        },
      ),
    );
  }


  Future<void> _showManualInputDialog(String label) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InputLabelStockOpnameDialog(
        label: label,
        onSave: (jmlhSak, berat) async {
          await _saveLabel(label, jmlhSak, berat);
        },
      ),
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
