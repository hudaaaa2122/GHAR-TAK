class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.detail,
    this.data,
    this.total,
    this.totalCount,
    this.page,
    this.raw,
  });

  final bool success;
  final String? detail;
  final T? data;
  final int? total;
  final int? totalCount;
  final int? page;
  final Map<String, dynamic>? raw;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic raw)? mapData,
  }) {
    final successRaw = json['success'];
    final ok = successRaw == 1 || successRaw == true || successRaw == '1';
    final dataRaw = json['data'];
    return ApiResponse(
      success: ok,
      detail: json['detail']?.toString() ?? json['message']?.toString(),
      data: mapData != null ? mapData(dataRaw) : dataRaw as T?,
      total: _asInt(json['total']),
      totalCount: _asInt(json['totalCount'] ?? json['total_count']),
      page: _asInt(json['page']),
      raw: json,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.isTimeout = false});

  final String message;
  final int? statusCode;
  final bool isTimeout;

  @override
  String toString() => message;
}

extension ApiResponseX<T> on ApiResponse<T> {
  /// Throws [ApiException] when the FastAPI envelope reports failure.
  ApiResponse<T> ensureSuccess([String fallback = 'Request failed']) {
    if (!success) {
      throw ApiException(detail?.isNotEmpty == true ? detail! : fallback);
    }
    return this;
  }
}
