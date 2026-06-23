import { apiClient } from './client';
import type { ApiResponse, PageResponse } from './types';

export type DiscountType = 'PERCENTAGE' | 'FIXED_AMOUNT';
export type VoucherStatus = 'SCHEDULED' | 'ACTIVE' | 'EXPIRED' | 'INACTIVE';

export interface Voucher {
  id: string;
  code: string;
  discountType: DiscountType;
  discountValue: number;
  minOrderValue: number | null;
  startDate: string | null;
  endDate: string | null;
  maxDiscountAmount: number | null;
  usageLimitPerCustomer: number | null;
  maxTotalUses: number | null;
  totalUsageCount: number | null;
  status: VoucherStatus;
}

export interface CreateVoucherInput {
  code: string;
  discountType: DiscountType;
  discountValue: number;
  minOrderValue?: number | null;
  startDate?: string | null;
  endDate?: string | null;
  maxDiscountAmount?: number | null;
  usageLimitPerCustomer?: number | null;
  maxTotalUses?: number | null;
}

// {@code code} is intentionally absent — it is immutable (BR-40/UC-22).
export interface UpdateVoucherInput {
  discountType: DiscountType;
  discountValue: number;
  minOrderValue?: number | null;
  startDate?: string | null;
  endDate?: string | null;
  maxDiscountAmount?: number | null;
  usageLimitPerCustomer?: number | null;
  maxTotalUses?: number | null;
  active?: boolean;
}

export const DISCOUNT_TYPE_LABELS: Record<DiscountType, string> = {
  PERCENTAGE: 'Giảm theo phần trăm (%)',
  FIXED_AMOUNT: 'Số tiền mặt cố định',
};

export const VOUCHER_STATUS_LABELS: Record<VoucherStatus, string> = {
  SCHEDULED: 'Lên lịch',
  ACTIVE: 'Đang áp dụng',
  EXPIRED: 'Hết hạn',
  INACTIVE: 'Vô hiệu',
};

export async function listVouchers(): Promise<Voucher[]> {
  const res = await apiClient.get<ApiResponse<PageResponse<Voucher>>>('/vouchers', { params: { size: 100 } });
  return res.data.data.content;
}
export async function getVoucher(id: string): Promise<Voucher> {
  const res = await apiClient.get<ApiResponse<Voucher>>(`/vouchers/${id}`);
  return res.data.data;
}
export async function createVoucher(input: CreateVoucherInput): Promise<Voucher> {
  const res = await apiClient.post<ApiResponse<Voucher>>('/vouchers', input);
  return res.data.data;
}
export async function updateVoucher(id: string, input: UpdateVoucherInput): Promise<Voucher> {
  const res = await apiClient.put<ApiResponse<Voucher>>(`/vouchers/${id}`, input);
  return res.data.data;
}
export async function deactivateVoucher(id: string): Promise<void> {
  await apiClient.post(`/vouchers/${id}/deactivate`);
}
