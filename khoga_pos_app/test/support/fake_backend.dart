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
  bool mustChangePassword = false,
  bool loginFails = false,
  bool hasOpenShift = false,
}) {
  final p = profile ??
      <String, dynamic>{
        'id': 'u1',
        'username': 'cashier01',
        'fullName': 'Nguyễn Thu Ngân',
        'role': 'CASHIER',
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
