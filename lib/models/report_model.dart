/// Report Model for Sales and Business Analytics
class ReportModel {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final List<TopSellingItem> topSellingItems;
  final List<DailySalesStat> dailySales;

  ReportModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.topSellingItems,
    required this.dailySales,
  });

  factory ReportModel.empty() {
    return ReportModel(
      totalRevenue: 0.0,
      totalOrders: 0,
      pendingOrders: 0,
      deliveredOrders: 0,
      cancelledOrders: 0,
      averageOrderValue: 0.0,
      topSellingItems: [],
      dailySales: [],
    );
  }
}

class TopSellingItem {
  final String menuItemId;
  final String name;
  final int quantitySold;
  final double totalRevenue;
  final String? imageUrl;

  TopSellingItem({
    required this.menuItemId,
    required this.name,
    required this.quantitySold,
    required this.totalRevenue,
    this.imageUrl,
  });
}

class DailySalesStat {
  final DateTime date;
  final double revenue;
  final int ordersCount;

  DailySalesStat({
    required this.date,
    required this.revenue,
    required this.ordersCount,
  });
}
