import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vender_app/api/onboarding_api.dart';
import 'package:vender_app/models/service_model.dart';
import 'package:vender_app/models/vendor_model.dart';

class OnboardingProvider with ChangeNotifier {
  final OnboardingApi _api = OnboardingApi();

  bool _isLoading = false;
  String? _errorMessage;

  // ── Step 1: KYC personal details ─────────────────────────────────────────
  String gender = '';
  String dob = '';
  String idProofType = '';
  String idProofNumber = '';
  String email = '';
  String alternativeMobile = '';

  // ── Step 2: Document photos ───────────────────────────────────────────────
  File? profilePic;
  File? idProofPic;

  // ── Step 3: Selected services ─────────────────────────────────────────────
  List<ServiceModel> availableServices = [];
  // service_id → selected true/false
  Map<int, bool> serviceSelection = {};

  // ── Step 4: Pricing ───────────────────────────────────────────────────────
  // key: "serviceId_categoryId" → price string entered by vendor
  Map<String, String> priceInputs = {};
  // existing prices from backend (after load): key same as above → price map
  Map<String, Map<String, dynamic>> existingPrices = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ServiceModel> get selectedServices =>
      availableServices.where((s) => serviceSelection[s.serviceId] == true).toList();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Pre-fill form fields from the vendor's existing profile (used when
  // re-editing KYC after rejection so the form comes up pre-populated).
  void preloadFromVendor(Vendor vendor) {
    gender = vendor.gender;
    dob = vendor.dob;
    idProofType = vendor.idProofType;
    idProofNumber = vendor.idProofName;
    email = vendor.email;
    alternativeMobile = vendor.alternativeMobile;
    // Leave profilePic / idProofPic null — vendor can optionally re-upload.
    notifyListeners();
  }

  // ── Load services from backend ────────────────────────────────────────────

  Future<bool> loadServices(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final services = await _api.getServiceList(token);
      availableServices = services;

      // Preserve existing selections if already set
      for (final s in services) {
        serviceSelection.putIfAbsent(s.serviceId, () => false);
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load full category list for selected services (needed for pricing step)
  Future<bool> loadCategoriesForSelected(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updated = <ServiceModel>[];
      for (final s in availableServices) {
        if (serviceSelection[s.serviceId] == true) {
          final full = await _api.getServiceWithCategories(token, s.serviceId);
          updated.add(full);
        }
      }
      // Replace selected services with full category data
      for (final full in updated) {
        final idx = availableServices.indexWhere((s) => s.serviceId == full.serviceId);
        if (idx != -1) availableServices[idx] = full;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load existing prices from backend so vendor can update them
  Future<void> loadExistingPrices(String token) async {
    try {
      final prices = await _api.getMyPrices(token);
      existingPrices = {};
      for (final p in prices) {
        final key = '${p['service_id']}_${p['category_id']}';
        existingPrices[key] = p;
        // Pre-fill price input with existing value
        priceInputs.putIfAbsent(key, () => p['price'].toString());
      }
      notifyListeners();
    } catch (_) {}
  }

  void toggleService(int serviceId) {
    serviceSelection[serviceId] = !(serviceSelection[serviceId] ?? false);
    notifyListeners();
  }

  void setPriceInput(int serviceId, int categoryId, String value) {
    priceInputs['${serviceId}_$categoryId'] = value;
  }

  String getPriceInput(int serviceId, int categoryId) =>
      priceInputs['${serviceId}_$categoryId'] ?? '';

  // ── KYC submit (initial — both photos required) ───────────────────────────

  Future<bool> submitKyc(String token) async {
    if (profilePic == null || idProofPic == null) {
      _errorMessage = 'Please upload both profile photo and ID proof photo.';
      notifyListeners();
      return false;
    }
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _api.submitKyc(
        token: token,
        gender: gender,
        dob: dob,
        idProofType: idProofType,
        idProofNumber: idProofNumber,
        email: email,
        alternativeMobile: alternativeMobile,
        profilePic: profilePic!,
        idProofPic: idProofPic!,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── KYC update (re-edit after rejection — photos optional) ────────────────

  Future<bool> updateKyc(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _api.updateKyc(
        token: token,
        gender: gender,
        dob: dob,
        idProofType: idProofType,
        idProofNumber: idProofNumber,
        email: email,
        alternativeMobile: alternativeMobile,
        profilePic: profilePic,   // null = keep existing on server
        idProofPic: idProofPic,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 2 submit: service selection ─────────────────────────────────────

  Future<bool> submitServiceSelection(String token) async {
    final selected = availableServices
        .where((s) => serviceSelection[s.serviceId] == true)
        .map((s) => SelectedService(serviceId: s.serviceId, service: s.service))
        .toList();

    if (selected.isEmpty) {
      _errorMessage = 'Please select at least one service.';
      notifyListeners();
      return false;
    }
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _api.selectServices(token, selected);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 3 submit: all prices ─────────────────────────────────────────────

  Future<bool> submitAllPrices(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      for (final service in selectedServices) {
        for (final cat in service.categoryList) {
          final key = '${service.serviceId}_${cat.categoryId}';
          final input = priceInputs[key] ?? '';
          final price = double.tryParse(input);
          if (price == null || price <= 0) continue;

          final existing = existingPrices[key];
          if (existing != null) {
            // Update if price changed
            if (existing['price'].toString() != input) {
              await _api.updatePrice(
                token: token,
                priceId: existing['_id'].toString(),
                price: price,
              );
            }
          } else {
            await _api.addPrice(
              token: token,
              serviceId: service.serviceId,
              categoryId: cat.categoryId,
              price: price,
            );
          }
        }
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Final submit ──────────────────────────────────────────────────────────

  Future<bool> finalSubmit(String token) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _api.submitOnboarding(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
