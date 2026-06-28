import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

http.Response apiOk(dynamic data, {String message = 'ok', int status = 200}) => http.Response(
      jsonEncode({'status': 'success', 'message': message, 'data': data}),
      status,
      headers: _jsonHeaders,
    );

http.Response apiError(String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'message': message, 'data': null}),
      status,
      headers: _jsonHeaders,
    );

const _prices = {'m1': 30000, 'm2': 25000, 'm3': 20000};

num _grossOf(List<dynamic> items) => items.fold<num>(0, (sum, it) {
      final m = it as Map<String, dynamic>;
      final price = _prices[m['menuItemId']] ?? 0;
      return sum + price * (m['quantity'] as num);
    });

Map<String, dynamic> _breakdown(num gross) => {
      'grossSubtotal': gross,
      'voucherDiscount': 0,
      'pointsRedeemed': 0,
      'pointDiscount': 0,
      'finalTaxableSubtotal': gross,
      'taxAmount': (gross * 10 / 110).round(),
      'netTotalPayable': gross,
      'pointsEarned': (gross / 1000).floor(),
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> content) => {
      'content': content,
      'page': 0,
      'size': content.length,
      'totalElements': content.length,
      'totalPages': 1,
    };

Map<String, dynamic> _shift({String? register, dynamic startingCash}) => {
      'id': 'shift-1',
      'storeId': 's1',
      'cashierId': 'u1',
      'posRegisterId': register ?? 'POS-01',
      'startingCash': startingCash ?? 1000000,
      'status': 'OPEN',
      'startTime': '2026-06-28T08:00:00',
    };

