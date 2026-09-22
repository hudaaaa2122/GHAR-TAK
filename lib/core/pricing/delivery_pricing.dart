import '../../data/models/models.dart';

/// Mirrors website cart/checkout shipping math
/// (`useCartOrderPricing` / CheckoutPaymentPage).
class DeliveryQuote {
  const DeliveryQuote({
    required this.baseFee,
    required this.fee,
    required this.discount,
    required this.isFree,
    required this.threshold,
    required this.freeShippingEnabled,
  });

  /// Shipping class amount before free-shipping discount.
  final double baseFee;

  /// Amount charged (after free-shipping discount).
  final double fee;

  /// Discount applied from free-shipping rules.
  final double discount;

  final bool isFree;
  final double threshold;
  final bool freeShippingEnabled;

  double get needForFree {
    if (!freeShippingEnabled || threshold <= 0) return 0;
    return (threshold - 0).clamp(0, double.infinity);
  }
}

DeliveryQuote quoteDelivery({
  required double subtotal,
  required SiteSettingsModel? settings,
  required double baseShippingAmount,
  String shippingType = 'fixed',
}) {
  final freeOn = settings?.freeShipping == true;
  final threshold = settings?.freeShippingAmount ?? 0;
  final maxOff = settings?.maximumShippingAmountOff ?? 0;

  double base = 0;
  switch (shippingType) {
    case 'percentage':
      base = subtotal * (baseShippingAmount / 100);
      break;
    case 'free_shipping':
      base = 0;
      break;
    case 'fixed':
    default:
      base = baseShippingAmount;
  }

  final qualifies =
      freeOn && threshold > 0 && base > 0 && subtotal >= threshold;
  final discount = qualifies
      ? (maxOff > 0 ? (maxOff < base ? maxOff : base) : base)
      : 0.0;
  final fee = (base - discount).clamp(0, double.infinity).toDouble();

  return DeliveryQuote(
    baseFee: base,
    fee: fee,
    discount: discount,
    isFree: fee <= 0,
    threshold: threshold,
    freeShippingEnabled: freeOn,
  );
}
