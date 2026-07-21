import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../../../core/network/api_errors.dart';
import '../repository/mapping_v2_repository.dart';

class MappingV2ScanScreen extends StatefulWidget {
  const MappingV2ScanScreen({
    super.key,
    required this.blok,
    required this.idLokasi,
  });

  final String blok;
  final int idLokasi;

  @override
  State<MappingV2ScanScreen> createState() => _MappingV2ScanScreenState();
}

class _MappingV2ScanScreenState extends State<MappingV2ScanScreen> {
  final MappingV2Repository _repository = MappingV2Repository();
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
            hintText: 'Contoh: B.0000013157',
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
    controller.dispose();
    if (label != null && label.isNotEmpty) {
      await _submitLabel(label);
    }
  }

  Future<void> _submitLabel(String labelCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _repository.updateLokasi(
        labelCode: labelCode,
        blok: widget.blok,
        idLokasi: widget.idLokasi,
      );
      await Vibration.vibrate(duration: 80);
      unawaited(_audioPlayer.play(AssetSource('sounds/accepted.mp3')));
      if (!mounted) return;
      _showMessage(result.message, isError: false);
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
        title: Text('Scan ${widget.blok}${widget.idLokasi}'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _showManualInput,
        icon: const Icon(Icons.keyboard),
        label: const Text('Input Manual'),
      ),
    );
  }
}
