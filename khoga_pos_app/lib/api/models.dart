/// Mirrors com.khoga.staff.dto.AttendanceReportRow
class AttendanceReportRow {
  final String userId;
  final String employeeName;
  final String shiftDate;
  final String? scheduledStart;
  final String? scheduledEnd;
  final String? checkInAt;
  final String? checkOutAt;
  final String status;
  final String? shiftType;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final int overtimeMinutes;
  final int workedMinutes;

  AttendanceReportRow({
    required this.userId,
    required this.employeeName,
    required this.shiftDate,
    this.scheduledStart,
    this.scheduledEnd,
    this.checkInAt,
    this.checkOutAt,
    required this.status,
    this.shiftType,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.overtimeMinutes,
    required this.workedMinutes,
  });

  factory AttendanceReportRow.fromJson(Map<String, dynamic> j) => AttendanceReportRow(
        userId: j['userId']?.toString() ?? '',
        employeeName: j['employeeName'] as String? ?? 'Unknown',
        shiftDate: j['shiftDate'] as String? ?? '',
        scheduledStart: j['scheduledStart'] as String?,
        scheduledEnd: j['scheduledEnd'] as String?,
        checkInAt: j['checkInAt'] as String?,
        checkOutAt: j['checkOutAt'] as String?,
        status: j['status'] as String? ?? 'ABSENT',
        shiftType: j['shiftType'] as String?,
        lateMinutes: (j['lateMinutes'] as num?)?.toInt() ?? 0,
        earlyLeaveMinutes: (j['earlyLeaveMinutes'] as num?)?.toInt() ?? 0,
        overtimeMinutes: (j['overtimeMinutes'] as num?)?.toInt() ?? 0,
        workedMinutes: (j['workedMinutes'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors com.khoga.auth.dto.LoginResponse.
class LoginResponse {
  final String token;
  final String role;
  final bool mustChangePassword;

  LoginResponse({required this.token, required this.role, required this.mustChangePassword});

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        token: j['token'] as String,
        role: j['role'] as String,
        mustChangePassword: j['mustChangePassword'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.auth.dto.ProfileResponse.
class Profile {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? email;
  final String? phone;
  final String? storeId;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.storeId,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: j['fullName'] as String,
        role: j['role'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        storeId: j['storeId'] as String?,
      );
}

/// Mirrors com.khoga.pos.dto.ShiftResponse (status is "OPEN" / "CLOSED").
class Shift {
  final String id;
  final String posRegisterId;
  final num startingCash;
  final String status;

  Shift({required this.id, required this.posRegisterId, required this.startingCash, required this.status});

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        posRegisterId: j['posRegisterId'] as String? ?? '',
        startingCash: (j['startingCash'] as num?) ?? 0,
        status: j['status'] as String? ?? 'OPEN',
      );
}

/// Mirrors com.khoga.order.dto.OrderSummaryResponse (history row / queue row).
class OrderSummary {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String orderType;
  final num total;
  final int itemCount;
  final String? customerName;
  final String? createdAt;

  OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.orderType,
    required this.total,
    required this.itemCount,
    this.customerName,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: j['id'] as String,
        orderNumber: j['orderNumber'] as String? ?? '',
        status: j['status'] as String? ?? '',
        paymentStatus: j['paymentStatus'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        orderType: j['orderType'] as String? ?? '',
        total: (j['total'] as num?) ?? 0,
        itemCount: (j['itemCount'] as int?) ?? 0,
        customerName: j['customerName'] as String?,
        createdAt: j['createdAt'] as String?,
      );
}

/// Mirrors com.khoga.order.dto.StatusUpdateResponse (UC-58 transition result).
class StatusUpdate {
  final String id;
  final String orderNumber;
  final String status;
  final List<String> stockWarnings;

  StatusUpdate({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.stockWarnings = const [],
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> j) => StatusUpdate(
        id: j['id'] as String,
        orderNumber: j['orderNumber'] as String? ?? '',
        status: j['status'] as String? ?? '',
        stockWarnings: ((j['stockWarnings'] as List?) ?? const []).map((e) => e as String).toList(),
      );
}

/// Mirrors com.khoga.order.dto.OrderItemLine (+ toppings).
class OrderItemLine {
  final String menuItemName;
  final int quantity;
  final num unitPrice;
  final List<OrderToppingLine> toppings;

  OrderItemLine({
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    this.toppings = const [],
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> j) => OrderItemLine(
        menuItemName: j['menuItemName'] as String? ?? '',
        quantity: (j['quantity'] as int?) ?? 0,
        unitPrice: (j['unitPrice'] as num?) ?? 0,
        toppings: ((j['toppings'] as List?) ?? const [])
            .map((t) => OrderToppingLine.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  num get lineTotal => unitPrice * quantity + toppings.fold<num>(0, (s, t) => s + t.unitPrice * t.quantity);
}

class OrderToppingLine {
  final String name;
  final int quantity;
  final num unitPrice;
  OrderToppingLine({required this.name, required this.quantity, required this.unitPrice});
  factory OrderToppingLine.fromJson(Map<String, dynamic> j) => OrderToppingLine(
        name: j['name'] as String? ?? '',
        quantity: (j['quantity'] as int?) ?? 0,
        unitPrice: (j['unitPrice'] as num?) ?? 0,
      );
}

/// Mirrors com.khoga.order.dto.OrderDetailResponse (UC-73 full order view).
class OrderDetail {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String orderType;
  final num subtotal;
  final num discount;
  final num taxAmount;
  final num total;
  final String? customerName;
  final List<OrderItemLine> items;
  final String? createdAt;

  OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.orderType,
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.total,
    required this.items,
    this.customerName,
    this.createdAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
        id: j['id'] as String,
        orderNumber: j['orderNumber'] as String? ?? '',
        status: j['status'] as String? ?? '',
        paymentStatus: j['paymentStatus'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        orderType: j['orderType'] as String? ?? '',
        subtotal: (j['subtotal'] as num?) ?? 0,
        discount: (j['discount'] as num?) ?? 0,
        taxAmount: (j['taxAmount'] as num?) ?? 0,
        total: (j['total'] as num?) ?? 0,
        customerName: j['customerName'] as String?,
        items: ((j['items'] as List?) ?? const [])
            .map((i) => OrderItemLine.fromJson(i as Map<String, dynamic>))
            .toList(),
        createdAt: j['createdAt'] as String?,
      );
}

/// Mirrors com.khoga.pos.dto.ZReportResponse (UC-53 close-shift reconciliation).
class ZReport {
  final String sessionId;
  final String posRegisterId;
  final num openingCash;
  final num totalCashSales;
  final num expectedCash;
  final num closingCash;
  final num discrepancy;
  final bool discrepancyFlagged;

  ZReport({
    required this.sessionId,
    required this.posRegisterId,
    required this.openingCash,
    required this.totalCashSales,
    required this.expectedCash,
    required this.closingCash,
    required this.discrepancy,
    required this.discrepancyFlagged,
  });

  factory ZReport.fromJson(Map<String, dynamic> j) => ZReport(
        sessionId: j['sessionId'] as String? ?? '',
        posRegisterId: j['posRegisterId'] as String? ?? '',
        openingCash: (j['openingCash'] as num?) ?? 0,
        totalCashSales: (j['totalCashSales'] as num?) ?? 0,
        expectedCash: (j['expectedCash'] as num?) ?? 0,
        closingCash: (j['closingCash'] as num?) ?? 0,
        discrepancy: (j['discrepancy'] as num?) ?? 0,
        discrepancyFlagged: j['discrepancyFlagged'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.staff.dto.ScheduleResponse (UC-35 scheduled shift).
class ScheduleShift {
  final String id;
  final String employeeId;
  final String employeeName;
  final String role;
  final String shiftDate;
  final String shiftType;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? posRegisterId;
  final bool crossBranch;

  ScheduleShift({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.shiftDate,
    required this.shiftType,
    this.shiftStartTime,
    this.shiftEndTime,
    this.posRegisterId,
    this.crossBranch = false,
  });

  factory ScheduleShift.fromJson(Map<String, dynamic> j) => ScheduleShift(
        id: j['id'] as String,
        employeeId: j['employeeId'] as String? ?? '',
        employeeName: j['employeeName'] as String? ?? '',
        role: j['role'] as String? ?? '',
        shiftDate: j['shiftDate'] as String? ?? '',
        shiftType: j['shiftType'] as String? ?? '',
        shiftStartTime: j['shiftStartTime'] as String?,
        shiftEndTime: j['shiftEndTime'] as String?,
        posRegisterId: j['posRegisterId'] as String?,
        crossBranch: j['crossBranch'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.staff.dto.StaffRosterResponse (UC-66 roster row).
class StaffRoster {
  final String userId;
  final String? employeeId;
  final String fullName;
  final String role;
  final bool pinSet;
  final bool pinLocked;
  final bool isActive;

  StaffRoster({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.pinSet,
    required this.pinLocked,
    required this.isActive,
    this.employeeId,
  });

  factory StaffRoster.fromJson(Map<String, dynamic> j) => StaffRoster(
        userId: j['userId'] as String,
        employeeId: j['employeeId'] as String?,
        fullName: j['fullName'] as String? ?? '',
        role: j['role'] as String? ?? '',
        pinSet: j['pinSet'] as bool? ?? false,
        pinLocked: j['pinLocked'] as bool? ?? false,
        isActive: j['isActive'] as bool? ?? true,
      );
}

/// Mirrors com.khoga.staff.dto.AttendanceResponse (UC-67 attendance pairing).
class Attendance {
  final String id;
  final String employeeName;
  final String? checkInAt;
  final String? checkOutAt;
  final String status;
  final bool pendingVerification;
  final bool photoCaptured;

  Attendance({
    required this.id,
    required this.employeeName,
    required this.status,
    this.checkInAt,
    this.checkOutAt,
    this.pendingVerification = false,
    this.photoCaptured = false,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: j['id'] as String,
        employeeName: j['employeeName'] as String? ?? '',
        checkInAt: j['checkInAt'] as String?,
        checkOutAt: j['checkOutAt'] as String?,
        status: j['status'] as String? ?? '',
        pendingVerification: j['pendingVerification'] as bool? ?? false,
        photoCaptured: j['photoCaptured'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.inventory.dto.StockItemResponse (UC-31 stock dashboard row).
class StockItem {
  final String id;
  final String rawMaterialId;
  final String code;
  final String name;
  final String unit;
  final num currentQuantity;
  final num minAlertThreshold;
  final num standardCost;
  final bool lowStock;

  StockItem({
    required this.id,
    required this.rawMaterialId,
    required this.code,
    required this.name,
    required this.unit,
    required this.currentQuantity,
    required this.minAlertThreshold,
    required this.standardCost,
    required this.lowStock,
  });

  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
        id: j['id'] as String,
        rawMaterialId: j['rawMaterialId'] as String? ?? '',
        code: j['code'] as String? ?? '',
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        currentQuantity: (j['currentQuantity'] as num?) ?? 0,
        minAlertThreshold: (j['minAlertThreshold'] as num?) ?? 0,
        standardCost: (j['standardCost'] as num?) ?? 0,
        lowStock: j['lowStock'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.inventory.dto.StockTransactionResponse (UC-61 ledger row).
class StockTransaction {
  final String id;
  final String materialName;
  final String transactionType;
  final num quantity;
  final num quantityBefore;
  final num quantityAfter;
  final String? reason;
  final String? managerName;
  final String? createdAt;

  StockTransaction({
    required this.id,
    required this.materialName,
    required this.transactionType,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    this.reason,
    this.managerName,
    this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> j) => StockTransaction(
        id: j['id'] as String,
        materialName: j['materialName'] as String? ?? '',
        transactionType: j['transactionType'] as String? ?? '',
        quantity: (j['quantity'] as num?) ?? 0,
        quantityBefore: (j['quantityBefore'] as num?) ?? 0,
        quantityAfter: (j['quantityAfter'] as num?) ?? 0,
        reason: j['reason'] as String?,
        managerName: j['managerName'] as String?,
        createdAt: j['createdAt'] as String?,
      );
}

/// Mirrors com.khoga.inventory.dto.StockAuditResultLine (UC-34 discrepancy line).
class StockAuditResult {
  final String stockItemId;
  final String name;
  final num systemQuantity;
  final num actualQuantity;
  final num adjustment;

  StockAuditResult({
    required this.stockItemId,
    required this.name,
    required this.systemQuantity,
    required this.actualQuantity,
    required this.adjustment,
  });

  factory StockAuditResult.fromJson(Map<String, dynamic> j) => StockAuditResult(
        stockItemId: j['stockItemId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        systemQuantity: (j['systemQuantity'] as num?) ?? 0,
        actualQuantity: (j['actualQuantity'] as num?) ?? 0,
        adjustment: (j['adjustment'] as num?) ?? 0,
      );
}

/// Mirrors com.khoga.customer.dto.CustomerResponse (subset used by the POS member lookup).
class CustomerLite {
  final String id;
  final String fullName;
  final String? phone;
  final int points;

  CustomerLite({required this.id, required this.fullName, this.phone, this.points = 0});

  factory CustomerLite.fromJson(Map<String, dynamic> j) => CustomerLite(
        id: j['id'] as String,
        fullName: j['fullName'] as String? ?? '',
        phone: j['phone'] as String?,
        points: (j['points'] as int?) ?? 0,
      );
}

/// Mirrors com.khoga.catalog.dto.CategoryResponse (subset).
class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'] as String, name: j['name'] as String);
}

/// Mirrors com.khoga.catalog.dto.MenuItemResponse (subset used by the POS).
class MenuItem {
  final String id;
  final String name;
  final num price;
  final String? categoryId;
  final String? categoryName;

  MenuItem({required this.id, required this.name, required this.price, this.categoryId, this.categoryName});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num?) ?? 0,
        categoryId: j['categoryId'] as String?,
        categoryName: j['categoryName'] as String?,
      );
}

/// Mirrors com.khoga.pos.dto.DiscountBreakdown (BR-70 stacking pipeline).
class CheckoutBreakdown {
  final num grossSubtotal;
  final num voucherDiscount;
  final num pointDiscount;
  final num taxAmount;
  final num netTotalPayable;
  final int pointsEarned;

  CheckoutBreakdown({
    required this.grossSubtotal,
    required this.voucherDiscount,
    required this.pointDiscount,
    required this.taxAmount,
    required this.netTotalPayable,
    required this.pointsEarned,
  });

  factory CheckoutBreakdown.fromJson(Map<String, dynamic> j) => CheckoutBreakdown(
        grossSubtotal: (j['grossSubtotal'] as num?) ?? 0,
        voucherDiscount: (j['voucherDiscount'] as num?) ?? 0,
        pointDiscount: (j['pointDiscount'] as num?) ?? 0,
        taxAmount: (j['taxAmount'] as num?) ?? 0,
        netTotalPayable: (j['netTotalPayable'] as num?) ?? 0,
        pointsEarned: (j['pointsEarned'] as int?) ?? 0,
      );
}

/// Mirrors com.khoga.pos.dto.CheckoutResponse.
class CheckoutResult {
  final String orderId;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final num changeDue;
  final String? qrContent;
  final CheckoutBreakdown breakdown;

  CheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.changeDue,
    required this.breakdown,
    this.qrContent,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        orderId: j['orderId'] as String,
        orderNumber: j['orderNumber'] as String? ?? '',
        status: j['status'] as String? ?? '',
        paymentStatus: j['paymentStatus'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        changeDue: (j['changeDue'] as num?) ?? 0,
        qrContent: j['qrContent'] as String?,
        breakdown: CheckoutBreakdown.fromJson((j['breakdown'] as Map<String, dynamic>?) ?? const {}),
      );
}
