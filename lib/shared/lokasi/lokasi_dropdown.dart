import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/app_search_dropdown.dart';
import 'lokasi_view_model.dart';
import 'lokasi_model.dart';

class LokasiDropdown extends StatelessWidget {
  final Lokasi? value; // ✅ sekarang pakai Lokasi, bukan String
  final ValueChanged<Lokasi?>? onChanged;
  final String hint;
  final bool includeSemua;
  final Lokasi semuaOption; // ubah jadi Lokasi juga

  const LokasiDropdown({
    super.key,
    this.value,
    this.onChanged,
    this.hint = 'Pilih Lokasi',
    this.includeSemua = true,
    this.semuaOption = const Lokasi(idLokasi: '__SEMUA__', blok: '-', enable: true),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LokasiViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (vm.errorMessage.isNotEmpty) return Text('Error: ${vm.errorMessage}');
        if (vm.lokasiList.isEmpty) return const Text('Tidak ada data lokasi');

        // ✅ Siapkan daftar lokasi (plus opsi "semua")
        final lokasiItems = <Lokasi>[
          if (includeSemua) semuaOption,
          ...vm.lokasiList,
        ];

        final effectiveValue = value ?? (includeSemua ? semuaOption : null);

        return AppSearchDropdown<Lokasi>(
          value: effectiveValue,
          items: lokasiItems,
          hint: hint,
          itemAsString: (l) {
            if (l.idLokasi == '__SEMUA__') return 'Lokasi (Semua)';
            return l.idLokasi.isEmpty ? l.blok : '${l.blok}${l.idLokasi}';
          },

          // 🔁 pastikan F31 ≠ B31 (bandingkan blok + id)
          compareFn: (a, b) => a.blok == b.blok && a.idLokasi == b.idLokasi,

          // 🔎 pencarian fleksibel: case-insensitive + normalisasi spasi/dash
          filterFn: (l, filter) {
            final q = filter.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
            final k1 = ('${l.blok}${l.idLokasi}').toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
            final k2 = (l.blok).toLowerCase(); // ketik "a" → match semua A..
            return k1.contains(q) || k2.contains(q);
          },

          searchHint: 'Cari…',
          onChanged: (picked) {
            if (onChanged == null) return;
            if (picked?.idLokasi == '__SEMUA__') {
              onChanged!(null);
            } else {
              onChanged!(picked);
            }
          },
        );

      },
    );
  }
}
