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
      pickupLocation: json['pickupLocation'] != null
          ? TripLocation.fromJson(json['pickupLocation'])
          : null,
      dropLocation: json['dropLocation'] != null
          ? TripLocation.fromJson(json['dropLocation'])
          : null,
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

class TripLocation {
  final String? address;
  final LocationCoordinates coordinates;

  TripLocation({
    this.address,
    required this.coordinates,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      address: json['address'],
      coordinates: LocationCoordinates.fromJson(json['coordinates'] ?? {}),
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

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      latitude: JsonParser.extractDouble(json['latitude'], 0.0),
      longitude: JsonParser.extractDouble(json['longitude'], 0.0),
    );
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
