class OtpModel {
  bool? status;
  String? msg;
  Data? data;

  OtpModel({this.status, this.msg, this.data});

  OtpModel.fromJson(Map<String, dynamic> json) {
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
  OtpData? otpData;

  Data({this.otpData});

  Data.fromJson(Map<String, dynamic> json) {
    otpData = json['otpData'] != null
        ? new OtpData.fromJson(json['otpData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.otpData != null) {
      data['otpData'] = this.otpData!.toJson();
    }
    return data;
  }
}

class OtpData {
  String? mobileNo;
  String? otpCode;
  String? otpRequest;
  bool? isVerified;
  String? sId;
  String? createdAt;
  String? updatedAt;

  OtpData({
    this.mobileNo,
    this.otpCode,
    this.otpRequest,
    this.isVerified,
    this.sId,
    this.createdAt,
    this.updatedAt,
  });

  OtpData.fromJson(Map<String, dynamic> json) {
    mobileNo = json['mobile_no'];
    otpCode = json['otp_code'];
    otpRequest = json['otp_request'];
    isVerified = json['is_verified'];
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mobile_no'] = this.mobileNo;
    data['otp_code'] = this.otpCode;
    data['otp_request'] = this.otpRequest;
    data['is_verified'] = this.isVerified;
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
