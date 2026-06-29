import { apiClient } from './client';
import type { ApiResponse, PageResponse, Role } from './types';

// ---- DTOs (mirror com.khoga.report.dto.*) ----

export interface BranchRevenueRow {
  storeId: string;
  storeName: string;
  revenue: number;
  orders: number;
}
export interface BestSellerRow {
  menuItemId: string;
  name: string;
  quantitySold: number;
}
export interface HqConsolidatedReport {
  from: string;
  to: string;
  totalRevenue: number;
  totalOrders: number;
  avgTransactionValue: number;
  cancellationRate: number;
  branches: BranchRevenueRow[];
  bestSellers: BestSellerRow[];
}

export interface PaymentBreakdown {
  cash: number;
  card: number;
  vietqr: number;
}
export interface StoreRevenueReport {
  from: string;
  to: string;
  storeId: string;
  netRevenue: number;
  completedOrders: number;
  discrepancyTotal: number;
  payments: PaymentBreakdown;
}

export interface MarginRow {
  itemId: string;
  name: string;
  kind: 'ITEM' | 'TOPPING';
  price: number;
  cogs: number;
  margin: number;
  marginPercent: number;
}
export interface ShrinkageRow {
  rawMaterialId: string;
  name: string;
  unit: string;
  theoretical: number;
  actualUsage: number;
  variance: number;
  lossValue: number;
  flagged: boolean;
}
export interface CogsReport {
  from: string;
  to: string;
  storeId: string | null;
  margins: MarginRow[];
  shrinkage: ShrinkageRow[];
}

export interface AuditChangeRow {
  id: string;
  timestamp: string;
  actorId: string | null;
  actor: string;
  entity: string;
  action: string;
  oldValue: string | null;
  newValue: string | null;
}

export interface LoyaltyMovement {
  opening: number;
  issued: number;
  redeemed: number;
  expired: number;
  closing: number;
}
export interface LoyaltyLiabilityReport {
  from: string;
  to: string;
  branchId: string | null;
  outstandingPoints: number;
  movement: LoyaltyMovement;
  note: string;
}

export interface LabourRow {
  storeId: string | null;
  storeName: string;
  labourHours: number;
  netSales: number;
  hoursPerMillion: number;
  vndPerHour: number;
}
export interface LabourReport {
  from: string;
  to: string;
  branchId: string | null;
  branches: LabourRow[];
  chainTotal: LabourRow | null;
}

export interface DailyZReport {
  businessDay: string;
  storeId: string;
  grossSales: number;
  voucherDiscount: number;
  pointDiscount: number;
  netSales: number;
  vat: number;
  refunds: number;
  tender: PaymentBreakdown;
  ordersCompleted: number;
  refundCount: number;
  pendingCancellations: number;
  shiftsInDay: number;
  provisional: boolean;
}

export interface CashierAnomalyRow {
  cashierId: string;
  cashierName: string;
  orders: number;
  cancellations: number;
  cancelRate: number;
  refunds: number;
  refundRate: number;
  vouchers: number;
  comps: number;
  flagged: boolean;
}
export interface AnomalyReport {
  from: string;
  to: string;
  branchId: string | null;
  thresholdPercent: number;
  cashiers: CashierAnomalyRow[];
}

// ---- Date range ----
export interface DateRange {
  from: string; // yyyy-MM-dd
  to: string;
}

// ---- Endpoint clients (P3 /reports/*) ----

export async function hqConsolidated(range: DateRange, branchId?: string): Promise<HqConsolidatedReport> {
  const res = await apiClient.get<ApiResponse<HqConsolidatedReport>>('/reports/hq-consolidated', {
    params: { ...range, branchId },
  });
  return res.data.data;
}

export async function storeRevenue(range: DateRange): Promise<StoreRevenueReport> {
  const res = await apiClient.get<ApiResponse<StoreRevenueReport>>('/reports/store-revenue', { params: range });
  return res.data.data;
}

export async function cogsReport(range: DateRange, branchId?: string): Promise<CogsReport> {
  const res = await apiClient.get<ApiResponse<CogsReport>>('/reports/cogs', { params: { ...range, branchId } });
  return res.data.data;
}

export async function priceHistory(
  range: DateRange,
  opts: { type?: string; actorId?: string; page?: number } = {},
): Promise<PageResponse<AuditChangeRow>> {
  const res = await apiClient.get<ApiResponse<PageResponse<AuditChangeRow>>>('/reports/price-history', {
    params: { ...range, type: opts.type, actorId: opts.actorId, page: opts.page ?? 0 },
  });
  return res.data.data;
}

