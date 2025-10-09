import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../view_model/stock_opname_scan_view_model.dart';
import '../view_model/stock_opname_detail_view_model.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/label_validation_result.dart';
import '../widget/confirmation_label_stock_opname_dialog.dart';
import '../widget/input_detail_label_stock_opname_dialog.dart';
import '../../../widgets/scan_notification.dart';
import '../../../widgets/status_indicator.dart';

class BarcodeQrScanStockOpnameScreen extends StatefulWidget {
  final String noSO;
  final String selectedFilter;
  final String idLokasi;

  const BarcodeQrScanStockOpnameScreen({
    Key? key,
    required this.noSO,
    required this.selectedFilter,
    required this.idLokasi,
  }) : super(key: key);

  @override
  _BarcodeQrScanStockOpnameScreenState createState() =>
      _BarcodeQrScanStockOpnameScreenState();
}

class _BarcodeQrScanStockOpnameScreenState extends State<BarcodeQrScanStockOpnameScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  bool isFlashOn = false;
  bool hasCameraPermission = false;
  late AnimationController _animationController;
  bool _isDetected = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSaving = false;
  String _saveMessage = '';
  String _detailedMessage = '';
  bool _isSuccess = false;
  bool _showStatusIndicator = false;

  Timer? _debounceTimer;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _getCameraPermission();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
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
          await _saveLabel(label, result.jmlhSak ?? 0, result.berat ?? 0);
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
    setState(() {
      _isSaving = true;
      _saveMessage = 'Menyimpan data...';
      _detailedMessage = '';
      _isSuccess = false;
      _showStatusIndicator = false;
    });

    try {
      final scanVM = Provider.of<StockOpnameScanViewModel>(context, listen: false);
      final success = await scanVM.insertLabel(
        label: label,
        noSO: widget.noSO,
        jmlhSak: jmlhSak,
        berat: berat,
        idLokasi: widget.idLokasi,
      );

      if (success) {
        _audioPlayer.play(AssetSource('sounds/accepted.mp3'));
        Provider.of<StockOpnameDetailViewModel>(context, listen: false)
            .fetchInitialData(
          widget.noSO,
          filterBy: widget.selectedFilter,
          idLokasi: widget.idLokasi,
        );

        _showSuccessStatus(
          'Data Berhasil Disimpan! 🎉',
          'Label: $label\nJumlah: $jmlhSak sak\nBerat: $berat kg',
        );
      } else {
        _audioPlayer.play(AssetSource('sounds/denied.mp3'));
        _showErrorStatus(
          'Gagal Menyimpan Data',
          'Label: $label\nSilakan coba lagi',
        );
      }
    } catch (e) {
      _audioPlayer.play(AssetSource('sounds/denied.mp3'));
      _showErrorStatus(
        'Terjadi Kesalahan',
        'Error: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessStatus(String title, String message) {
    setState(() {
      _saveMessage = title;
      _detailedMessage = message;
      _isSuccess = true;
      _showStatusIndicator = true;
    });

    // Show haptic feedback
    Vibration.vibrate(duration: 100, amplitude: 128);

    // Auto clear after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _saveMessage = '';
          _detailedMessage = '';
          _lastScannedCode = null;
          _showStatusIndicator = false;
        });
      }
    });
  }

  void _showErrorStatus(String title, String message) {
    setState(() {
      _saveMessage = title;
      _detailedMessage = message;
      _isSuccess = false;
      _showStatusIndicator = true;
    });

    // Show error vibration pattern
    Vibration.vibrate(pattern: [0, 200, 100, 200]);

    // Auto clear after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _saveMessage = '';
          _detailedMessage = '';
          _lastScannedCode = null;
          _showStatusIndicator = false;
        });
      }
    });
  }

  void _dismissNotification() {
    setState(() {
      _saveMessage = '';
      _detailedMessage = '';
      _lastScannedCode = null;
      _showStatusIndicator = false;
    });
  }

  void _retryLastScan() {
    if (_lastScannedCode != null) {
      _processScanResult(_lastScannedCode!);
    }
  }

  Future<void> _getCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasCameraPermission = status == PermissionStatus.granted;
    });

    if (status == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Izin kamera diperlukan untuk scanning'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Buka Pengaturan',
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _processScanResult(String rawValue) async {
    if (rawValue == _lastScannedCode) {
      debugPrint('Duplicate scan ignored.');
      return;
    }

    _lastScannedCode = rawValue;

    setState(() {
      _isSaving = true;
      _saveMessage = 'Memvalidasi label...';
      _detailedMessage = '';
      _isSuccess = false;
      _showStatusIndicator = false;
    });

    try {
      final scanVM = Provider.of<StockOpnameScanViewModel>(context, listen: false);
      final result = await scanVM.validateLabel(rawValue, widget.noSO);

      debugPrint('🔍 Result: $result');
      debugPrint('🔍 Result.labelType: ${result?.labelType}');
      debugPrint('🔍 Result.message: ${result?.message}');
      debugPrint('🔍 Result.foundInStockOpname: ${result?.foundInStockOpname}');
      debugPrint('🔍 Result.isDuplicate: ${result?.isDuplicate}');
      debugPrint('🔍 Result.canInsert: ${result?.canInsert}');

      setState(() {
        _isSaving = false;
      });

      // Check if result is null or doesn't have required data
      if (result == null || result.labelType == null ) {
        _audioPlayer.play(AssetSource('sounds/denied.mp3'));
        _showErrorStatus(
            'Validasi Gagal',
            'Label tidak dapat divalidasi\nLabel: $rawValue'
        );
        return;
      }

      // Handle duplicate label case
      if (result.isDuplicate) {
        _audioPlayer.play(AssetSource('sounds/denied.mp3'));
        _showErrorStatus('Label Duplikat!', result.message);
        return;
      }

      // Handle category invalid case
      if (!result.isValidCategory && result.foundInStockOpname) {
        _audioPlayer.play(AssetSource('sounds/denied.mp3'));
        _showErrorStatus('Kategori Tidak Sesuai', result.message);
        return;
      }

      // If validation successful, show confirmation dialog
      await _showConfirmDialog(rawValue, result);

    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      debugPrint('❌ Error saat validasi: $e');
      _audioPlayer.play(AssetSource('sounds/denied.mp3'));
      _showErrorStatus(
          'Koneksi Bermasalah 📱',
          'Periksa koneksi internet Anda'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scanAreaSize = screenWidth * 0.6;
    int count = Provider.of<StockOpnameDetailViewModel>(context, listen: false)
        .totalData;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Lokasi ${widget.idLokasi} | ${count}',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_off : Icons.flash_on,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
              });
              cameraController.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          if (hasCameraPermission)
            MobileScanner(
              controller: cameraController,
              scanWindow: Rect.fromCenter(
                center: Offset(screenWidth / 2, screenHeight / 2),
                width: scanAreaSize,
                height: scanAreaSize,
              ),
              onDetect: (capture) {
                try {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    final String rawValue = barcodes.first.rawValue!;

                    if (!_isDetected) {
                      setState(() {
                        _isDetected = true;
                      });
                      _animationController.forward(from: 0);

                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          _isDetected = false;
                        });
                        _processScanResult(rawValue);
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Error during barcode detection: $e');
                  _showErrorStatus(
                      'Error Scan 📱',
                      'Terjadi kesalahan saat memproses barcode'
                  );
                }
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Izin kamera diperlukan untuk scanning',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getCameraPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Berikan Izin Kamera',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // Scan area overlay with enhanced animation
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDetected
                      ? Colors.greenAccent
                      : Colors.white.withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: _isDetected
                    ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ]
                    : null,
              ),
              child: _isDetected
                  ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: Colors.greenAccent.withOpacity(0.1),
                ),
              )
                  : null,
            ),
          ),

          // Enhanced status indicator
          if (_showStatusIndicator)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: StatusIndicator(
                  isSuccess: _isSuccess,
                  isVisible: _showStatusIndicator,
                ),
              ),
            ),

          // Interactive notification
          if (_saveMessage.isNotEmpty)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: ScanNotification(
                title: _saveMessage,
                message: _detailedMessage,
                isSuccess: _isSuccess,
                isLoading: _isSaving,
                onDismiss: _dismissNotification,
                onRetry: !_isSuccess && !_isSaving ? _retryLastScan : null,
              ),
            ),

          // Scan instruction overlay
          if (_saveMessage.isEmpty && !_isSaving)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Arahkan kamera ke barcode atau QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}