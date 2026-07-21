// Mirrors the backend DTOs (com.khoga.*). Keep in sync with the Java records.

export type Role = 'CASHIER' | 'BARISTA' | 'STORE_MANAGER' | 'CEOVIEWER' | 'BUSINESSADMIN' | 'SSADMIN';

/** Standard envelope returned by every controller (com.khoga.common.dto.ApiResponse). */
export interface ApiResponse<T> {
  status: 'success' | 'error';
  message: string;
  data: T;
  timestamp?: string;
}

/** com.khoga.common.dto.PageResponse */
export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

/** com.khoga.auth.dto.LoginResponse */
export interface LoginResponse {
  status?: string;          // 'AUTHENTICATED' | 'MFA_REQUIRED'
  token: string | null;
  role: Role | null;
  mustChangePassword: boolean;
  mfaToken?: string | null; // present only when status === 'MFA_REQUIRED'
}

/** com.khoga.auth.dto.ProfileResponse */
export interface Profile {
  id: string;
  username: string;
  fullName: string;
  email: string | null;
  phone: string | null;
  role: Role;
  storeId: string | null;
}

export const ROLE_LABELS: Record<Role, string> = {
  CASHIER: 'Thu ngân',
  BARISTA: 'Pha chế',
  STORE_MANAGER: 'Quản lý chi nhánh',
  CEOVIEWER: 'Giám đốc (chỉ xem)',
  BUSINESSADMIN: 'Quản trị kinh doanh',
  SSADMIN: 'Quản trị hệ thống',
};
