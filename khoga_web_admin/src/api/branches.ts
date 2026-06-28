import { apiClient } from './client';
import type { ApiResponse, PageResponse } from './types';

/** com.khoga.branch.dto.BranchResponse */
export interface Branch {
  id: string;
  name: string;
  address: string;
  phone: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

/** Create/UpdateBranchRequest — name/address required, phone 10–12 digits. */
export interface BranchInput {
  name: string;
  address: string;
  phone: string;
}

// A coffee chain caps active branches (MAX_ACTIVE_BRANCHES, default 10), so one
// page of 100 comfortably holds the whole list — filtering/search done client-side.
export async function listBranches(active?: boolean): Promise<Branch[]> {
  const params: Record<string, unknown> = { size: 100 };
  if (active !== undefined) params.active = active;
  const res = await apiClient.get<ApiResponse<PageResponse<Branch>>>('/branches', { params });
  return res.data.data.content;
}

export async function getBranch(id: string): Promise<Branch> {
  const res = await apiClient.get<ApiResponse<Branch>>(`/branches/${id}`);
  return res.data.data;
}

export async function createBranch(input: BranchInput): Promise<Branch> {
  const res = await apiClient.post<ApiResponse<Branch>>('/branches', input);
  return res.data.data;
}

export async function updateBranch(id: string, input: BranchInput): Promise<Branch> {
  const res = await apiClient.put<ApiResponse<Branch>>(`/branches/${id}`, input);
  return res.data.data;
}

export async function deactivateBranch(id: string): Promise<void> {
  await apiClient.post(`/branches/${id}/deactivate`);
}

/** com.khoga.branch.dto.BranchSettingsResponse — branch-scoped operational settings (UC-42). */
export interface BranchSettings {
  timezone: string | null;
  printerAddress: string | null;
}

export async function getBranchSettings(id: string): Promise<BranchSettings> {
  const res = await apiClient.get<ApiResponse<BranchSettings>>(`/branches/${id}/settings`);
  return res.data.data;
}

export async function updateBranchSettings(id: string, input: BranchSettings): Promise<void> {
  await apiClient.put(`/branches/${id}/settings`, input);
}
