class VendorModel {
  bool? status;
  String? msg;
  Data? data;

  VendorModel({this.status, this.msg, this.data});

  VendorModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    msg = json['msg'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  Vendor? vendor;

  Data({this.vendor});

  Data.fromJson(Map<String, dynamic> json) {
    vendor = json['vendor'] != null
        ? new Vendor.fromJson(json['vendor'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.vendor != null) {
      data['vendor'] = this.vendor!.toJson();
    }
    return data;
  }
}

class Vendor {
  final String id;
  final String name;
  final String mobile;
  final String cityName;
  final int cityId;
  final String stateName;
  final int stateId;
  final String pincode;
  final String address;
  final bool accountIsActive;
  final String alternativeMobile;
  final String email;
  final double walletBalance;
  final String gender;
  final String dob;
  final String profilePic;
  final String idProofPic;
  final String idProofName;
  final String accessToken;
  final int orderCapacity;
  final int garmentCapacity;
  final int currentGarmentLoad;
  final int currentLoad;
  final List<dynamic> areaCover;
  final bool canPickup;
  final bool canProcess;
  final bool canDeliver;
  final bool canIroning;
  final bool canDryclean;
  final bool canWashAndFold;
  final bool canWashAndIroning;
  final bool canTailoring;
  final bool canStreamIroning;
  final String registrationStatus;
  final List<dynamic> bankDetails;
  final String createdAt;
  final String updatedAt;

  Vendor({
    required this.id,
    required this.name,
    required this.mobile,
    this.cityName = '',
    this.cityId = 0,
    this.stateName = '',
    this.stateId = 0,
    this.pincode = '',
    this.address = '',
    this.accountIsActive = false,
    this.alternativeMobile = '',
    this.email = '',
    this.walletBalance = 0,
    this.gender = '',
    this.dob = '',
    this.profilePic = '',
    this.idProofPic = '',
    this.idProofName = '',
    this.accessToken = '',
    this.orderCapacity = 0,
    this.garmentCapacity = 0,
    this.currentGarmentLoad = 0,
    this.currentLoad = 0,
    this.areaCover = const [],
    this.canPickup = false,
    this.canProcess = false,
    this.canDeliver = false,
    this.canIroning = false,
    this.canDryclean = false,
    this.canWashAndFold = false,
    this.canWashAndIroning = false,
    this.canTailoring = false,
    this.canStreamIroning = false,
    this.registrationStatus = '',
    this.bankDetails = const [],
    this.createdAt = '',
    this.updatedAt = '',
  });

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return false;
  }

  static double _asDouble(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;

  static int _asInt(dynamic v) =>
      (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      cityName: json['cityName']?.toString() ?? '',
      cityId: _asInt(json['cityId']),
      stateName: json['stateName']?.toString() ?? '',
      stateId: _asInt(json['stateId']),
      pincode: json['pincode']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      accountIsActive: _asBool(json['accountIsActive']),
      alternativeMobile: json['alternativeMobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      walletBalance: _asDouble(json['walletBalance']),
      gender: json['gender']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      profilePic: json['profilePic']?.toString() ?? '',
      idProofPic: json['idProofPic']?.toString() ?? '',
      idProofName: json['idProofName']?.toString() ?? '',
      accessToken: json['accessToken']?.toString() ?? '',
      orderCapacity: _asInt(json['orderCapacity']),
      garmentCapacity: _asInt(json['garmentCapacity']),
      currentGarmentLoad: _asInt(json['currentGarmentLoad']),
      currentLoad: _asInt(json['currentLoad']),
      areaCover: List<dynamic>.from(json['areaCover'] ?? const []),
      canPickup: _asBool(json['can_pickup']),
      canProcess: _asBool(json['can_process']),
      canDeliver: _asBool(json['can_deliver']),
      canIroning: _asBool(json['can_ironing']),
      canDryclean: _asBool(json['can_dryclean']),
      canWashAndFold: _asBool(json['can_wash_and_fold']),
      canWashAndIroning: _asBool(json['can_wash_and_ironing']),
      canTailoring: _asBool(json['can_tailoring']),
      canStreamIroning: _asBool(json['can_stream_ironing']),
      registrationStatus: json['registrationStatus']?.toString() ?? '',
      bankDetails: List<dynamic>.from(json['bankDetails'] ?? const []),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'mobile': mobile,
      'cityName': cityName,
      'cityId': cityId,
      'stateName': stateName,
      'stateId': stateId,
      'pincode': pincode,
      'address': address,
      'accountIsActive': accountIsActive,
      'alternativeMobile': alternativeMobile,
      'email': email,
      'walletBalance': walletBalance,
      'gender': gender,
      'dob': dob,
      'profilePic': profilePic,
      'idProofPic': idProofPic,
      'idProofName': idProofName,
      'accessToken': accessToken,
      'orderCapacity': orderCapacity,
      'garmentCapacity': garmentCapacity,
      'currentGarmentLoad': currentGarmentLoad,
      'currentLoad': currentLoad,
      'areaCover': areaCover,
      'can_pickup': canPickup,
      'can_process': canProcess,
      'can_deliver': canDeliver,
      'can_ironing': canIroning,
      'can_dryclean': canDryclean,
      'can_wash_and_fold': canWashAndFold,
      'can_wash_and_ironing': canWashAndIroning,
      'can_tailoring': canTailoring,
      'can_stream_ironing': canStreamIroning,
      'registrationStatus': registrationStatus,
      'bankDetails': bankDetails,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Active service capabilities as human-readable labels, for chips/lists.
  List<String> get activeServices => [
    if (canPickup) 'Pickup',
    if (canProcess) 'Process',
    if (canDeliver) 'Deliver',
    if (canIroning) 'Ironing',
    if (canDryclean) 'Dry Clean',
    if (canWashAndFold) 'Wash & Fold',
    if (canWashAndIroning) 'Wash & Ironing',
    if (canTailoring) 'Tailoring',
    if (canStreamIroning) 'Steam Ironing',
  ];

  VendorModel copyWith({String? accessToken}) {
    return VendorModel.fromJson({
      ...toJson(),
      'accessToken': accessToken ?? this.accessToken,
    });
  }
}
