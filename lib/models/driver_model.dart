import '../core/utils/json_parser.dart';

class DriverModel {
  final String id;
  final String mobile;
  final String? name;
  final String? transporterId;
  final TransporterInfo? transporter;
  final String status;
  final String? riskLevel;
  final String? language;
  final double walletBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.mobile,
    this.name,
    this.transporterId,
    this.transporter,
    required this.status,
    this.riskLevel,
    this.language,
    required this.walletBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: JsonParser.extractString(json['_id'] ?? json['id'], ''),
      mobile: JsonParser.extractString(json['mobile'], ''),
      name: json['name']?.toString(),
      transporterId: JsonParser.extractId(json['transporterId']),
      transporter: json['transporter'] != null
          ? TransporterInfo.fromJson(json['transporter'])
          : null,
      status: JsonParser.extractString(json['status'], 'pending'),
      riskLevel: json['riskLevel']?.toString(),
      language: json['language']?.toString(),
      walletBalance: JsonParser.extractDouble(json['walletBalance'], 0.0),
      createdAt: JsonParser.extractDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: JsonParser.extractDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'language': language,
    };
  }
}

class TransporterInfo {
  final String id;
  final String name;
  final String company;
  final String mobile;

  TransporterInfo({
    required this.id,
    required this.name,
    required this.company,
    required this.mobile,
  });

  factory TransporterInfo.fromJson(Map<String, dynamic> json) {
    return TransporterInfo(
      id: JsonParser.extractString(json['_id'] ?? json['id'], ''),
      name: JsonParser.extractString(json['name'], ''),
      company: JsonParser.extractString(json['company'], ''),
      mobile: JsonParser.extractString(json['mobile'], ''),
    );
  }
}
