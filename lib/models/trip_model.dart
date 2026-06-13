import '../core/utils/json_parser.dart';

class TripModel {
  final String id;
  final String tripId;
  final String transporterId;
  final String vehicleId;
  final String? driverId;
  final String? containerNumber;
  final String? reference;
  final TripLocation? pickupLocation;
  final TripLocation? dropLocation;
  final String tripType;
  final String status;
  final DateTime? driverAcceptedAt;
  final List<MilestoneModel> milestones;
  final PODModel? pod;
  final CurrentMilestone? currentMilestone;
  final VehicleInfo? vehicle;
  final TransporterInfo? transporter;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.tripId,
    required this.transporterId,
    required this.vehicleId,
    this.driverId,
    this.containerNumber,
    this.reference,
    this.pickupLocation,
    this.dropLocation,
    required this.tripType,
    required this.status,
    this.driverAcceptedAt,
    required this.milestones,
    this.pod,
    this.currentMilestone,
    this.vehicle,
    this.transporter,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: JsonParser.extractString(json['_id'] ?? json['id'], ''),
      tripId: JsonParser.extractString(json['tripId'], ''),
      transporterId: JsonParser.extractId(json['transporterId']) ?? '',
      vehicleId: JsonParser.extractId(json['vehicleId']) ?? '',
      driverId: JsonParser.extractId(json['driverId']),
      containerNumber: json['containerNumber']?.toString(),
      reference: json['reference']?.toString(),
      pickupLocation: _parseTripLocation(json['pickupLocation']),
      dropLocation: _parseTripLocation(json['dropLocation']),
      tripType: JsonParser.extractString(json['tripType'], 'EXPORT'),
      status: JsonParser.extractString(json['status'], 'PLANNED'),
      driverAcceptedAt: JsonParser.extractDateTime(json['driverAcceptedAt']),
      milestones: JsonParser.extractList<MilestoneModel>(
        json['milestones'],
        (json) => MilestoneModel.fromJson(json),
      ),
      pod: json['POD'] != null ? PODModel.fromJson(json['POD']) : null,
      currentMilestone: json['currentMilestone'] != null
          ? CurrentMilestone.fromJson(json['currentMilestone'])
          : null,
      vehicle: json['vehicleId'] != null && json['vehicleId'] is Map
          ? VehicleInfo.fromJson(json['vehicleId'])
          : null,
      transporter: json['transporterId'] != null && json['transporterId'] is Map
          ? TransporterInfo.fromJson(json['transporterId'])
          : null,
      createdAt: JsonParser.extractDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: JsonParser.extractDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

/// API uses GeoJSON Point: `{ type, coordinates: [lng, lat], formattedAddress, ... }`.
TripLocation? _parseTripLocation(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    try {
      return TripLocation.fromJson(Map<String, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }
  return null;
}

class TripLocation {
  final String? address;
  final LocationCoordinates coordinates;

  TripLocation({
    this.address,
    required this.coordinates,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      address: json['address']?.toString() ??
          json['formattedAddress']?.toString(),
      coordinates: LocationCoordinates.fromJson(json['coordinates']),
    );
  }
}

class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  /// Handles `{ latitude, longitude }` (milestones, legacy) and GeoJSON `[longitude, latitude]`.
  factory LocationCoordinates.fromJson(dynamic json) {
    if (json == null) {
      return LocationCoordinates(latitude: 0, longitude: 0);
    }
    if (json is List) {
      if (json.length >= 2) {
        final a = (json[0] as num).toDouble();
        final b = (json[1] as num).toDouble();
        return LocationCoordinates(longitude: a, latitude: b);
      }
      return LocationCoordinates(latitude: 0, longitude: 0);
    }
    if (json is Map) {
      final m = Map<String, dynamic>.from(json);
      return LocationCoordinates(
        latitude: JsonParser.extractDouble(m['latitude'], 0.0),
        longitude: JsonParser.extractDouble(m['longitude'], 0.0),
      );
    }
    return LocationCoordinates(latitude: 0, longitude: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class MilestoneModel {
  final String milestoneType;
  final int milestoneNumber;
  final DateTime timestamp;
  final LocationCoordinates location;
  final String? photo;
  final String driverId;
  final String backendMeaning;

  MilestoneModel({
    required this.milestoneType,
    required this.milestoneNumber,
    required this.timestamp,
    required this.location,
    this.photo,
    required this.driverId,
    required this.backendMeaning,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      milestoneType: JsonParser.extractString(json['milestoneType'], ''),
      milestoneNumber: JsonParser.extractInt(json['milestoneNumber'], 0),
      timestamp: JsonParser.extractDateTime(json['timestamp']) ?? DateTime.now(),
      location: LocationCoordinates.fromJson(json['location'] ?? {}),
      photo: json['photo']?.toString(),
      driverId: JsonParser.extractId(json['driverId']) ?? '',
      backendMeaning: JsonParser.extractString(json['backendMeaning'], ''),
    );
  }
}

class CurrentMilestone {
  final int milestoneNumber;
  final String milestoneType;
  final String? label;

  CurrentMilestone({
    required this.milestoneNumber,
    required this.milestoneType,
    this.label,
  });

  factory CurrentMilestone.fromJson(Map<String, dynamic> json) {
    return CurrentMilestone(
      milestoneNumber: JsonParser.extractInt(json['milestoneNumber'], 0),
      milestoneType: JsonParser.extractString(json['milestoneType'], ''),
      label: json['label']?.toString(),
    );
  }
}

class PODModel {
  final String? photo;
  final DateTime? uploadedAt;
  final String? uploadedBy;
  final DateTime? approvedAt;
  final String? approvedBy;

  PODModel({
    this.photo,
    this.uploadedAt,
    this.uploadedBy,
    this.approvedAt,
    this.approvedBy,
  });

  factory PODModel.fromJson(Map<String, dynamic> json) {
    return PODModel(
      photo: json['photo']?.toString(),
      uploadedAt: JsonParser.extractDateTime(json['uploadedAt']),
      uploadedBy: JsonParser.extractId(json['uploadedBy']),
      approvedAt: JsonParser.extractDateTime(json['approvedAt']),
      approvedBy: JsonParser.extractId(json['approvedBy']),
    );
  }
}

class VehicleInfo {
  final String vehicleNumber;
  final String? trailerType;

  VehicleInfo({
    required this.vehicleNumber,
    this.trailerType,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      vehicleNumber: JsonParser.extractString(json['vehicleNumber'], ''),
      trailerType: json['trailerType']?.toString(),
    );
  }
}

class TransporterInfo {
  final String id;
  final String name;
  final String company;
  final String? mobile;

  TransporterInfo({
    required this.id,
    required this.name,
    required this.company,
    this.mobile,
  });

  factory TransporterInfo.fromJson(Map<String, dynamic> json) {
    return TransporterInfo(
      id: JsonParser.extractString(json['_id'] ?? json['id'], ''),
      name: JsonParser.extractString(json['name'], ''),
      company: JsonParser.extractString(json['company'], ''),
      mobile: json['mobile']?.toString(),
    );
  }
}
