import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { http } from 'msw';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import HqConsolidated from './HqConsolidated';

describe('HqConsolidated (UC-28/29)', () => {
  it('renders chain totals, branch comparison and best sellers', async () => {
    server.use(
      http.get('/api/v1/reports/hq-consolidated', () =>
        ok({
          from: '2026-05-01', to: '2026-05-31',
          totalRevenue: 450000000, totalOrders: 12500, avgTransactionValue: 36000, cancellationRate: 1.5,
          branches: [{ storeId: 's1', storeName: 'District 1', revenue: 250000000, orders: 6800 }],
          bestSellers: [{ menuItemId: 'm1', name: 'Peach Tea', quantitySold: 3400 }],
        }),
      ),
    );

    renderWithProviders(<HqConsolidated />, { route: '/reports/hq-consolidated' });

    expect(await screen.findByText('District 1')).toBeInTheDocument();
    expect(screen.getByText('Peach Tea')).toBeInTheDocument();
    expect(screen.getByText('1.5%')).toBeInTheDocument();
  });
});
