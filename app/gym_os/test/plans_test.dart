import 'package:flutter_test/flutter_test.dart';
import 'package:gym_os/features/plans/models/plan_model.dart';

void main() {
  group('PlanModel tests', () {
    test('fromJson and toJson work correctly', () {
      final json = {
        'id': 'plan-123',
        'name': 'اشتراك شهري',
        'description': 'دخول مفتوح لجميع الأجهزة',
        'price': 450.0,
        'durationInDays': 30,
        'isActive': true,
        'maxSessions': null,
      };

      final plan = PlanModel.fromJson(json);

      expect(plan.id, 'plan-123');
      expect(plan.name, 'اشتراك شهري');
      expect(plan.description, 'دخول مفتوح لجميع الأجهزة');
      expect(plan.price, 450.0);
      expect(plan.durationInDays, 30);
      expect(plan.isActive, true);
      expect(plan.maxSessions, isNull);

      final exported = plan.toJson();
      expect(exported['id'], 'plan-123');
      expect(exported['name'], 'اشتراك شهري');
      expect(exported['price'], 450.0);
      expect(exported['durationInDays'], 30);
      expect(exported['isActive'], true);
    });

    test('copyWith updates specified fields only', () {
      const plan = PlanModel(
        id: '1',
        name: '3 Months',
        price: 1200,
        durationInDays: 90,
        isActive: true,
      );

      final updated = plan.copyWith(isActive: false, price: 1300);

      expect(updated.id, '1');
      expect(updated.name, '3 Months');
      expect(updated.price, 1300);
      expect(updated.durationInDays, 90);
      expect(updated.isActive, false);
    });
  });
}
