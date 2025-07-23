import 'package:flutter/material.dart';

class InputLabelStockOpnameDialog extends StatefulWidget {
  final String label;
  final Function(int jmlhSak, double berat) onSave;

  const InputLabelStockOpnameDialog({
    Key? key,
    required this.label,
    required this.onSave,
  }) : super(key: key);

  @override
  _InputLabelStockOpnameDialogState createState() =>
      _InputLabelStockOpnameDialogState();
}

class _InputLabelStockOpnameDialogState
    extends State<InputLabelStockOpnameDialog> {
  final TextEditingController _sakController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();

  String? _sakError;
  String? _beratError;

  @override
  void dispose() {
    _sakController.dispose();
    _beratController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    final sakText = _sakController.text.trim();
    final beratText = _beratController.text.trim();

    int? jmlhSak = int.tryParse(sakText);
    double? berat = double.tryParse(beratText);

    setState(() {
      _sakError = null;
      _beratError = null;

      if (sakText.isEmpty) {
        _sakError = 'Jumlah sak tidak boleh kosong';
      } else if (jmlhSak == null || jmlhSak <= 0) {
        _sakError = 'Jumlah sak harus angka lebih dari 0';
      }

      if (beratText.isEmpty) {
        _beratError = 'Berat tidak boleh kosong';
      } else if (berat == null || berat <= 0) {
        _beratError = 'Berat harus angka lebih dari 0';
      }
    });

    if (_sakError == null && _beratError == null) {
      Navigator.of(context).pop();
      widget.onSave(jmlhSak!, berat!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: const [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Text('Edit Detail'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabelInfo('Label', widget.label),
            const SizedBox(height: 16),
            TextField(
              controller: _sakController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Sak',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2),
                errorText: _sakError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _beratController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Berat (kg)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.scale),
                errorText: _beratError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _validateAndSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan Data'),
        ),
      ],
    );
  }

  Widget _buildLabelInfo(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.qr_code_2, size: 20, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$title: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.black87),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