export async function accessReview(
  range: DateRange,
  opts: { actorId?: string; page?: number } = {},
): Promise<PageResponse<AuditChangeRow>> {
  const res = await apiClient.get<ApiResponse<PageResponse<AuditChangeRow>>>('/reports/access-review', {
    params: { ...range, actorId: opts.actorId, page: opts.page ?? 0 },
  });
  return res.data.data;
}

export async function loyaltyLiability(range: DateRange, branchId?: string): Promise<LoyaltyLiabilityReport> {
  const res = await apiClient.get<ApiResponse<LoyaltyLiabilityReport>>('/reports/loyalty-liability', {
    params: { ...range, branchId },
  });
  return res.data.data;
}

export async function labourReport(range: DateRange, branchId?: string): Promise<LabourReport> {
  const res = await apiClient.get<ApiResponse<LabourReport>>('/reports/labour', { params: { ...range, branchId } });
  return res.data.data;
}

export async function dailyZReport(businessDay: string, branchId?: string): Promise<DailyZReport> {
  const res = await apiClient.get<ApiResponse<DailyZReport>>(`/reports/z-report/${businessDay}`, {
    params: { branchId },
  });
  return res.data.data;
}

export async function anomalyReport(range: DateRange, branchId?: string): Promise<AnomalyReport> {
  const res = await apiClient.get<ApiResponse<AnomalyReport>>('/reports/anomaly', { params: { ...range, branchId } });
  return res.data.data;
}

// ---- CSV export (UC-29/41/82) ----

/** Downloads a CSV from an export endpoint and triggers a browser save. */
export async function downloadCsv(path: string, params: Record<string, unknown>, filename: string): Promise<void> {
  const res = await apiClient.get(path, { params, responseType: 'blob' });
  const url = URL.createObjectURL(res.data as Blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// ---- Formatting helpers ----

export const formatVnd = (n: number): string => `${Math.round(n).toLocaleString('vi-VN')} ₫`;
export const formatPoints = (n: number): string => `${Math.round(n).toLocaleString('vi-VN')} điểm`;
export const formatNum = (n: number): string => n.toLocaleString('vi-VN');

// ---- Role gating (mirrors backend @PreAuthorize) ----

const HQ: Role[] = ['CEOVIEWER', 'BUSINESSADMIN', 'SSADMIN'];
const HQ_OR_SM: Role[] = [...HQ, 'STORE_MANAGER'];

export interface ReportMeta {
  path: string;
  title: string;
  desc: string;
  roles: Role[];
}

/** The reports catalogue with the roles allowed to open each (matches the controller). */
export const REPORTS: ReportMeta[] = [
  { path: '/reports/hq-consolidated', title: 'Doanh thu hợp nhất (HQ)', desc: 'Tổng doanh thu chuỗi, so sánh chi nhánh, bán chạy (UC-28/29)', roles: HQ },
  { path: '/reports/store-revenue', title: 'Doanh thu cửa hàng', desc: 'Doanh thu & đối soát quỹ theo chi nhánh (UC-40/41)', roles: ['STORE_MANAGER'] },
  { path: '/reports/cogs', title: 'Giá vốn & Hao hụt', desc: 'Biên lợi nhuận theo món + hao hụt nguyên liệu (UC-76)', roles: HQ_OR_SM },
  { path: '/reports/change-history', title: 'Lịch sử đổi giá / voucher', desc: 'Nhật ký thay đổi giá & voucher (UC-77)', roles: HQ },
  { path: '/reports/loyalty-liability', title: 'Nợ điểm thưởng', desc: 'Điểm tồn & biến động kỳ (UC-78)', roles: HQ },
  { path: '/reports/labour', title: 'Năng suất lao động', desc: 'Giờ công vs doanh thu theo chi nhánh (UC-79)', roles: HQ_OR_SM },
  { path: '/reports/z-report', title: 'Z-Report ngày', desc: 'Tổng kết cuối ngày theo chi nhánh (UC-81)', roles: HQ_OR_SM },
  { path: '/reports/anomaly', title: 'Bất thường hủy/hoàn', desc: 'Tỉ lệ hủy/hoàn theo thu ngân (UC-82)', roles: HQ_OR_SM },
  { path: '/reports/access-review', title: 'Rà soát truy cập', desc: 'Nhật ký thay đổi tài khoản (UC-83)', roles: ['CEOVIEWER', 'SSADMIN'] },
];

export const canAccess = (meta: ReportMeta, role: Role | undefined): boolean =>
  role !== undefined && meta.roles.includes(role);
