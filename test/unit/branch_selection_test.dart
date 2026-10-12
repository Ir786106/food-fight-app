import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/models/branch_model.dart';
import 'package:food_fight/services/branch_service.dart';

void main() {
  group('Branch Selection & Haversine Distance Tests', () {
    final branches = BranchService.getDefaultBranches();

    test('All seeded branches have valid GPS coordinates and delivery radii', () {
      expect(branches.length, 5);
      for (final b in branches) {
        expect(b.latitude, isNotNull);
        expect(b.longitude, isNotNull);
        expect(b.deliveryRadiusKm, isNotNull);
        expect(b.deliveryRadiusKm > 0, isTrue);
      }
    });

    test('Calculates accurate Haversine distance between points', () {
      final dhaBranch = branches.firstWhere((b) => b.id == 'branch-dha-lhr');
      
      // Point ~2.5 km away from DHA Lahore branch (e.g. 31.4850, 74.3950)
      final distance = dhaBranch.distanceToKm(31.4850, 74.3950);
      expect(distance, greaterThan(1.0));
      expect(distance, lessThan(4.0));
    });

    test('Detects customer is within delivery radius', () {
      final dhaBranch = branches.firstWhere((b) => b.id == 'branch-dha-lhr');
      
      // Point within 5 km of DHA branch
      final isInside = dhaBranch.isWithinDeliveryRadius(31.4850, 74.3950);
      expect(isInside, isTrue);
    });

    test('Detects customer in Arifwala is out of radius from Lahore branches', () {
      final dhaBranch = branches.firstWhere((b) => b.id == 'branch-dha-lhr');
      final gulbergBranch = branches.firstWhere((b) => b.id == 'branch-gulberg-lhr');
      
      // Arifwala coordinates: ~30.5333 N, 73.0667 E
      const arifwalaLat = 30.5333;
      const arifwalaLng = 73.0667;

      final distDha = dhaBranch.distanceToKm(arifwalaLat, arifwalaLng);
      final distGulberg = gulbergBranch.distanceToKm(arifwalaLat, arifwalaLng);

      // Arifwala is ~160-200 km from Lahore
      expect(distDha, greaterThan(120.0));
      expect(distGulberg, greaterThan(120.0));

      // Neither Lahore branch delivers to Arifwala!
      expect(dhaBranch.isWithinDeliveryRadius(arifwalaLat, arifwalaLng), isFalse);
      expect(gulbergBranch.isWithinDeliveryRadius(arifwalaLat, arifwalaLng), isFalse);
    });

    test('Nearest active branch resolution among multiple branches', () {
      // Customer in Islamabad F-7 sector: ~33.7200, 73.0550
      const isbLat = 33.7200;
      const isbLng = 73.0550;

      final sorted = List<BranchModel>.from(branches)
        ..sort((a, b) => a.distanceToKm(isbLat, isbLng).compareTo(b.distanceToKm(isbLat, isbLng)));

      final nearest = sorted.first;
      expect(nearest.id, 'branch-f7-isb');
      expect(nearest.isWithinDeliveryRadius(isbLat, isbLng), isTrue);
    });

    test('Branch fallback routes to next open branch when nearest is closed', () {
      final testBranches = [
        BranchModel(
          id: 'branch-closed',
          name: 'Closed Kitchen',
          address: 'Main Blvd',
          city: 'Lahore',
          phone: '042000',
          latitude: 31.4700,
          longitude: 74.4000,
          deliveryRadiusKm: 15.0,
          status: 'closed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BranchModel(
          id: 'branch-open',
          name: 'Open Kitchen',
          address: 'Gulberg',
          city: 'Lahore',
          phone: '042111',
          latitude: 31.5100,
          longitude: 74.3400,
          deliveryRadiusKm: 15.0,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Customer nearest to closed branch
      const customerLat = 31.4710;
      const customerLng = 74.4010;

      final closedDist = testBranches.first.distanceToKm(customerLat, customerLng);
      final openDist = testBranches[1].distanceToKm(customerLat, customerLng);
      expect(closedDist, lessThan(openDist));

      final nearestClosed = testBranches.first;
      expect(nearestClosed.isActive, isFalse);

      // Fallback open branch
      final nextOpen = testBranches.where((b) => b.isActive).firstOrNull;
      expect(nextOpen, isNotNull);
      expect(nextOpen!.id, 'branch-open');
    });
  });
}
