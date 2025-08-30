class WishItem {
  final String id;
  String name;
  String? productUrl;
  double? estimatedPrice;
  String? suggestedStore;
  String? notes;
  String? imageUrl;
  int priority; // 1 (low) to 5 (high) or custom enum
  bool isBought; // Para el creador: si alguien lo ha comprado.
  String? boughtById; // ID del contacto que lo marcó (opcional, para el creador)

  WishItem({
    required this.id,
    required this.name,
    this.productUrl,
    this.estimatedPrice,
    this.suggestedStore,
    this.notes,
    this.imageUrl,
    this.priority = 3, // Default to medium
    this.isBought = false,
    this.boughtById,
  });
}