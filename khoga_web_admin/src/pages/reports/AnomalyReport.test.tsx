import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { http } from 'msw';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import AnomalyReport from './AnomalyReport';

describe('AnomalyReport (UC-82)', () => {
  it('lists per-cashier activity and flags those above the threshold', async () => {
    server.use(
      http.get('/api/v1/reports/anomaly', () =>
        ok({
          from: '2026-05-01', to: '2026-05-31', branchId: null, thresholdPercent: 5,
          cashiers: [
            { cashierId: 'c1', cashierName: 'An', orders: 612, cancellations: 8, cancelRate: 1.3, refunds: 3, refundRate: 0.5, vouchers: 41, comps: 2, flagged: false },
            { cashierId: 'c2', cashierName: 'Binh', orders: 470, cancellations: 39, cancelRate: 8.3, refunds: 17, refundRate: 3.6, vouchers: 88, comps: 9, flagged: true },
          ],
        }),
      ),
    );

    renderWithProviders(<AnomalyReport />, { route: '/reports/anomaly' });

    expect(await screen.findByText('An')).toBeInTheDocument();
    expect(screen.getByText('Binh')).toBeInTheDocument();
    expect(screen.getAllByText('⚠ Cao')).toHaveLength(1); // only Binh flagged
  });
});
