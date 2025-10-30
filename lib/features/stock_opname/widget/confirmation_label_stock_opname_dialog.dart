import 'package:flutter/material.dart';
import '../model/label_validation_result.dart';

class ConfirmationLabelStockOpnameSheet extends StatelessWidget {
  final String label;
  final LabelValidationResult result;
  final VoidCallback onConfirm;
  final VoidCallback onManualInput;

  const ConfirmationLabelStockOpnameSheet({
    Key? key,
    required this.label,
    required this.result,
    required this.onConfirm,
    required this.onManualInput,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isValid = result.canInsert == true;
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.5; // up to 80% of screen

    return Padding(
      // push content above the keyboard when it shows
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Stack(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Konfirmasi Label',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBox(result.message, isValid),
                    const SizedBox(height: 16),

                    const Text('Detail Data', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    ..._buildInfoRow('Label', label),
                    ..._buildInfoRow('Jenis', result.labelType ?? '-'),
                    ..._buildInfoRow('Qty', '${result.jmlhSak ?? "-"}'),
                    ..._buildInfoRow('Berat', '${result.berat ?? "-"} kg'),
                    ..._buildInfoRow('Lokasi', result.idLokasi ?? '-'),

                    if (result.mesinInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text('Data Mesin', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      for (final mesin in result.mesinInfo) ...[
                        ..._buildInfoRow('Mesin', mesin.namaMesin),
                        ..._buildInfoRow('Operator', mesin.namaOperator),
                        const Divider(height: 12),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // actions bar pinned at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: onManualInput,
                    child: const Text('Ubah'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Simpan Data'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String message, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.cancel,
              color: isValid ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isValid ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoRow(String label, String value) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
          ],
        ),
      ),
    ];
  }
}
