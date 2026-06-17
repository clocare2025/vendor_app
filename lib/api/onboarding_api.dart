import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:vender_app/core/constants/api_constants.dart';
import 'package:vender_app/models/service_model.dart';
import 'package:vender_app/models/vendor_model.dart';

class OnboardingApi {
  // ── Onboarding status ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getOnboardingStatus(String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.onboardingStatus),
      headers: _authHeaders(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['msg'] ?? 'Failed to fetch onboarding status');
  }

  // ── KYC submit (multipart) ─────────────────────────────────────────────────

  Future<void> submitKyc({
    required String token,
    required String gender,
    required String dob,
    required String idProofType,
    required String idProofNumber,
    String? email,
    String? alternativeMobile,
    required File profilePic,
    required File idProofPic,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.kycSubmit),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['gender'] = gender;
    request.fields['dob'] = dob;
    request.fields['idProofType'] = idProofType;
    request.fields['idProofNumber'] = idProofNumber;
    if (email != null && email.isNotEmpty) request.fields['email'] = email;
    if (alternativeMobile != null && alternativeMobile.isNotEmpty) {
      request.fields['alternativeMobile'] = alternativeMobile;
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        'profilePic',
        profilePic.path,
        contentType: _imageContentType(profilePic.path),
      ),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'idProofPic',
        idProofPic.path,
        contentType: _imageContentType(idProofPic.path),
      ),
    );

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['msg'] ?? 'KYC submission failed');
    }
  }

  // Derive the image content-type from the file extension so the server's
  // multer fileFilter accepts it (Flutter defaults to application/octet-stream).
  MediaType _imageContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // ── Service list (for selection screen) ──────────────────────────────────

  Future<List<ServiceModel>> getServiceList(String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.serviceList),
      headers: _authHeaders(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      final list = body['data']['service'] as List<dynamic>;
      return list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(body['msg'] ?? 'Failed to load services');
  }

  // ── Service category list (with types_of_Clothes) ────────────────────────

  Future<ServiceModel> getServiceWithCategories(
    String token,
    int serviceId,
  ) async {
    final res = await http.get(
      Uri.parse(ApiConstants.serviceCategories(serviceId.toString())),
      headers: _authHeaders(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      final d = body['data'] as Map<String, dynamic>;
      return ServiceModel(
        serviceId: (d['service_id'] as num).toInt(),
        service: d['service'].toString(),
        serviceDurationHours: 0,
        duration: '',
        description: '',
        categoryList: (d['category_list'] as List<dynamic>)
            .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    throw Exception(body['msg'] ?? 'Failed to load categories');
  }

  // ── Select services ────────────────────────────────────────────────────────

  Future<void> selectServices(
    String token,
    List<SelectedService> services,
  ) async {
    final res = await http.post(
      Uri.parse(ApiConstants.onboardingServicesSelect),
      headers: _jsonHeaders(token),
      body: jsonEncode({'services': services.map((s) => s.toJson()).toList()}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['msg'] ?? 'Failed to save services');
    }
  }

  // ── Prices ────────────────────────────────────────────────────────────────

  Future<void> addPrice({
    required String token,
    required int serviceId,
    required int categoryId,
    required double price,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.priceList),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'service_id': serviceId,
        'category_id': categoryId,
        'price': price,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['msg'] ?? 'Failed to save price');
    }
  }

  Future<List<Map<String, dynamic>>> getMyPrices(String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.priceList),
      headers: _authHeaders(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && body['status'] == true) {
      return List<Map<String, dynamic>>.from(body['data']['prices']);
    }
    throw Exception(body['msg'] ?? 'Failed to load prices');
  }

  Future<void> updatePrice({
    required String token,
    required String priceId,
    required double price,
  }) async {
    final res = await http.put(
      Uri.parse(ApiConstants.priceDetail(priceId)),
      headers: _jsonHeaders(token),
      body: jsonEncode({'price': price}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['msg'] ?? 'Failed to update price');
    }
  }

  // ── Final submit ──────────────────────────────────────────────────────────

  Future<void> submitOnboarding(String token) async {
    final res = await http.post(
      Uri.parse(ApiConstants.onboardingSubmit),
      headers: _jsonHeaders(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['status'] != true) {
      throw Exception(body['msg'] ?? 'Submission failed');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
  };

  Map<String, String> _jsonHeaders(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}
