/// Interface for report service
abstract class IReportService {
  /// Get daily sales report
  Future<DailySalesReport> getDailySalesReport(String restaurantId, DateTime date);

  /// Get weekly sales report
  Future<WeeklySalesReport> getWeeklySalesReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Get monthly sales report
  Future<MonthlySalesReport> getMonthlySalesReport(String restaurantId, int year, int month);

  /// Get custom date range report
  Future<CustomDateRangeReport> getCustomDateRangeReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Get order summary report
  Future<OrderSummaryReport> getOrderSummaryReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Get product report
  Future<ProductReport> getProductReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Get customer report
  Future<CustomerReport> getCustomerReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Get rider report
  Future<RiderReport> getRiderReport(String restaurantId, DateTime startDate, DateTime endDate);

  /// Export report as CSV
  Future<String> exportReportToCsv(String reportType, DateTime startDate, DateTime endDate);
}

/// Daily sales report
class DailySalesReport {
  final DateTime date;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSales;
  final double averageOrderValue;

  DailySalesReport({
    required this.date,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.averageOrderValue,
  });
}

/// Weekly sales report
class WeeklySalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<DailySalesReport> dailyReports;
  final int totalOrders;
  final double totalSales;

  WeeklySalesReport({
    required this.startDate,
    required this.endDate,
    required this.dailyReports,
    required this.totalOrders,
    required this.totalSales,
  });
}

/// Monthly sales report
class MonthlySalesReport {
  final int year;
  final int month;
  final List<DailySalesReport> dailyReports;
  final int totalOrders;
  final double totalSales;

  MonthlySalesReport({
    required this.year,
    required this.month,
    required this.dailyReports,
    required this.totalOrders,
    required this.totalSales,
  });
}

/// Custom date range report
class CustomDateRangeReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSales;
  final double averageOrderValue;

  CustomDateRangeReport({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSales,
    required this.averageOrderValue,
  });
}

/// Order summary report
class OrderSummaryReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final int pendingOrders;
  final int acceptedOrders;
  final int preparingOrders;
  final int readyOrders;
  final int outForDeliveryOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double averageOrderValue;

  OrderSummaryReport({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.pendingOrders,
    required this.acceptedOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.outForDeliveryOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
  });
}

/// Product report
class ProductReport {
  final DateTime startDate;
  final DateTime endDate;
  final List<ProductSales> topProducts;
  final List<ProductSales> bottomProducts;
  final List<CategorySales> categorySales;

  ProductReport({
    required this.startDate,
    required this.endDate,
    required this.topProducts,
    required this.bottomProducts,
    required this.categorySales,
  });
}

/// Product sales data
class ProductSales {
  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });
}

/// Category sales data
class CategorySales {
  final String categoryId;
  final String categoryName;
  final int totalOrders;
  final double totalRevenue;

  CategorySales({
    required this.categoryId,
    required this.categoryName,
    required this.totalOrders,
    required this.totalRevenue,
  });
}

/// Customer report
class CustomerReport {
  final DateTime startDate;
  final DateTime endDate;
  final int newCustomers;
  final int returningCustomers;
  final int totalCustomers;
  final double averageSpent;
  final List<CustomerStats> topCustomers;

  CustomerReport({
    required this.startDate,
    required this.endDate,
    required this.newCustomers,
    required this.returningCustomers,
    required this.totalCustomers,
    required this.averageSpent,
    required this.topCustomers,
  });
}

/// Customer statistics
class CustomerStats {
  final String userId;
  final String userName;
  final int totalOrders;
  final double totalSpent;

  CustomerStats({
    required this.userId,
    required this.userName,
    required this.totalOrders,
    required this.totalSpent,
  });
}

/// Rider report
class RiderReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalRiders;
  final int activeRiders;
  final List<RiderStats> riderStats;
  final int totalDeliveries;
  final double totalEarnings;

  RiderReport({
    required this.startDate,
    required this.endDate,
    required this.totalRiders,
    required this.activeRiders,
    required this.riderStats,
    required this.totalDeliveries,
    required this.totalEarnings,
  });
}

/// Rider statistics
class RiderStats {
  final String riderId;
  final String riderName;
  final int totalDeliveries;
  final double totalEarnings;
  final double averageRating;

  RiderStats({
    required this.riderId,
    required this.riderName,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.averageRating,
  });
}
