import { apiClient } from './client';
import type { ApiResponse, LoginResponse, Profile } from './types';

export async function login(username: string, password: string): Promise<LoginResponse> {
  const res = await apiClient.post<ApiResponse<LoginResponse>>('/auth/login', { username, password });
  return res.data.data;
}

export async function logout(): Promise<void> {
  await apiClient.post('/auth/logout');
}

export async function getProfile(): Promise<Profile> {
  const res = await apiClient.get<ApiResponse<Profile>>('/profile');
  return res.data.data;
}

/** UC-08 (BR-19): self-service edit of contact fields only (email + phone). */
export async function updateProfile(input: { email: string; phone: string }): Promise<Profile> {
  const res = await apiClient.put<ApiResponse<Profile>>('/profile', input);
  return res.data.data;
}

/** UC-06: first-login forced change. Returns a fresh session (cookie re-issued by backend). */
export async function forcePasswordChange(newPassword: string): Promise<LoginResponse> {
  const res = await apiClient.post<ApiResponse<LoginResponse>>('/auth/force-password-change', { newPassword });
  return res.data.data;
}

/** UC-09: change password while logged in. */
export async function changePassword(currentPassword: string, newPassword: string): Promise<void> {
  await apiClient.post('/auth/change-password', { currentPassword, newPassword });
}
