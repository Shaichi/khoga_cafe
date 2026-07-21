import { describe, it, expect } from 'vitest';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http } from 'msw';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import CentralSettings from './CentralSettings';

const CONFIGS = [
  { key: 'VAT_RATE', value: '10', updatedBy: 'seed', updatedAt: null },
  { key: 'LOYALTY_ACCRUAL_PERCENTAGE', value: '5', updatedBy: 'seed', updatedAt: null },
];

// Screen 24 — "Cấu Hình & Bảo Mật Hệ Thống" (central config card, UC-24).
describe('CentralSettings (24 · Cấu hình hệ thống)', () => {
  it('hiển thị giá trị cấu hình hiện tại từ backend', async () => {
    server.use(http.get('/api/v1/system-config', () => ok(CONFIGS)));

    renderWithProviders(<CentralSettings />, { route: '/settings' });

    expect(await screen.findByDisplayValue('10')).toBeInTheDocument();
    expect(screen.getByDisplayValue('5')).toBeInTheDocument();
    // Friendly label for a known key, not the raw enum.
    expect(screen.getByText(/thuế vat/i)).toBeInTheDocument();
  });

  it('chỉ lưu (PUT) những khóa đã thay đổi', async () => {
    const puts: Record<string, string> = {};
    server.use(
      http.get('/api/v1/system-config', () => ok(CONFIGS)),
      http.put('/api/v1/system-config/:key', async ({ params, request }) => {
        const body = (await request.json()) as { value: string };
        puts[params.key as string] = body.value;
        return ok({ key: params.key, value: body.value, updatedBy: 'u', updatedAt: null });
      }),
    );
    const user = userEvent.setup();
    renderWithProviders(<CentralSettings />, { route: '/settings' });

    const vat = await screen.findByDisplayValue('10');
    await user.clear(vat);
    await user.type(vat, '12');
    await user.click(screen.getByRole('button', { name: /lưu cấu hình/i }));

    await waitFor(() => expect(puts.VAT_RATE).toBe('12'));
    // Untouched key must NOT be re-sent.
    expect(puts.LOYALTY_ACCRUAL_PERCENTAGE).toBeUndefined();
  });
});
