import { apiClient } from './client';
import type { ApiResponse, PageResponse } from './types';

export type OrderStatus = 'PENDING' | 'PREPARING' | 'HOLD' | 'READY' | 'COMPLETED' | 'CANCELLED' | 'ABANDONED';
export type Tier = 'BRONZE' | 'SILVER' | 'GOLD';

export interface Customer {
  id: string;
  phone: string;
  fullName: string;
  email: string | null;
  points: number | null;
  birthDate: string | null;
  isActive: boolean | null;
  consentAt: string | null;
  consentVersion: string | null;
}

export interface CreateCustomerInput {
  phone: string;
  fullName: string;
  email?: string;
  birthDate?: string | null;
  consentVersion: string; // PDPA — BR-71
}
export interface UpdateCustomerInput {
  fullName?: string;
  email?: string;
  birthDate?: string | null;
}
export interface PointAdjustmentInput {
  delta: number;
  reason: string; // BR-49 — mandatory
}

/** Thin projection for a customer's purchase history (UC-27). */
export interface CustomerOrderEntry {
  orderId: string;
  orderNumber: string;
  total: number;
  status: OrderStatus;
  createdAt: string;
}

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING: 'Chờ xử lý',
  PREPARING: 'Đang pha chế',
  HOLD: 'Tạm giữ',
  READY: 'Sẵn sàng',
  COMPLETED: 'Hoàn thành',
  CANCELLED: 'Đã hủy',
  ABANDONED: 'Bỏ dở',
};

// Membership tier is a display-only heuristic derived from points — the backend
// does not model tiers. Thresholds chosen to match the Figma sample data.
export function tierFromPoints(points: number | null): Tier {
  const p = points ?? 0;
  if (p >= 300) return 'GOLD';
  if (p >= 100) return 'SILVER';
  return 'BRONZE';
}

export const CONSENT_VERSION = 'v1.0';

export async function listCustomers(search?: string): Promise<Customer[]> {
  const params: Record<string, unknown> = { size: 100 };
  if (search && search.trim()) params.search = search.trim();
  const res = await apiClient.get<ApiResponse<PageResponse<Customer>>>('/customers', { params });
  return res.data.data.content;
}
export async function getCustomer(id: string): Promise<Customer> {
  const res = await apiClient.get<ApiResponse<Customer>>(`/customers/${id}`);
  return res.data.data;
}
export async function getCustomerHistory(id: string): Promise<CustomerOrderEntry[]> {
  const res = await apiClient.get<ApiResponse<CustomerOrderEntry[]>>(`/customers/${id}/history`);
  return res.data.data;
}
export async function createCustomer(input: CreateCustomerInput): Promise<Customer> {
  const res = await apiClient.post<ApiResponse<Customer>>('/customers', input);
  return res.data.data;
}
export async function updateCustomer(id: string, input: UpdateCustomerInput): Promise<Customer> {
  const res = await apiClient.put<ApiResponse<Customer>>(`/customers/${id}`, input);
  return res.data.data;
}
export interface PointLogEntry {
  id: string;
  createdAt?: string;
  date: string;
  type: string;
  pointsDelta: number;
  reason: string;
  performedBy: string;
}

export async function getCustomerPointLogs(id: string): Promise<PointLogEntry[]> {
  const res = await apiClient.get<ApiResponse<PointLogEntry[]>>(`/customers/${id}/point-logs`);
  return res.data.data;
}

export async function adjustPoints(id: string, input: PointAdjustmentInput): Promise<Customer> {
  const res = await apiClient.post<ApiResponse<Customer>>(`/customers/${id}/points`, input);
  return res.data.data;
}
