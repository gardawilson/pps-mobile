class StockOpname {
  final String noSO;
  final String tanggal;
  final String namaWarehouse;
  final bool isBahanBaku;
  final bool isWashing;
  final bool isBonggolan;
  final bool isCrusher;
  final bool isBroker;
  final bool isGilingan;
  final bool isMixer;
  final bool isFurnitureWIP;
  final bool isBarangJadi;
  final bool isReject;

  StockOpname({
    required this.noSO,
    required this.tanggal,
    required this.namaWarehouse,
    required this.isBahanBaku,
    required this.isWashing,
    required this.isBonggolan,
    required this.isCrusher,
    required this.isBroker,
    required this.isGilingan,
    required this.isMixer,
    required this.isFurnitureWIP,
    required this.isBarangJadi,
    required this.isReject,
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      noSO: json['NoSO'] ?? '',
      tanggal: json['Tanggal']?.toString() ?? '',
      namaWarehouse: json['NamaWarehouse'] ?? '-',
      isBahanBaku: json['IsBahanBaku'] ?? false,
      isWashing: json['IsWashing'] ?? false,
      isBonggolan: json['IsBonggolan'] ?? false,
      isCrusher: json['IsCrusher'] ?? false,
      isBroker: json['IsBroker'] ?? false,
      isGilingan: json['IsGilingan'] ?? false,
      isMixer: json['IsMixer'] ?? false,
      isFurnitureWIP: json['IsFurnitureWIP'] ?? false,
      isBarangJadi: json['IsBarangJadi'] ?? false,
      isReject: json['IsReject'] ?? false,
    );
  }
}
