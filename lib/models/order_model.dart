enum OrderStatus { pending, active, completed, cancelled }

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String serviceName;
  final double amount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? pickupTime;
  final DateTime? deliveryTime;
  final List<String> items;
  final String? notes;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.pickupTime,
    this.deliveryTime,
    this.items = const [],
    this.notes,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      serviceName: json['service_name'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: _statusFromString(json['status'] ?? 'pending'),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      pickupTime: json['pickup_time'] != null ? DateTime.tryParse(json['pickup_time']) : null,
      deliveryTime: json['delivery_time'] != null ? DateTime.tryParse(json['delivery_time']) : null,
      items: List<String>.from(json['items'] ?? []),
      notes: json['notes'],
    );
  }

  static OrderStatus _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return OrderStatus.active;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  OrderModel copyWith({OrderStatus? status}) {
    return OrderModel(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      serviceName: serviceName,
      amount: amount,
      status: status ?? this.status,
      createdAt: createdAt,
      pickupTime: pickupTime,
      deliveryTime: deliveryTime,
      items: items,
      notes: notes,
    );
  }
}
