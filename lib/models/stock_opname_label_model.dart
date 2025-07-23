class StockOpnameLabel {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;
  final double berat;
  final String? idLokasi;

  StockOpnameLabel({
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    required this.idLokasi,
  });

  factory StockOpnameLabel.fromJson(Map<String, dynamic> json) {
    return StockOpnameLabel(
      nomorLabel: json['NomorLabel'],
      labelType: json['LabelType'],
      jmlhSak: json['JmlhSak'] ?? 0,
      berat: (json['Berat'] as num).toDouble(),
      idLokasi: json['IdLokasi'],
    );
  }
}
