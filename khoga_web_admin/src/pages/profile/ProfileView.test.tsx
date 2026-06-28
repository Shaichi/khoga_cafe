import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from '../../test/utils';
import ProfileView from './ProfileView';

// Screen 06 — "Thông Tin Cá Nhân". Shows the signed-in user (from AuthProvider,
// which MSW answers via GET /profile with `defaultProfile`).
describe('ProfileView (06 · Thông tin cá nhân)', () => {
  it('hiển thị thông tin của người dùng đang đăng nhập', async () => {
    renderWithProviders(<ProfileView />, { route: '/profile' });

    expect(await screen.findByText('Nguyễn Văn Quản')).toBeInTheDocument();
    expect(screen.getByText('ssadmin')).toBeInTheDocument();
    expect(screen.getByText('admin@khoga.vn')).toBeInTheDocument();
    expect(screen.getByText('0901234567')).toBeInTheDocument();
    // Role rendered via ROLE_LABELS, not the raw enum.
    expect(screen.getByText('Quản trị hệ thống')).toBeInTheDocument();
  });

  it('có lối tới Chỉnh sửa thông tin và Đổi mật khẩu', async () => {
    renderWithProviders(<ProfileView />, { route: '/profile' });

    expect(await screen.findByRole('link', { name: /chỉnh sửa thông tin/i })).toHaveAttribute(
      'href',
      '/profile/edit',
    );
    expect(screen.getByRole('link', { name: /đổi mật khẩu/i })).toHaveAttribute(
      'href',
      '/profile/password',
    );
    expect(screen.getByRole('button', { name: /đăng xuất/i })).toBeInTheDocument();
  });
});
