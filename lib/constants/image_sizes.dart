/// Product image size guide (internal reference).
/// Upload at ~2× display for retina. Use JPG for photos; PNG only if transparency needed.
/// All product images are 1:1 (square). Use [BoxFit.contain] / resizeMode contain.
class ImageSizes {
  ImageSizes._();

  // —— Product card (Offers, Best Sellers, Limited Stock, search/category) ——
  static const double cardDisplay = 264;
  static const double cardUpload = 1000;
  static const int cardMaxKb = 500;
  static const double cardPadding = 14;

  // —— Product detail – large hero ——
  static const double detailDisplay = 400;
  static const double detailUpload = 1600;
  static const int detailMaxKb = 800;
  static const double detailRadius = 18;

  // —— Product detail – gallery thumbnail (~4 per row) ——
  static const double thumbDisplay = 105;
  static const double thumbUpload = 500;
  static const int thumbMaxKb = 200;

  /// ~10% inset so product edges are not cropped in source art.
  static const double sourcePaddingRatio = 0.10;
}
