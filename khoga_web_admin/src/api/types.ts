// Mirrors the backend DTOs (com.khoga.*). Keep in sync with the Java records.

export type Role = 'CASHIER' | 'BARISTA' | 'STORE_MANAGER' | 'BUSINESSADMIN' | 'SSADMIN';

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
  token: string;
  role: Role;
  mustChangePassword: boolean;
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
  BUSINESSADMIN: 'Quản trị kinh doanh',
  SSADMIN: 'Quản trị hệ thống',
};
