// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../view_models/stock_opname_detail_view_model.dart';
// import '../views/barcode_qr_scan_stock_opname_screen.dart';
//
// class ScanLocationDialog extends StatelessWidget {
//   final String noSO; // Tambahkan noSO
//
//   const ScanLocationDialog({Key? key, required this.noSO}) : super(key: key); // Tambahkan konstruktor untuk noSO
//
//   @override
//   Widget build(BuildContext context) {
//     final viewModel = Provider.of<StockOpnameInputViewModel>(context);
//
//     return AlertDialog(
//       title: const Text('Pilih Blok dan ID Lokasi'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           DropdownButton<String>(
//             isExpanded: true,
//             hint: const Text('Pilih Blok'),
//             value: viewModel.blok.isEmpty ? null : viewModel.blok,
//             items: viewModel.blokList
//                 .map((blokData) => blokData.blok)
//                 .toSet()
//                 .map((blok) {
//               return DropdownMenuItem<String>(
//                 value: blok,
//                 child: Text(blok),
//               );
//             }).toList(),
//             onChanged: (value) {
//               if (value != null) {
//                 viewModel.updateBlokAndLokasi(value);
//               }
//             },
//           ),
//           const SizedBox(height: 16),
//           DropdownButton<String>(
//             isExpanded: true,
//             hint: const Text('Pilih ID Lokasi'),
//             value: viewModel.idLokasi.isEmpty ? null : viewModel.idLokasi,
//             items: viewModel.blokList
//                 .where((blokData) => blokData.blok == viewModel.blok)
//                 .map((blokData) {
//               return DropdownMenuItem<String>(
//                 value: blokData.idLokasi,
//                 child: Text(blokData.idLokasi),
//               );
//             }).toList(),
//             onChanged: (value) {
//               if (value != null) {
//                 viewModel.idLokasi = value;
//                 viewModel.notifyListeners();
//               }
//             },
//           ),
//         ],
//       ),
//       actions: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             TextButton(
//               onPressed: () {
//                 viewModel.resetBlokAndLokasi();
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Batal'),
//             ),
//             TextButton(
//               onPressed: viewModel.blok.isNotEmpty && viewModel.idLokasi.isNotEmpty
//                   ? () {
//                 // Navigasi ke BarcodeQrScanScreen
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => BarcodeQrScanScreen(
//                       noSO: noSO,
//                       selectedFilter: 'all',
//                       idLokasi: viewModel.idLokasi,// Kirim noSO
//                     ),
//                   ),
//                 );
//               }
//                   : null,
//               child: const Text('Lanjutkan'), // Ganti "Scan" dengan "Lanjutkan"
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }