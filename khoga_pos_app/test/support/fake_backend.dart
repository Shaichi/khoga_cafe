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

/// Test voucher table: only GIAM10 is valid (10.000 off), mirroring a fixed-amount voucher.
num _voucherDiscount(String? code) => code == 'GIAM10' ? 10000 : 0;

Map<String, dynamic> _breakdown(num gross, {num voucherDiscount = 0, int pointsRedeemed = 0}) {
  final pointDiscount = pointsRedeemed * 100; // valuePerPoint = 100
  final net = (gross - voucherDiscount - pointDiscount).clamp(0, gross);
  return {
    'grossSubtotal': gross,
    'voucherDiscount': voucherDiscount,
    'pointsRedeemed': pointsRedeemed,
    'pointDiscount': pointDiscount,
    'finalTaxableSubtotal': net,
    'taxAmount': (net * 10 / 110).round(),
    'netTotalPayable': net,
    'pointsEarned': (net / 1000).floor(),
  };
}

Map<String, dynamic> _page(List<Map<String, dynamic>> content) => {
      'content': content,
      'page': 0,
      'size': content.length,
      'totalElements': content.length,
      'totalPages': 1,
    };

Map<String, dynamic> _scheduleFromBody(String id, Map<String, dynamic> body) => {
      'id': id,
      'employeeId': body['employeeId'] ?? 'u1',
      'employeeName': body['employeeId'] == 'u2' ? 'Lê Pha Chế' : 'Nguyễn Thu Ngân',
      'role': 'CASHIER',
      'shiftDate': body['shiftDate'] ?? '2026-06-29',
      'shiftType': body['shiftType'] ?? 'MORNING',
      'shiftStartTime': body['shiftStartTime'],
      'shiftEndTime': body['shiftEndTime'],
      'posRegisterId': body['posRegisterId'],
      'crossBranch': false,
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
        'username': switch (role) {
          'STORE_MANAGER' => 'manager01',
          'BARISTA' => 'barista01',
          _ => 'cashier01',
        },
        'fullName': switch (role) {
          'STORE_MANAGER' => 'Trần Quản Lý',
          'BARISTA' => 'Lê Pha Chế',
          _ => 'Nguyễn Thu Ngân',
        },
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

    if (path.endsWith('/profile')) {
      if (req.method == 'PUT') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return apiOk({...p, 'email': body['email'], 'phone': body['phone']}, message: 'Cập nhật hồ sơ thành công');
      }
      return apiOk(p);
    }
    if (path.endsWith('/auth/change-password')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      if ((body['currentPassword'] as String?) == 'wrong') {
        return apiError('Mật khẩu hiện tại không đúng', 400);
      }
      return apiOk(null, message: 'Đổi mật khẩu thành công');
    }
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
    // Barista queue (UC-57) — active orders oldest-first.
    if (path.endsWith('/queue')) {
      return apiOk([
        {
          'id': 'oq1', 'orderNumber': 'ORD-101', 'status': 'PENDING', 'paymentStatus': 'PAID',
          'paymentMethod': 'CASH', 'orderType': 'DINE_IN', 'total': 30000, 'itemCount': 1,
          'customerName': null, 'createdAt': '2026-06-28T11:00:00',
        },
        {
          'id': 'oq2', 'orderNumber': 'ORD-102', 'status': 'PREPARING', 'paymentStatus': 'PAID',
          'paymentMethod': 'VIETQR', 'orderType': 'TAKEAWAY', 'total': 45000, 'itemCount': 2,
          'customerName': 'Anh Minh', 'createdAt': '2026-06-28T11:05:00',
        },
      ]);
    }
    // Barista status transition (UC-58): /orders/{id}/status.
    final statusMatch = RegExp(r'/orders/([\w-]+)/status$').firstMatch(path);
    if (statusMatch != null && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      return apiOk({
        'id': statusMatch.group(1),
        'orderNumber': 'ORD-101',
        'status': status,
        // BR-89: deducting on PREPARING may push an ingredient negative.
        'stockWarnings': status == 'PREPARING' ? ['Cà phê hạt đã âm kho — cần nhập thêm'] : <String>[],
      }, message: 'Đã cập nhật trạng thái đơn');
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
    // ---- Staff: attendance (UC-67, all staff) ----
    if (path.endsWith('/attendance/check-in')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      if ((body['pin'] as String?) != '1234') return apiError('Mã PIN không đúng', 400);
      final hasPhoto = (body['photoUrl'] as String?)?.isNotEmpty ?? false;
      return apiOk({
        'id': 'att-1', 'userId': 'u1', 'employeeName': 'Nguyễn Thu Ngân',
        'shiftDate': '2026-06-28', 'checkInAt': '2026-06-28T08:02:00', 'checkOutAt': null,
        'scheduledStart': '2026-06-28T08:00:00', 'status': 'PRESENT',
        'pendingVerification': !hasPhoto, 'photoCaptured': hasPhoto,
      }, message: 'Đã check-in');
    }
    if (path.endsWith('/attendance/check-out')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      if ((body['pin'] as String?) != '1234') return apiError('Mã PIN không đúng', 400);
      return apiOk({
        'id': 'att-1', 'userId': 'u1', 'employeeName': 'Nguyễn Thu Ngân',
        'shiftDate': '2026-06-28', 'checkInAt': '2026-06-28T08:02:00', 'checkOutAt': '2026-06-28T16:30:00',
        'scheduledStart': '2026-06-28T08:00:00', 'status': 'PRESENT',
        'pendingVerification': false, 'photoCaptured': true,
      }, message: 'Đã check-out');
    }

    // ---- Staff: scheduling + roster (UC-35/66), Store Manager ----
    final schedMatch = RegExp(r'/schedules/([\w-]+)$').firstMatch(path);
    if (schedMatch != null && req.method == 'PUT') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return apiOk(_scheduleFromBody(schedMatch.group(1)!, body), message: 'Đã cập nhật lịch');
    }
    if (path.endsWith('/schedules')) {
      if (req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return apiOk(_scheduleFromBody('sc-new', body), message: 'Đã tạo lịch làm việc', status: 201);
      }
      return apiOk([
        {
          'id': 'sc1', 'employeeId': 'u1', 'employeeName': 'Nguyễn Thu Ngân', 'role': 'CASHIER',
          'shiftDate': '2026-06-28', 'shiftType': 'MORNING', 'shiftStartTime': '08:00', 'shiftEndTime': '12:00',
          'posRegisterId': 'POS-01', 'crossBranch': false,
        },
        {
          'id': 'sc2', 'employeeId': 'u2', 'employeeName': 'Lê Pha Chế', 'role': 'BARISTA',
          'shiftDate': '2026-06-28', 'shiftType': 'AFTERNOON', 'shiftStartTime': '12:00', 'shiftEndTime': '18:00',
          'posRegisterId': null, 'crossBranch': true,
        },
      ]);
    }
    if (path.endsWith('/staff')) {
      return apiOk([
        {
          'userId': 'u1', 'employeeId': 'EMP-001', 'fullName': 'Nguyễn Thu Ngân', 'role': 'CASHIER',
          'pinSet': true, 'pinLocked': false, 'isActive': true,
        },
        {
          'userId': 'u2', 'employeeId': 'EMP-002', 'fullName': 'Lê Pha Chế', 'role': 'BARISTA',
          'pinSet': false, 'pinLocked': false, 'isActive': true,
        },
      ]);
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
    if (path.endsWith('/stock/export')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final qty = (body['quantity'] as num?) ?? 0;
      return apiOk({
        'id': 'tx-exp', 'stockItemId': body['stockItemId'], 'materialName': 'Sữa tươi',
        'transactionType': 'EXPORT', 'quantity': -qty, 'quantityBefore': 12, 'quantityAfter': 12 - qty,
        'reason': body['reason'], 'managerName': 'Quản lý', 'createdAt': '2026-06-28T10:30:00',
      }, message: 'Xuất kho thành công');
    }
    if (path.endsWith('/stock/audit')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final items = (body['items'] as List).cast<Map<String, dynamic>>();
      const system = {'si1': 5, 'si2': 12};
      const names = {'si1': 'Cà phê hạt', 'si2': 'Sữa tươi'};
      return apiOk([
        for (final it in items)
          {
            'stockItemId': it['stockItemId'],
            'name': names[it['stockItemId']] ?? 'Nguyên liệu',
            'systemQuantity': system[it['stockItemId']] ?? 0,
            'actualQuantity': it['actualQuantity'],
            'adjustment': (it['actualQuantity'] as num) - (system[it['stockItemId']] ?? 0),
          },
      ], message: 'Kiểm kê hoàn tất');
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
    if (path.endsWith('/customers')) {
      final search = (req.url.queryParameters['search'] ?? '').toLowerCase();
      final all = [
        {'id': 'cust-1', 'phone': '0900000001', 'fullName': 'Nguyễn Hội Viên', 'email': null, 'points': 500, 'isActive': true},
        {'id': 'cust-2', 'phone': '0987654321', 'fullName': 'Trần Khách Quen', 'email': null, 'points': 120, 'isActive': true},
      ];
      final filtered = search.isEmpty
          ? all
          : all.where((c) =>
              (c['fullName'] as String).toLowerCase().contains(search) ||
              (c['phone'] as String).contains(search)).toList();
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
      return apiOk(_breakdown(
        _grossOf(body['items'] as List),
        voucherDiscount: _voucherDiscount(body['voucherCode'] as String?),
        pointsRedeemed: (body['redeemPoints'] as num?)?.toInt() ?? 0,
      ));
    }
    if (path.endsWith('/checkout')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final gross = _grossOf(body['items'] as List);
      final method = body['paymentMethod'] as String;
      final cash = (body['cashReceived'] as num?) ?? 0;
      final breakdown = _breakdown(
        gross,
        voucherDiscount: _voucherDiscount(body['voucherCode'] as String?),
        pointsRedeemed: (body['redeemPoints'] as num?)?.toInt() ?? 0,
      );
      final net = breakdown['netTotalPayable'] as num;
      return apiOk({
        'orderId': 'o1',
        'orderNumber': 'ORD-001',
        'status': 'PENDING',
        'paymentStatus': method == 'VIETQR' ? 'AWAITING_PAYMENT' : 'PAID',
        'paymentMethod': method,
        'breakdown': breakdown,
        'changeDue': method == 'CASH' ? (cash - net) : 0,
        'qrContent': method == 'VIETQR' ? 'vietqr://order/o1' : null,
        'qrReference': method == 'VIETQR' ? 'REF-1' : null,
      }, message: 'Tạo đơn thành công', status: 201);
    }
    
    final toppingsMatch = RegExp(r'/menu-items/([\w-]+)/toppings$').firstMatch(path);
    if (toppingsMatch != null) {
      if (toppingsMatch.group(1) == 'm1') {
        return apiOk([
          {'id': 't1', 'name': 'Shot thêm', 'price': 5000, 'active': true},
        ]);
      }
      return apiOk([]); // no toppings
    }

    if (path.endsWith('/vouchers')) {
      return apiOk([
        {'id': 'v1', 'code': 'GIAM10', 'discountType': 'FIXED', 'discountValue': 10000, 'description': 'Giảm 10K', 'status': 'ACTIVE'}
      ]);
    }
    
    return apiError('Not mocked: $path', 404);
  });
}
