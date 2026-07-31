import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import '../../../core/network/api_errors.dart';
import '../model/so_v2_models.dart';
import '../repository/so_v2_repository.dart';
import 'so_v2_category_style.dart';

class SoV2ScanScreen extends StatefulWidget {
  const SoV2ScanScreen({
    super.key,
    required this.stockOpnameNo,
    required this.blok,
    required this.locationId,
    this.pendingLabels = const [],
  });

  final String stockOpnameNo;
  final String blok;
  final int locationId;

  /// Currently loaded label rows for this lokasi, used to resolve which
  /// pallet a scanned bahan-baku labelNo refers to (see [_submitLabel]).
  /// Only rows already fetched by the detail screen are considered — rows
  /// on further pagination pages are not included.
  final List<SoV2LabelRow> pendingLabels;

  @override
  State<SoV2ScanScreen> createState() => _SoV2ScanScreenState();
}

class _SoV2ScanScreenState extends State<SoV2ScanScreen> {
  final SoV2Repository _repository = SoV2Repository();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _hasPermission = false;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  String? _lastCode;
  Timer? _releaseTimer;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) setState(() => _hasPermission = status.isGranted);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty || code == _lastCode) return;
    _lastCode = code;
    _submitLabel(code);
  }

  Future<void> _showManualInput() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Label Manual'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Nomor label',
            hintText: 'Contoh: B.0000013157 atau A.0000002753-7',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (label != null && label.isNotEmpty) {
      await _submitLabel(label);
    }
  }

  // Bahan baku labels (e.g. "A.0000002753") can have several pallets
  // pending under the same labelNo — pallet disambiguation only applies
  // to this prefix; every other label is submitted as before.
  static final RegExp _palletBasedPrefix = RegExp(
    r'^(AB|A)\.',
    caseSensitive: false,
  );

  final Set<String> _submittedPallets = {};

  String _palletKey(String labelNo, dynamic noPallet) =>
      '${labelNo.trim().toUpperCase()}#$noPallet';

  int? _asPalletInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  Future<SoV2LabelRow?> _pickPallet(List<SoV2LabelRow> candidates) {
    return showModalBottomSheet<SoV2LabelRow>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Pilih Pallet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Label ini punya beberapa pallet yang belum discan. Pilih salah satu:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            for (final row in candidates)
              ListTile(
                leading: const Icon(
                  Icons.inventory_2_outlined,
                  color: soV2ThemeBlue,
                ),
                title: Text('Pallet ${row.raw['NoPallet']}'),
                subtitle: Text(
                  [
                    if (row.raw['Berat'] != null)
                      '${soV2FormatQuantity(row.raw['Berat'])} kg',
                    if (row.raw['JmlhSak'] != null) '${row.raw['JmlhSak']} sak',
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(context).pop(row),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLabel(String labelNo) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final trimmed = labelNo.trim();
    var submitLabelNo = trimmed;
    int? palletNo;

    if (_palletBasedPrefix.hasMatch(trimmed)) {
      // Manual input mirrors the "labelNo-palletNo" format shown in the
      // label list (e.g. "A.0000002753-7") — when present, the pallet is
      // already explicit and no candidate search/picker is needed. A plain
      // scanned barcode only carries labelNo, so that still falls back to
      // matching against pendingLabels below.
      final explicit = RegExp(r'^(.+)-(\d+)$').firstMatch(trimmed);
      if (explicit != null) {
        submitLabelNo = explicit.group(1)!.trim();
        palletNo = int.tryParse(explicit.group(2)!);
      } else {
        final candidates = widget.pendingLabels.where((row) {
          final noBahanBaku = row.raw['NoBahanBaku'];
          final noPallet = row.raw['NoPallet'];
          return noBahanBaku != null &&
              '$noBahanBaku'.trim().toUpperCase() == trimmed.toUpperCase() &&
              !row.isScanned &&
              noPallet != null &&
              !_submittedPallets.contains(_palletKey(trimmed, noPallet));
        }).toList();

        if (candidates.isEmpty) {
          _showMessage(
            'Label tidak ditemukan atau semua pallet sudah discan.',
            isError: true,
          );
          if (mounted) setState(() => _isProcessing = false);
          _releaseCode();
          return;
        }

        if (candidates.length == 1) {
          palletNo = _asPalletInt(candidates.first.raw['NoPallet']);
        } else {
          final chosen = await _pickPallet(candidates);
          if (chosen == null) {
            if (mounted) setState(() => _isProcessing = false);
            _releaseCode();
            return;
          }
          palletNo = _asPalletInt(chosen.raw['NoPallet']);
        }
      }
    }

    try {
      final response = await _repository.submitResult(
        stockOpnameNo: widget.stockOpnameNo,
        labelNo: submitLabelNo,
        blok: widget.blok,
        locationId: widget.locationId,
        palletNo: palletNo,
      );
      await Vibration.vibrate(duration: 80);
      unawaited(_audioPlayer.play(AssetSource('sounds/accepted.mp3')));
      if (!mounted) return;
      if (palletNo != null) {
        _submittedPallets.add(_palletKey(submitLabelNo, palletNo));
      }
      final data = response['data'] as Map<String, dynamic>;
      final details = <String>[
        if (data['weight'] != null) '${data['weight']} kg',
        if (data['pieceCount'] != null) '${data['pieceCount']} pcs',
        if (data['sackCount'] != null) '${data['sackCount']} sak',
      ];
      _showMessage(
        '${response['message']}${details.isEmpty ? '' : '\n${details.join(' · ')}'}',
      );
    } catch (e) {
      await Vibration.vibrate(pattern: [0, 180, 100, 180]);
      unawaited(_audioPlayer.play(AssetSource('sounds/denied.mp3')));
      if (!mounted) return;
      final message = e is ApiFailure
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      _showMessage(message, isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
      _releaseCode();
    }
  }

  void _releaseCode() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(seconds: 2), () {
      _lastCode = null;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          'Scan ${widget.locationId == 0 ? 'Lokasi tidak diketahui' : '${widget.blok}${widget.locationId}'}',
        ),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () async {
              await _scannerController.toggleTorch();
              if (mounted) {
                setState(() => _torchEnabled = !_torchEnabled);
              }
            },
            icon: Icon(_torchEnabled ? Icons.flash_off : Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasPermission)
            MobileScanner(controller: _scannerController, onDetect: _onDetect)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.no_photography,
                    size: 64,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Izin kamera diperlukan',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _requestCameraPermission,
                    child: const Text('Berikan Izin'),
                  ),
                ],
              ),
            ),
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_isProcessing)
            ColoredBox(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: soV2ThemeBlue,
        foregroundColor: Colors.white,
        onPressed: _isProcessing ? null : _showManualInput,
        child: const Icon(Icons.keyboard),
      ),
    );
  }
}
