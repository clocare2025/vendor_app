class OrderItem {
  final String name;
  final int quantity;
  final double vendorPrice;
  final double total;
  final List<String> typesOfClothes;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.vendorPrice,
    required this.total,
    this.typesOfClothes = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final price = (json['vendor_price'] as num?)?.toDouble() ?? 0.0;
    return OrderItem(
      name: json['name']?.toString() ?? '',
      quantity: qty,
      vendorPrice: price,
      total: (json['total'] as num?)?.toDouble() ?? price * qty,
      typesOfClothes: List<String>.from(json['types_of_clothes'] as List? ?? []),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String serviceName;
  final String category;

  // ── Status ──────────────────────────────────────────────────────────────────
  // Values: assigned | accepted | picked_up | processing | completed | rejected
  final String status;

  // ── Amounts ─────────────────────────────────────────────────────────────────
  final double vendorAmount;

  // ── Customer ─────────────────────────────────────────────────────────────────
  final String customerName;
  final String customerPhone;
  final String customerAddress;

  // ── Timeline ─────────────────────────────────────────────────────────────────
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;           // timer starts here
  final DateTime? processingStartedAt;
  final DateTime? processingCompletedAt;
  final DateTime? serviceDeadline;      // pickedUpAt + serviceDurationHours
  final int serviceDurationHours;

  // ── Booking slot (customer's requested time) ─────────────────────────────────
  final DateTime? pickupAt;
  final String pickupTimeSlot;
  final String serviceDuration;

  // ── Items ─────────────────────────────────────────────────────────────────────
  final List<OrderItem> items;
  final String? rejectReason;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.serviceName,
    this.category = '',
    required this.status,
    required this.vendorAmount,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.processingStartedAt,
    this.processingCompletedAt,
    this.serviceDeadline,
    this.serviceDurationHours = 0,
    this.pickupAt,
    this.pickupTimeSlot = '',
    this.serviceDuration = '',
    this.items = const [],
    this.rejectReason,
  });

  // ── Status helpers ──────────────────────────────────────────────────────────
  bool get isAssigned => status == 'assigned';
  bool get isAccepted => status == 'accepted';
  bool get isPickedUp => status == 'picked_up';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  bool get canAccept => isAssigned;
  bool get canReject => isAssigned;
  bool get canPickup => isAccepted;
  bool get canStartProcessing => isPickedUp;
  bool get canComplete => isPickedUp || isProcessing;

  // Home screen helpers
  bool get isPending => isAssigned;
  bool get isActive => isAccepted || isPickedUp || isProcessing;

  // Timer helpers
  bool get timerRunning => isPickedUp || isProcessing;
  Duration? get remainingTime {
    if (serviceDeadline == null) return null;
    return serviceDeadline!.difference(DateTime.now());
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    return OrderModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: json['order_number']?.toString() ?? '',
      serviceName: json['service']?.toString() ?? json['service_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? 'assigned',
      vendorAmount: (json['vendor_amount'] as num?)?.toDouble() ?? 0.0,
      customerName: customer['name']?.toString() ?? json['customer_name']?.toString() ?? '',
      customerPhone: customer['phone']?.toString() ?? json['customer_phone']?.toString() ?? '',
      customerAddress: customer['address']?.toString() ?? json['customer_address']?.toString() ?? '',
      assignedAt: (DateTime.tryParse(json['assigned_at']?.toString() ?? '') ?? DateTime.now()).toLocal(),
      acceptedAt: _parseDate(json['accepted_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      processingStartedAt: _parseDate(json['processing_started_at']),
      processingCompletedAt: _parseDate(json['processing_completed_at']),
      serviceDeadline: _parseDate(json['service_deadline']),
      serviceDurationHours: (json['service_duration_hours'] as num?)?.toInt() ?? 0,
      pickupAt: _parseDate(json['pickup_at']),
      pickupTimeSlot: json['pickup_time']?.toString() ?? '',
      serviceDuration: json['service_duration']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      rejectReason: json['reject_reason']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    // Convert UTC from API to device local time (IST for India)
    return DateTime.tryParse(val.toString())?.toLocal();
  }

  OrderModel copyWith({String? status, String? rejectReason,
      DateTime? pickedUpAt, DateTime? serviceDeadline,
      DateTime? processingStartedAt, DateTime? processingCompletedAt}) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      serviceName: serviceName,
      category: category,
      status: status ?? this.status,
      vendorAmount: vendorAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      assignedAt: assignedAt,
      acceptedAt: acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      processingStartedAt: processingStartedAt ?? this.processingStartedAt,
      processingCompletedAt: processingCompletedAt ?? this.processingCompletedAt,
      serviceDeadline: serviceDeadline ?? this.serviceDeadline,
      serviceDurationHours: serviceDurationHours,
      pickupAt: pickupAt,
      pickupTimeSlot: pickupTimeSlot,
      serviceDuration: serviceDuration,
      items: items,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
