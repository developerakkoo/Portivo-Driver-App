class AuthResponseModel {
  final bool success;
  final String message;
  final AuthData? data;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }
}

class AuthData {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

class UserModel {
  final String id;
  final String mobile;
  final String? name;
  final String userType;
  final String status;
  final bool hasPinSet;
  final String? transporterId;

  UserModel({
    required this.id,
    required this.mobile,
    this.name,
    required this.userType,
    required this.status,
    required this.hasPinSet,
    this.transporterId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      mobile: json['mobile'] ?? '',
      name: json['name'],
      userType: json['userType'] ?? '',
      status: json['status'] ?? '',
      hasPinSet: json['hasPinSet'] ?? false,
      transporterId: json['transporterId']?.toString(),
    );
  }
}
