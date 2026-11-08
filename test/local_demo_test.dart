import 'package:flutter_test/flutter_test.dart';
import 'package:food_fight/core/config/local_demo.dart';

void main() {
  test('local demo uses a loopback host and isolated Firebase project', () {
    expect(LocalDemo.host, '127.0.0.1');
    expect(LocalDemo.options.projectId, 'demo-food-fight');
    expect(LocalDemo.options.storageBucket, 'demo-food-fight.appspot.com');
  });

  test('local demo fails before Firebase initialization on native platforms', () async {
    await expectLater(LocalDemo.connect(), throwsStateError);
  });
}
