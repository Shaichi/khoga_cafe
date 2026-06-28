import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { Routes, Route } from 'react-router-dom';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { defaultProfile, ok } from '../../test/handlers';
import ProfileEdit from './ProfileEdit';

function renderEdit() {
  return renderWithProviders(
    <Routes>
      <Route path="/profile/edit" element={<ProfileEdit />} />
      <Route path="/profile" element={<div>TRANG HỒ SƠ</div>} />
    </Routes>,
    { route: '/profile/edit' },
  );
}

// Screen 07 — "Chỉnh sửa thông tin". Only email + phone are editable (BR-19).
describe('ProfileEdit (07 · Chỉnh sửa thông tin)', () => {
  it('điền sẵn email/SĐT hiện tại rồi lưu thay đổi qua PUT /profile', async () => {
    let received: { email: string; phone: string } | null = null;
    server.use(
      http.put('/api/v1/profile', async ({ request }) => {
        received = (await request.json()) as { email: string; phone: string };
        return ok({ ...defaultProfile, email: received.email, phone: received.phone });
      }),
    );
    const user = userEvent.setup();
    renderEdit();

    // Wait for the async prefill (AuthProvider load -> effect) to settle.
    await screen.findByDisplayValue('admin@khoga.vn');
    const email = screen.getByLabelText('Email');
    expect(screen.getByLabelText(/số điện thoại/i)).toHaveValue('0901234567');

    await user.clear(email);
    await user.type(email, 'moi@khoga.vn');
    await user.click(screen.getByRole('button', { name: /lưu/i }));

    // Navigates back to the profile view on success.
    expect(await screen.findByText('TRANG HỒ SƠ')).toBeInTheDocument();
    expect(received).toEqual({ email: 'moi@khoga.vn', phone: '0901234567' });
  });

  it('chặn lưu khi số điện thoại sai định dạng', async () => {
    let called = false;
    server.use(
      http.put('/api/v1/profile', () => {
        called = true;
        return ok(defaultProfile);
      }),
    );
    const user = userEvent.setup();
    renderEdit();

    const phone = await screen.findByLabelText(/số điện thoại/i);
    await user.clear(phone);
    await user.type(phone, '123'); // too short
    await user.click(screen.getByRole('button', { name: /lưu/i }));

    expect(await screen.findByText(/10–12 chữ số/i)).toBeInTheDocument();
    expect(called).toBe(false);
  });
});