/// A MockClient standing in for the Khoga backend (our MSW equivalent). Every
/// endpoint except /auth/login requires the Bearer token, so a passing flow
/// proves the token was attached after authentication.
MockClient authBackend({
  Map<String, dynamic>? profile,
  String role = 'CASHIER',
  bool mustChangePassword = false,
  bool loginFails = false,
  bool hasOpenShift = false,
}) {
  final p = profile ??
      <String, dynamic>{
        'id': 'u1',
        'username': role == 'STORE_MANAGER' ? 'manager01' : 'cashier01',
        'fullName': role == 'STORE_MANAGER' ? 'Trần Quản Lý' : 'Nguyễn Thu Ngân',
        'role': role,
        'email': null,
        'phone': null,
        'storeId': 's1',
      };
  return MockClient((req) async {
    final path = req.url.path;
    if (path.endsWith('/auth/login')) {
      if (loginFails) return apiError('Sai tài khoản hoặc mật khẩu', 401);
      return apiOk({'token': 'jwt-1', 'role': p['role'], 'mustChangePassword': mustChangePassword});
    }
    if (req.headers['Authorization'] != 'Bearer jwt-1') return apiError('Yêu cầu xác thực', 401);

    if (path.endsWith('/profile')) return apiOk(p);
    if (path.endsWith('/shifts/active')) {
      if (!hasOpenShift) return apiError('Không có ca đang mở', 404);
      return apiOk(_shift());
    }
    if (path.endsWith('/shifts/open')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return apiOk(
        _shift(register: body['posRegisterId'] as String?, startingCash: body['startingCash']),
        message: 'Đã mở ca',
        status: 201,
      );
    }
    if (path.contains('/shifts/') && path.endsWith('/close')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final closing = (body['closingCash'] as num?) ?? 0;
      const opening = 1000000, sales = 200000;
      const expected = opening + sales; // expected drawer = float + cash sales
      final discrepancy = closing - expected;
      return apiOk({
        'sessionId': 'shift-1',
        'posRegisterId': 'POS-01',
        'openingCash': opening,
        'totalCashSales': sales,
        'expectedCash': expected,
        'closingCash': closing,
        'discrepancy': discrepancy,
        'discrepancyFlagged': discrepancy != 0,
        'startTime': '2026-06-28T08:00:00',
        'closedAt': '2026-06-28T17:00:00',
      }, message: 'Đã đóng ca');
    }
    // Order detail (UC-73): /orders/{id} — matched before the list endpoint.
    final orderDetailMatch = RegExp(r'/orders/([\w-]+)$').firstMatch(path);
    if (orderDetailMatch != null && req.method == 'GET') {
      final id = orderDetailMatch.group(1)!;
      return apiOk({
        'id': id,
        'orderNumber': 'ORD-001',
        'storeId': 's1',
        'status': 'COMPLETED',
        'paymentStatus': 'PAID',
        'paymentMethod': 'CASH',
        'orderType': 'TAKEAWAY',
        'subtotal': 50000,
        'discount': 0,
        'taxAmount': 4545,
        'total': 50000,
        'pointsRedeemed': 0,
        'pointsEarned': 50,
        'customerName': 'Khách lẻ',
        'items': [
          {
            'menuItemName': 'Espresso',
            'quantity': 1,
            'unitPrice': 30000,
            'toppings': [
              {'name': 'Shot thêm', 'quantity': 1, 'unitPrice': 5000},
            ],
          },
          {'menuItemName': 'Trà đào', 'quantity': 1, 'unitPrice': 20000, 'toppings': []},
        ],
        'createdAt': '2026-06-28T09:15:00',
      });
    }
    if (path.endsWith('/orders')) {
      final status = req.url.queryParameters['status'];
      final all = [
        {
          'id': 'o1', 'orderNumber': 'ORD-001', 'status': 'COMPLETED', 'paymentStatus': 'PAID',
          'paymentMethod': 'CASH', 'orderType': 'TAKEAWAY', 'total': 50000, 'itemCount': 2,
          'customerName': 'Khách lẻ', 'createdAt': '2026-06-28T09:15:00',
        },
        {
          'id': 'o2', 'orderNumber': 'ORD-002', 'status': 'CANCELLED', 'paymentStatus': 'UNPAID',
          'paymentMethod': 'VIETQR', 'orderType': 'DINE_IN', 'total': 30000, 'itemCount': 1,
          'customerName': null, 'createdAt': '2026-06-28T10:05:00',
        },
      ];
      final filtered = status == null ? all : all.where((o) => o['status'] == status).toList();
      return apiOk(_page(filtered));
    }
    // ---- Inventory (UC-31/32/61), Store Manager ----
    if (path.endsWith('/stock/transactions')) {
      final type = req.url.queryParameters['type'];
      final all = [
        {
          'id': 'tx1', 'stockItemId': 'si1', 'materialName': 'Cà phê hạt', 'transactionType': 'IMPORT',
          'quantity': 10, 'quantityBefore': 2, 'quantityAfter': 12, 'reason': 'Nhập hàng',
          'managerName': 'Quản lý', 'createdAt': '2026-06-28T08:30:00',
        },
        {
          'id': 'tx2', 'stockItemId': 'si2', 'materialName': 'Sữa tươi', 'transactionType': 'RECIPE_DEDUCTION',
          'quantity': -1, 'quantityBefore': 6, 'quantityAfter': 5, 'reason': 'Trừ công thức',
          'managerName': null, 'createdAt': '2026-06-28T09:00:00',
        },
      ];
      final filtered = type == null ? all : all.where((t) => t['transactionType'] == type).toList();
      return apiOk(_page(filtered));
    }
    if (path.endsWith('/stock/import')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final qty = (body['quantity'] as num?) ?? 0;
      return apiOk({
        'id': 'tx-new', 'stockItemId': body['stockItemId'], 'materialName': 'Cà phê hạt',
        'transactionType': 'IMPORT', 'quantity': qty, 'quantityBefore': 2, 'quantityAfter': 2 + qty,
        'reason': body['note'], 'managerName': 'Quản lý', 'createdAt': '2026-06-28T10:00:00',
      }, message: 'Nhập kho thành công');
    }
    if (path.endsWith('/stock')) {
      final lowOnly = req.url.queryParameters['lowStock'] == 'true';
      final search = req.url.queryParameters['search'];
      final all = [
        {
          'id': 'si1', 'rawMaterialId': 'rm1', 'code': 'CF-01', 'name': 'Cà phê hạt', 'unit': 'kg',
          'currentQuantity': 2, 'minAlertThreshold': 5, 'standardCost': 200000, 'lowStock': true,
        },
        {
          'id': 'si2', 'rawMaterialId': 'rm2', 'code': 'ST-01', 'name': 'Sữa tươi', 'unit': 'lít',
          'currentQuantity': 12, 'minAlertThreshold': 4, 'standardCost': 25000, 'lowStock': false,
        },
      ];
      var filtered = lowOnly ? all.where((s) => s['lowStock'] == true).toList() : all;
      if (search != null && search.isNotEmpty) {
        filtered = filtered
            .where((s) => (s['name'] as String).toLowerCase().contains(search.toLowerCase()))
            .toList();
      }
      return apiOk(_page(filtered));
    }
    if (path.endsWith('/categories')) {
      return apiOk(_page([
        {'id': 'c1', 'name': 'Cà phê'},
        {'id': 'c2', 'name': 'Trà'},
      ]));
    }
    if (path.endsWith('/menu-items')) {
      final items = [
        {'id': 'm1', 'name': 'Espresso', 'price': 30000, 'categoryId': 'c1', 'categoryName': 'Cà phê'},
        {'id': 'm2', 'name': 'Cà phê đen đá', 'price': 25000, 'categoryId': 'c1', 'categoryName': 'Cà phê'},
        {'id': 'm3', 'name': 'Trà đào', 'price': 20000, 'categoryId': 'c2', 'categoryName': 'Trà'},
      ];
      final cat = req.url.queryParameters['categoryId'];
      final filtered = cat == null ? items : items.where((i) => i['categoryId'] == cat).toList();
      return apiOk(_page(filtered));
    }
    if (path.endsWith('/checkout/preview')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return apiOk(_breakdown(_grossOf(body['items'] as List)));
    }
    if (path.endsWith('/checkout')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final gross = _grossOf(body['items'] as List);
      final method = body['paymentMethod'] as String;
      final cash = (body['cashReceived'] as num?) ?? 0;
      return apiOk({
        'orderId': 'o1',
        'orderNumber': 'ORD-001',
        'status': 'PENDING',
        'paymentStatus': method == 'VIETQR' ? 'AWAITING_PAYMENT' : 'PAID',
        'paymentMethod': method,
        'breakdown': _breakdown(gross),
        'changeDue': method == 'CASH' ? (cash - gross) : 0,
        'qrContent': method == 'VIETQR' ? 'vietqr://order/o1' : null,
        'qrReference': method == 'VIETQR' ? 'REF-1' : null,
      }, message: 'Tạo đơn thành công', status: 201);
    }
    return apiError('Not mocked: $path', 404);
  });
}
