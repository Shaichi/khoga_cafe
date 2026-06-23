import axios from 'axios';

/**
 * Single axios instance for the whole app.
 *
 * - baseURL is relative (`/api/v1`) so requests go through the Vite dev proxy
 *   (see vite.config.ts) and stay same-origin.
 * - withCredentials sends/receives the HttpOnly `khoga_token` cookie issued by
 *   the backend on login. We never read the JWT in JS — the cookie carries it.
 */
export const apiClient = axios.create({
  baseURL: '/api/v1',
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
});

/** Pull the human-readable message out of a backend ApiResponse error, with a fallback. */
export function errorMessage(err: unknown, fallback = 'Đã có lỗi xảy ra'): string {
  if (axios.isAxiosError(err)) {
    return err.response?.data?.message ?? err.message ?? fallback;
  }
  return fallback;
}
