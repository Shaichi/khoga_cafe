import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { http } from 'msw';
import { renderWithProviders } from '../../test/utils';
import { server } from '../../test/server';
import { ok } from '../../test/handlers';
import CogsReport from './CogsReport';

describe('CogsReport (UC-76)', () => {
  it('shows per-item margin and flags abnormal ingredient shrinkage', async () => {
    server.use(
      http.get('/api/v1/reports/cogs', () =>
        ok({
          from: '2026-05-01', to: '2026-05-31', storeId: null,
          margins: [{ itemId: 'm1', name: 'Espresso', kind: 'ITEM', price: 30000, cogs: 8500, margin: 21500, marginPercent: 72 }],
          shrinkage: [
            { rawMaterialId: 'r1', name: 'Fresh Milk', unit: 'L', theoretical: 120, actualUsage: 131.5, variance: -11.5, lossValue: 230000, flagged: true },
            { rawMaterialId: 'r2', name: 'Coffee Beans', unit: 'kg', theoretical: 18, actualUsage: 18.4, variance: -0.4, lossValue: 60000, flagged: false },
          ],
        }),
      ),
    );

    renderWithProviders(<CogsReport />, { route: '/reports/cogs' });

    expect(await screen.findByText('Espresso')).toBeInTheDocument();
    expect(screen.getByText(/Fresh Milk/)).toBeInTheDocument();
    expect(screen.getByText(/Coffee Beans/)).toBeInTheDocument();
    // exactly one row flagged (Fresh Milk at ~9.6%, Coffee Beans at ~2.2% not flagged)
    expect(screen.getAllByText('⚠ Bất thường')).toHaveLength(1);
  });
});
