import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../models/option_template_model.dart';

class OptionTemplateService {
  final FirebaseFirestore? _customFirestore;
  OptionTemplateService({FirebaseFirestore? firestore}) : _customFirestore = firestore;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  final String _collection = 'optionTemplates';

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection(_collection);

  /// Stream templates available to a branch (including global templates)
  Stream<List<OptionTemplateModel>> streamTemplates({String? branchId}) {
    Query<Map<String, dynamic>> query = _templatesRef.where('isActive', isEqualTo: true);

    if (branchId != null && branchId.isNotEmpty && branchId != 'all') {
      query = query.where('branchId', whereIn: [branchId, null, '', 'all']);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OptionTemplateModel.fromJson(data);
      }).toList();
    });
  }

  /// Create a template
  Future<String> createTemplate(OptionTemplateModel template) async {
    try {
      final docRef = template.id.isNotEmpty ? _templatesRef.doc(template.id) : _templatesRef.doc();
      final data = template.copyWith(id: docRef.id).toJson();
      await docRef.set(data);
      AppLogger.info('Option template created: ${docRef.id}', tag: 'OptionTemplateService');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating option template: $e', tag: 'OptionTemplateService');
      rethrow;
    }
  }

  /// Update a template
  Future<void> updateTemplate(OptionTemplateModel template) async {
    try {
      await _templatesRef.doc(template.id).update(template.toJson());
      AppLogger.info('Option template updated: ${template.id}', tag: 'OptionTemplateService');
    } catch (e) {
      AppLogger.error('Error updating option template: $e', tag: 'OptionTemplateService');
      rethrow;
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _templatesRef.doc(templateId).delete();
      AppLogger.info('Option template deleted: $templateId', tag: 'OptionTemplateService');
    } catch (e) {
      AppLogger.error('Error deleting option template: $e', tag: 'OptionTemplateService');
      rethrow;
    }
  }

  /// Seed initial standard templates if Firestore has 0 templates
  Future<void> seedDefaultTemplatesIfEmpty() async {
    try {
      final snapshot = await _templatesRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final now = DateTime.now();

      // Standard 4 sizes set
      await createTemplate(OptionTemplateModel(
        id: 'template_size_4',
        name: '4 Sizes (S, M, L, XL)',
        type: 'size_set',
        isRequired: true,
        minSelections: 1,
        maxSelections: 1,
        items: const [
          OptionTemplateItem(id: 's', name: 'Small', price: 0, isDefault: true),
          OptionTemplateItem(id: 'm', name: 'Medium', price: 400),
          OptionTemplateItem(id: 'l', name: 'Large', price: 800),
          OptionTemplateItem(id: 'xl', name: 'Extra Large', price: 1200),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      // Standard 3 sizes set
      await createTemplate(OptionTemplateModel(
        id: 'template_size_3',
        name: '3 Sizes (M, L, XL)',
        type: 'size_set',
        isRequired: true,
        minSelections: 1,
        maxSelections: 1,
        items: const [
          OptionTemplateItem(id: 'm', name: 'Medium', price: 0, isDefault: true),
          OptionTemplateItem(id: 'l', name: 'Large', price: 400),
          OptionTemplateItem(id: 'xl', name: 'Extra Large', price: 800),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      // Extra Toppings group
      await createTemplate(OptionTemplateModel(
        id: 'template_extras_toppings',
        name: 'Extra Toppings',
        type: 'extras_group',
        isRequired: false,
        minSelections: 0,
        maxSelections: 5,
        items: const [
          OptionTemplateItem(id: 'cheese', name: 'Extra Mozzarella Cheese', price: 150),
          OptionTemplateItem(id: 'chicken', name: 'Extra Smoked Chicken', price: 180),
          OptionTemplateItem(id: 'olives', name: 'Black Olives & Jalapenos', price: 80),
          OptionTemplateItem(id: 'mushrooms', name: 'Fresh Mushrooms', price: 100),
          OptionTemplateItem(id: 'onion_pepper', name: 'Crunchy Capsicum & Onion', price: 60),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      // Extra Dip Sauces group
      await createTemplate(OptionTemplateModel(
        id: 'template_extras_dips',
        name: 'Extra Dip Sauces',
        type: 'extras_group',
        isRequired: false,
        minSelections: 0,
        maxSelections: 4,
        items: const [
          OptionTemplateItem(id: 'garlic_mayo', name: 'Garlic Mayo Dip', price: 70),
          OptionTemplateItem(id: 'chipotle', name: 'Smoky Chipotle Sauce', price: 80),
          OptionTemplateItem(id: 'honey_mustard', name: 'Honey Mustard Dip', price: 80),
          OptionTemplateItem(id: 'ranch', name: 'Creamy Ranch Dip', price: 90),
        ],
        createdAt: now,
        updatedAt: now,
      ));

      AppLogger.info('Default option templates seeded successfully', tag: 'OptionTemplateService');
    } catch (e) {
      AppLogger.error('Error seeding default templates: $e', tag: 'OptionTemplateService');
    }
  }
}
