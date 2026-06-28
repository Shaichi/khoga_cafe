import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { Routes, Route } from 'react-router-dom';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import ChangePassword from './ChangePassword';

function renderPw() {
  return renderWithProviders(
    <Routes>
      <Route path="/profile/password" element={<ChangePassword />} />
      <Route path="/profile" element={<div>TRANG HỒ SƠ</div>} />
    </Routes>,
    { route: '/profile/password' },
  );
}

// Screen 08 — "Đổi Mật Khẩu" (UC-09, logged-in change).
describe('ChangePassword (08 · Đổi mật khẩu)', () => {
  it('gửi mật khẩu hiện tại + mới rồi quay lại hồ sơ', async () => {
    let received: { currentPassword: string; newPassword: string } | null = null;
    server.use(
      http.post('/api/v1/auth/change-password', async ({ request }) => {
        received = (await request.json()) as { currentPassword: string; newPassword: string };
        return ok(null);
      }),
    );
    const user = userEvent.setup();
    renderPw();

    await user.type(await screen.findByLabelText(/mật khẩu hiện tại/i), 'Old@1234');
    await user.type(screen.getByLabelText('Mật khẩu mới'), 'New@1234');
    await user.type(screen.getByLabelText(/xác nhận/i), 'New@1234');
    await user.click(screen.getByRole('button', { name: /cập nhật mật khẩu/i }));

    expect(await screen.findByText('TRANG HỒ SƠ')).toBeInTheDocument();
    expect(received).toEqual({ currentPassword: 'Old@1234', newPassword: 'New@1234' });
  });

  it('chặn gửi khi xác nhận mật khẩu không khớp', async () => {
    let called = false;
    server.use(
      http.post('/api/v1/auth/change-password', () => {
        called = true;
        return ok(null);
      }),
    );
    const user = userEvent.setup();
    renderPw();

    await user.type(await screen.findByLabelText(/mật khẩu hiện tại/i), 'Old@1234');
    await user.type(screen.getByLabelText('Mật khẩu mới'), 'New@1234');
    await user.type(screen.getByLabelText(/xác nhận/i), 'Khac@1234');
    await user.click(screen.getByRole('button', { name: /cập nhật mật khẩu/i }));

    expect(await screen.findByText(/không khớp/i)).toBeInTheDocument();
    expect(called).toBe(false);
  });
});
