import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class PaymentBreakdown {
  final double cash;
  final double card;
  final double vietqr;

  PaymentBreakdown({required this.cash, required this.card, required this.vietqr});

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      cash: (json['cash'] ?? 0).toDouble(),
      card: (json['card'] ?? 0).toDouble(),
      vietqr: (json['vietqr'] ?? 0).toDouble(),
    );
  }

  double get total => cash + card + vietqr;
}

class StoreRevenueReport {
  final String from;
  final String to;
  final String? storeId;
  final double netRevenue;
  final int completedOrders;
  final double discrepancyTotal;
  final PaymentBreakdown payments;

  StoreRevenueReport({
    required this.from,
    required this.to,
    this.storeId,
    required this.netRevenue,
    required this.completedOrders,
    required this.discrepancyTotal,
    required this.payments,
  });

  factory StoreRevenueReport.fromJson(Map<String, dynamic> json) {
    return StoreRevenueReport(
      from: json['from'] as String,
      to: json['to'] as String,
      storeId: json['storeId'] as String?,
      netRevenue: (json['netRevenue'] ?? 0).toDouble(),
      completedOrders: json['completedOrders'] as int? ?? 0,
      discrepancyTotal: (json['discrepancyTotal'] ?? 0).toDouble(),
      payments: PaymentBreakdown.fromJson(json['payments'] ?? {}),
    );
  }
}

class ReportApi {
  final ApiClient _client;

  ReportApi(this._client);

  Future<StoreRevenueReport> getStoreRevenue(String from, String to) async {
    // _client.get already unwraps the JSON and returns the 'data' payload
    final data = await _client.get('/reports/store-revenue?from=$from&to=$to');
    return StoreRevenueReport.fromJson(data);
  }
}
