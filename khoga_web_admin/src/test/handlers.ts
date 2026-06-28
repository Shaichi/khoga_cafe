import { http, HttpResponse } from 'msw';
import type { Profile } from '../api/types';

/**
 * Default authenticated user returned by GET /profile. Every render that mounts
 * <AuthProvider> triggers this call, so a baseline handler must always exist;
 * individual tests override behaviour with `server.use(...)`.
 */
export const defaultProfile: Profile = {
  id: 'u-1',
  username: 'ssadmin',
  fullName: 'Nguyễn Văn Quản',
  email: 'admin@khoga.vn',
  phone: '0901234567',
  role: 'SSADMIN',
  storeId: null,
};

/** Wrap data in the backend's standard ApiResponse envelope. */
export function ok<T>(data: T, message = 'ok') {
  return HttpResponse.json({ status: 'success', message, data });
}

export const handlers = [
  http.get('/api/v1/profile', () => ok(defaultProfile)),
];
