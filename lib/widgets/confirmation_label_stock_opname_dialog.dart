import 'package:flutter/material.dart';
import '/models/label_validation_result.dart';

class ConfirmationLabelStockOpnameDialog extends StatelessWidget {
  final String label;
  final LabelValidationResult result;
  final VoidCallback onConfirm;
  final VoidCallback onManualInput;

  const ConfirmationLabelStockOpnameDialog({
    Key? key,
    required this.label,
    required this.result,
    required this.onConfirm,
    required this.onManualInput,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isValid = result.canInsert == true;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 10),
      titlePadding: const EdgeInsets.only(left: 24, right: 8, top: 24, bottom: 0),
      title: Stack(
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Konfirmasi Label'),
            ],
          ),
          Positioned(
            right: -8,
            top: -8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBox(result.message, isValid),
            const SizedBox(height: 16),
            const Text('Detail Data', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._buildInfoRow('Label', label),
            ..._buildInfoRow('Jenis', result.labelType ?? '-'),
            if (result.hasStockData) ...[
              ..._buildInfoRow('Jumlah Sak', '${result.jmlhSak}'),
              ..._buildInfoRow('Berat', '${result.berat} kg'),
              ..._buildInfoRow('ID Lokasi', '${result.idLokasi}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onManualInput,
          child: const Text('Ubah'),
        ),
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
    );
  }

  Widget _buildStatusBox(String message, bool isValid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
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
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
