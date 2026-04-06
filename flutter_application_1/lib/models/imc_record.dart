class IMCRecord {
  final int id;
  final String firstName;
  final String lastName;
  final String birthDate;
  final double weight;
  final double height;
  final String imc;
  final String date;

  IMCRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.weight,
    required this.height,
    required this.imc,
    required this.date,
  });

  factory IMCRecord.fromJson(Map<String, dynamic> json) {
    return IMCRecord(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      imc: json['imc']?.toString() ?? '0',
      date: json['date'] as String? ?? '',
    );
  }
}