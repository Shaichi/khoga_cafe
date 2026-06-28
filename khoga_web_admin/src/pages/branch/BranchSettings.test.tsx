import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { Routes, Route } from 'react-router-dom';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import BranchSettings from './BranchSettings';

const BRANCH = {
  id: 'b-1',
  name: 'Khoga - Nguyễn Du',
  address: '123 Nguyễn Du, Q1',
  phone: '0283930001',
  active: true,
  createdAt: null,
  updatedAt: null,
};

function renderSettings() {
  return renderWithProviders(
    <Routes>
      <Route path="/branches/:id/settings" element={<BranchSettings />} />
      <Route path="/branches" element={<div>DANH SÁCH CHI NHÁNH</div>} />
    </Routes>,
    { route: '/branches/b-1/settings' },
  );
}

// Screen 33 — "Cấu Hình Chi Nhánh (Web)" (UC-42). Read-back is via the new
// GET /branches/{id}/settings; only timezone + printer address are BE-backed.
describe('BranchSettings (33 · Cấu hình chi nhánh)', () => {
  it('điền sẵn cấu hình hiện tại của chi nhánh rồi lưu thay đổi', async () => {
    let received: { timezone: string; printerAddress: string } | null = null;
    server.use(
      http.get('/api/v1/branches/b-1', () => ok(BRANCH)),
      http.get('/api/v1/branches/b-1/settings', () =>
        ok({ timezone: 'Asia/Ho_Chi_Minh', printerAddress: '192.168.1.150' }),
      ),
      http.put('/api/v1/branches/b-1/settings', async ({ request }) => {
        received = (await request.json()) as { timezone: string; printerAddress: string };
        return ok({ ...BRANCH });
      }),
    );
    const user = userEvent.setup();
    renderSettings();

    // Branch name shown (read-only), settings prefilled.
    expect(await screen.findByDisplayValue('Khoga - Nguyễn Du')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Asia/Ho_Chi_Minh')).toBeInTheDocument();
    const printer = screen.getByDisplayValue('192.168.1.150');

    await user.clear(printer);
    await user.type(printer, '10.0.0.5');
    await user.click(screen.getByRole('button', { name: /lưu/i }));

    expect(await screen.findByText('DANH SÁCH CHI NHÁNH')).toBeInTheDocument();
    expect(received).toEqual({ timezone: 'Asia/Ho_Chi_Minh', printerAddress: '10.0.0.5' });
  });
});
