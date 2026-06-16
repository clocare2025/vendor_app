import '../models/order_model.dart';

/// Supplies order data to [OrderProvider].
///
/// Currently backed by mock data because the backend doesn't expose an
/// orders endpoint yet. Once `/api/vendor/v1/orders` exists, replace the
/// bodies below with real HTTP calls (see [AuthApi] for the pattern) —
/// the provider and the rest of the app won't need to change.
class OrdersService {
  Future<List<OrderModel>> fetchOrders() async {
    // TODO: Replace with actual API call to your backend.
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockOrders();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // TODO: Replace with actual API call to your backend.
  }

  List<OrderModel> _mockOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'ORD1001',
        customerName: 'Aarav Sharma',
        customerPhone: '+91 98765 43210',
        customerAddress: '12, Green Park, New Delhi',
        serviceName: 'Wash & Fold',
        amount: 450,
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 30)),
        items: const ['Shirts (5)', 'Trousers (3)'],
      ),
      OrderModel(
        id: 'ORD1002',
        customerName: 'Priya Verma',
        customerPhone: '+91 98123 45678',
        customerAddress: '45, MG Road, Pune',
        serviceName: 'Dry Cleaning',
        amount: 850,
        status: OrderStatus.active,
        createdAt: now.subtract(const Duration(hours: 2)),
        pickupTime: now.subtract(const Duration(hours: 1)),
        items: const ['Suit (1)', 'Saree (2)'],
      ),
      OrderModel(
        id: 'ORD1003',
        customerName: 'Rohan Gupta',
        customerPhone: '+91 99887 76655',
        customerAddress: '7, Marine Drive, Mumbai',
        serviceName: 'Ironing',
        amount: 200,
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
        deliveryTime: now.subtract(const Duration(hours: 5)),
        items: const ['Shirts (8)'],
      ),
      OrderModel(
        id: 'ORD1004',
        customerName: 'Sneha Iyer',
        customerPhone: '+91 90909 08080',
        customerAddress: '23, Anna Nagar, Chennai',
        serviceName: 'Wash & Fold',
        amount: 600,
        status: OrderStatus.active,
        createdAt: now.subtract(const Duration(hours: 4)),
        items: const ['Bedsheets (2)', 'Towels (4)'],
      ),
      OrderModel(
        id: 'ORD1005',
        customerName: 'Vikram Singh',
        customerPhone: '+91 91234 56789',
        customerAddress: '88, Sector 17, Chandigarh',
        serviceName: 'Dry Cleaning',
        amount: 1200,
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        deliveryTime: now.subtract(const Duration(days: 1)),
        items: const ['Jackets (2)', 'Coats (1)'],
      ),
      OrderModel(
        id: 'ORD1006',
        customerName: 'Anita Desai',
        customerPhone: '+91 95555 12345',
        customerAddress: '5, Koramangala, Bangalore',
        serviceName: 'Wash & Fold',
        amount: 350,
        status: OrderStatus.cancelled,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        items: const ['Shirts (4)'],
      ),
      OrderModel(
        id: 'ORD1007',
        customerName: 'Karan Mehta',
        customerPhone: '+91 97777 88990',
        customerAddress: '15, Banjara Hills, Hyderabad',
        serviceName: 'Ironing',
        amount: 150,
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 10)),
        items: const ['Shirts (3)', 'Trousers (2)'],
      ),
    ];
  }
}
