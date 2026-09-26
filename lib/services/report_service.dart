import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_fight/models/report_model.dart';
import 'package:food_fight/core/constants/firestore_collections.dart';
import 'package:food_fight/core/utils/logger.dart';

/// Report Service for sales analytics & top-selling items
class ReportService {
  static final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  /// Fetch sales analytics for a given date range
  static Future<ReportModel> fetchSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _ordersCollection;

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }

      final snapshot = await query.get();

      double totalRevenue = 0.0;
      int totalOrders = snapshot.docs.length;
      int pendingOrders = 0;
      int deliveredOrders = 0;
      int cancelledOrders = 0;

      final Map<String, Map<String, dynamic>> itemSalesMap = {};
      final Map<String, Map<String, dynamic>> dailyMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        final total = (data['total'] ?? 0).toDouble();
        final createdAtMs = data['createdAt'] as int? ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        if (status == 'pending') {
          pendingOrders++;
        } else if (status == 'delivered') {
          deliveredOrders++;
        } else if (status == 'cancelled') {
          cancelledOrders++;
        }

        // Only include non-cancelled orders in revenue & top items
        if (status != 'cancelled') {
          totalRevenue += total;

          // Daily stats
          if (!dailyMap.containsKey(dateKey)) {
            dailyMap[dateKey] = {'date': DateTime(date.year, date.month, date.day), 'revenue': 0.0, 'count': 0};
          }
          dailyMap[dateKey]!['revenue'] = (dailyMap[dateKey]!['revenue'] as double) + total;
          dailyMap[dateKey]!['count'] = (dailyMap[dateKey]!['count'] as int) + 1;

          // Item sales
          final items = (data['items'] as List?) ?? [];
          for (var itemJson in items) {
            if (itemJson is Map) {
              final food = itemJson['food'] as Map? ?? itemJson;
              final itemId = (food['id'] ?? '').toString();
              final itemName = (food['name'] ?? 'Item').toString();
              final basePrice = (food['price'] ?? 0).toDouble();
              final qty = (itemJson['quantity'] ?? 1) as int;
              final double lineRevenue = itemJson['totalPrice'] != null
                  ? (itemJson['totalPrice'] as num).toDouble()
                  : (itemJson['unitPrice'] != null
                      ? (itemJson['unitPrice'] as num).toDouble() * qty
                      : basePrice * qty);
              final img = food['imageUrl']?.toString();

              if (!itemSalesMap.containsKey(itemId)) {
                itemSalesMap[itemId] = {
                  'id': itemId,
                  'name': itemName,
                  'qty': 0,
                  'revenue': 0.0,
                  'image': img,
                };
              }
              itemSalesMap[itemId]!['qty'] = (itemSalesMap[itemId]!['qty'] as int) + qty;
              itemSalesMap[itemId]!['revenue'] = (itemSalesMap[itemId]!['revenue'] as double) + lineRevenue;
            }
          }
        }
      }

      // Convert items map to sorted list
      final topItemsList = itemSalesMap.values.map((v) {
        return TopSellingItem(
          menuItemId: v['id'] as String,
          name: v['name'] as String,
          quantitySold: v['qty'] as int,
          totalRevenue: v['revenue'] as double,
          imageUrl: v['image'] as String?,
        );
      }).toList();
      topItemsList.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

      // Convert daily map to sorted list
      final dailySalesList = dailyMap.values.map((v) {
        return DailySalesStat(
          date: v['date'] as DateTime,
          revenue: v['revenue'] as double,
          ordersCount: v['count'] as int,
        );
      }).toList();
      dailySalesList.sort((a, b) => b.date.compareTo(a.date));

      final avgOrder = totalOrders > 0 ? (totalRevenue / (totalOrders - cancelledOrders > 0 ? totalOrders - cancelledOrders : 1)) : 0.0;

      return ReportModel(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        deliveredOrders: deliveredOrders,
        cancelledOrders: cancelledOrders,
        averageOrderValue: avgOrder,
        topSellingItems: topItemsList,
        dailySales: dailySalesList,
      );
    } catch (e) {
      AppLogger.error('Error fetching sales report: $e', tag: 'ReportService');
      return ReportModel.empty();
    }
  }
}
