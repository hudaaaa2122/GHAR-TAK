import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../shared/app_toast.dart';

/// Calls customer-website Next.js payment APIs (same as web checkout).
class PaymentGatewayApi {
  PaymentGatewayApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.websiteBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                validateStatus: (_) => true,
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post(path, data: body);
    final data = res.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid payment response');
  }

  /// JazzCash M-Wallet initiate.
  Future<JazzCashInitResult> initiateJazzCash({
    required String orderId,
    required double amount,
    required String mobileNumber,
    required String customerEmail,
    required String customerName,
    String? description,
    String? cnic,
  }) async {
    try {
      final body = await _post('/api/jazzcash/initiate', {
        'orderId': orderId,
        'amount': amount,
        'mobileNumber': mobileNumber,
        'customerEmail': customerEmail,
        'customerName': customerName,
        if (description != null) 'description': description,
        if (cnic != null) 'cnic': cnic,
      });
      final success = body['success'] == true;
      final txn = body['txnRefNo']?.toString() ??
          body['transactionId']?.toString() ??
          body['pp_TxnRefNo']?.toString();
      final code =
          body['responseCode']?.toString() ?? body['pp_ResponseCode']?.toString();
      final paid = body['paymentComplete'] == true || code == '000';
      final pending = body['pendingApproval'] == true ||
          code == '157' ||
          code == '210';
      if (success && paid) {
        return JazzCashInitResult(
          success: true,
          paymentComplete: true,
          transactionId: txn,
          txnRefNo: txn,
          responseCode: code ?? '000',
          message: body['message']?.toString(),
        );
      }
      if (success && pending) {
        return JazzCashInitResult(
          success: true,
          pendingApproval: true,
          transactionId: txn,
          txnRefNo: txn,
          responseCode: code,
          message: body['message']?.toString(),
        );
      }
      return JazzCashInitResult(
        success: false,
        error: body['error']?.toString() ??
            body['message']?.toString() ??
            'JazzCash payment failed',
        responseCode: code,
      );
    } catch (e) {
      return JazzCashInitResult(
        success: false,
        error: friendlyUserMessage(e),
      );
    }
  }

  Future<JazzCashStatusResult> jazzCashStatus({
    String? transactionId,
    String? txnRefNo,
  }) async {
    final ref = txnRefNo ?? transactionId;
    if (ref == null || ref.isEmpty) {
      return const JazzCashStatusResult(
        success: false,
        error: 'No active transaction',
      );
    }
    try {
      final body = await _post('/api/jazzcash/status-inquiry', {
        'transactionId': transactionId ?? ref,
        'txnRefNo': ref,
      });
      final complete = body['success'] == true &&
          (body['paymentComplete'] == true ||
              body['responseCode']?.toString() == '000');
      if (complete) {
        return JazzCashStatusResult(
          success: true,
          paymentComplete: true,
          transactionId: body['transactionId']?.toString() ?? transactionId,
          txnRefNo: body['txnRefNo']?.toString() ?? ref,
          message: body['message']?.toString(),
        );
      }
      if (body['success'] == true && body['pendingApproval'] == true) {
        return JazzCashStatusResult(
          success: true,
          pendingApproval: true,
          transactionId: body['transactionId']?.toString() ?? transactionId,
          txnRefNo: body['txnRefNo']?.toString() ?? ref,
          message: body['message']?.toString(),
        );
      }
      return JazzCashStatusResult(
        success: false,
        error: body['error']?.toString() ??
            body['message']?.toString() ??
            'Payment not complete',
        responseCode: body['responseCode']?.toString(),
      );
    } catch (e) {
      return JazzCashStatusResult(
        success: false,
        error: friendlyUserMessage(e),
      );
    }
  }

  /// JazzCash Card Page Redirection — returns postUrl + formFields.
  Future<JazzCashCardInitResult> initiateJazzCashCard({
    required double amount,
    String? description,
  }) async {
    try {
      final body = await _post('/api/jazzcash/card/initiate', {
        'amount': amount,
        if (description != null) 'description': description,
      });
      if (body['success'] != true) {
        return JazzCashCardInitResult(
          success: false,
          error: body['error']?.toString() ?? 'Failed to start JazzCash card',
        );
      }
      if (body['mocked'] == true && body['paymentComplete'] == true) {
        return JazzCashCardInitResult(
          success: true,
          mocked: true,
          paymentComplete: true,
          txnRefNo: body['txnRefNo']?.toString() ??
              body['transactionId']?.toString(),
        );
      }
      final fields = body['formFields'];
      return JazzCashCardInitResult(
        success: true,
        postUrl: body['postUrl']?.toString(),
        formFields: fields is Map
            ? fields.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
            : null,
        txnRefNo: body['txnRefNo']?.toString(),
      );
    } catch (e) {
      return JazzCashCardInitResult(
        success: false,
        error: friendlyUserMessage(e),
      );
    }
  }

  Future<EasyPaisaInitResult> initiateEasyPaisa({
    required String orderId,
    required double amount,
    required String mobileNumber,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      final body = await _post('/api/easypaisa/initiate', {
        'orderId': orderId,
        'amount': amount,
        'mobileNumber': mobileNumber,
        'customerEmail': customerEmail,
        'customerName': customerName,
      });
      if (body['success'] == true && body['transactionId'] != null) {
        return EasyPaisaInitResult(
          success: true,
          transactionId: body['transactionId']?.toString(),
          orderId: body['orderId']?.toString() ?? orderId,
          message: body['message']?.toString(),
        );
      }
      return EasyPaisaInitResult(
        success: false,
        error: body['error']?.toString() ?? 'Failed to initiate EasyPaisa',
        errorCode: body['errorCode']?.toString(),
      );
    } catch (e) {
      return EasyPaisaInitResult(
        success: false,
        error: friendlyUserMessage(e),
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  Future<EasyPaisaOtpResult> verifyEasyPaisaOtp({
    required String transactionId,
    required String orderId,
    required String otp,
  }) async {
    try {
      final body = await _post('/api/easypaisa/verify-otp', {
        'transactionId': transactionId,
        'orderId': orderId,
        'otp': otp,
      });
      final status = body['transactionStatus']?.toString();
      if (body['success'] == true && status == 'SUCCESS') {
        return EasyPaisaOtpResult(
          success: true,
          transactionId: transactionId,
          transactionStatus: 'SUCCESS',
          message: body['message']?.toString(),
        );
      }
      return EasyPaisaOtpResult(
        success: false,
        error: body['error']?.toString() ?? 'OTP verification failed',
        errorCode: body['errorCode']?.toString(),
        transactionStatus: status,
      );
    } catch (e) {
      return EasyPaisaOtpResult(
        success: false,
        error: friendlyUserMessage(e),
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  /// PayFast Pakistan — get token then build redirect form fields.
  Future<PayFastPkResult> initiatePayFastPk({
    required double amount,
    required String email,
    required String phone,
  }) async {
    try {
      final characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      final buf = StringBuffer('GT-${DateTime.now().millisecondsSinceEpoch}-');
      final rnd = DateTime.now().microsecondsSinceEpoch;
      for (var i = 0; i < 4; i++) {
        buf.write(characters[(rnd + i * 7) % characters.length]);
      }
      final basketId = buf.toString();
      final body = await _post('/api/payfast-pk/get-token', {
        'basketId': basketId,
        'amount': amount.toStringAsFixed(2),
      });
      if (body['success'] != true || body['token'] == null) {
        return PayFastPkResult(
          success: false,
          error: body['error']?.toString() ?? 'Failed to get PayFast token',
        );
      }
      final paymentUrl = body['paymentUrl']?.toString() ??
          'https://ipguat.apps.net.pk/Ecommerce/api/Transaction/PostTransaction';
      final origin = AppConfig.websiteBaseUrl;
      final fields = <String, String>{
        'CURRENCY_CODE': 'PKR',
        'MERCHANT_ID': body['merchantId']?.toString() ?? '',
        'MERCHANT_NAME': body['merchantName']?.toString() ?? 'Gher Tak',
        'TOKEN': body['token']?.toString() ?? '',
        'BASKET_ID': basketId,
        'TXNAMT': amount.toStringAsFixed(2),
        'ORDER_DATE': DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
        'SUCCESS_URL': '$origin/payfast-success',
        'FAILURE_URL': '$origin/payfast-failed',
        'CHECKOUT_URL':
            body['checkoutUrl']?.toString() ?? '$origin/api/payfast-pk/ipn',
        'CUSTOMER_EMAIL_ADDRESS': email,
        'CUSTOMER_MOBILE_NO': phone.replaceAll(RegExp(r'[^0-9]'), ''),
        'SIGNATURE': 'CTSPK-${DateTime.now().millisecondsSinceEpoch}',
        'VERSION': 'CTSPK-CART-1.0',
        'TXNDESC': 'Item Purchased from Cart',
        'PROCCODE': '00',
        'TRAN_TYPE': 'ECOMM_PURCHASE',
        'STORE_ID': '',
        'RECURRING_TXN': '',
        'MERCHANT_USERAGENT': 'GherTak-Mobile',
      };
      return PayFastPkResult(
        success: true,
        basketId: basketId,
        postUrl: paymentUrl,
        formFields: fields,
      );
    } catch (e) {
      return PayFastPkResult(
        success: false,
        error: friendlyUserMessage(e),
      );
    }
  }
}

class JazzCashInitResult {
  const JazzCashInitResult({
    required this.success,
    this.paymentComplete = false,
    this.pendingApproval = false,
    this.transactionId,
    this.txnRefNo,
    this.message,
    this.error,
    this.responseCode,
  });

  final bool success;
  final bool paymentComplete;
  final bool pendingApproval;
  final String? transactionId;
  final String? txnRefNo;
  final String? message;
  final String? error;
  final String? responseCode;
}

class JazzCashStatusResult {
  const JazzCashStatusResult({
    required this.success,
    this.paymentComplete = false,
    this.pendingApproval = false,
    this.transactionId,
    this.txnRefNo,
    this.message,
    this.error,
    this.responseCode,
  });

  final bool success;
  final bool paymentComplete;
  final bool pendingApproval;
  final String? transactionId;
  final String? txnRefNo;
  final String? message;
  final String? error;
  final String? responseCode;
}

class JazzCashCardInitResult {
  const JazzCashCardInitResult({
    required this.success,
    this.postUrl,
    this.formFields,
    this.txnRefNo,
    this.mocked = false,
    this.paymentComplete = false,
    this.error,
  });

  final bool success;
  final String? postUrl;
  final Map<String, String>? formFields;
  final String? txnRefNo;
  final bool mocked;
  final bool paymentComplete;
  final String? error;
}

class EasyPaisaInitResult {
  const EasyPaisaInitResult({
    required this.success,
    this.transactionId,
    this.orderId,
    this.message,
    this.error,
    this.errorCode,
  });

  final bool success;
  final String? transactionId;
  final String? orderId;
  final String? message;
  final String? error;
  final String? errorCode;
}

class EasyPaisaOtpResult {
  const EasyPaisaOtpResult({
    required this.success,
    this.transactionId,
    this.transactionStatus,
    this.message,
    this.error,
    this.errorCode,
  });

  final bool success;
  final String? transactionId;
  final String? transactionStatus;
  final String? message;
  final String? error;
  final String? errorCode;
}

class PayFastPkResult {
  const PayFastPkResult({
    required this.success,
    this.basketId,
    this.postUrl,
    this.formFields,
    this.error,
  });

  final bool success;
  final String? basketId;
  final String? postUrl;
  final Map<String, String>? formFields;
  final String? error;
}
