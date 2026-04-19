import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helpers.dart';

enum ItemFormat {
  cartridge('cartridge', 'Cartridge'),
  pcb('pcb', 'PCB'),
  cd('cd', 'CD'),
  conversion('conversion', 'Conversion');

  final String value;
  final String label;
  const ItemFormat(this.value, this.label);

  static ItemFormat fromValue(String value) {
    return ItemFormat.values.firstWhere(
      (f) => f.value == value,
      orElse: () => ItemFormat.cartridge,
    );
  }
}

enum ItemCondition {
  mint('mint', 'Mint'),
  nearMint('near_mint', 'Near Mint'),
  good('good', 'Good'),
  fair('fair', 'Fair'),
  poor('poor', 'Poor');

  final String value;
  final String label;
  const ItemCondition(this.value, this.label);

  static ItemCondition fromValue(String value) {
    return ItemCondition.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ItemCondition.good,
    );
  }
}

class CollectionItem {
  final String id;
  final String gameId;
  final String gameTitle;
  final String platform;
  final ItemFormat format;
  final ItemCondition condition;
  final String region;
  final double? purchasePrice;
  final String? purchaseCurrency;
  final Timestamp? purchaseDate;
  final String? notes;
  final Timestamp? addedAt;

  const CollectionItem({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.platform,
    required this.format,
    required this.condition,
    required this.region,
    this.purchasePrice,
    this.purchaseCurrency,
    this.purchaseDate,
    this.notes,
    this.addedAt,
  });

  factory CollectionItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CollectionItem(
      id: doc.id,
      gameId: data['game_id'] as String? ?? '',
      gameTitle: data['game_title'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      format: ItemFormat.fromValue(data['format'] as String? ?? ''),
      condition: ItemCondition.fromValue(data['condition'] as String? ?? ''),
      region: data['region'] as String? ?? '',
      purchasePrice: (data['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: data['purchase_currency'] as String?,
      purchaseDate: parseTimestamp(data['purchase_date']),
      notes: data['notes'] as String?,
      addedAt: parseTimestamp(data['added_at']),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'game_id': gameId,
        'game_title': gameTitle,
        'platform': platform,
        'format': format.value,
        'condition': condition.value,
        'region': region,
        if (purchasePrice != null) 'purchase_price': purchasePrice,
        if (purchaseCurrency != null) 'purchase_currency': purchaseCurrency,
        if (purchaseDate != null) 'purchase_date': purchaseDate,
        if (notes != null) 'notes': notes,
        'added_at': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreUpdate() => {
        'platform': platform,
        'format': format.value,
        'condition': condition.value,
        'region': region,
        'purchase_price': purchasePrice,
        'purchase_currency': purchaseCurrency,
        'purchase_date': purchaseDate,
        'notes': notes,
      };
}
