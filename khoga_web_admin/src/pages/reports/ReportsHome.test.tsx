import { describe, it, expect } from 'vitest';
import { screen } from '@testing-library/react';
import { renderWithProviders } from '../../test/utils';
import ReportsHome from './ReportsHome';

// Default profile is SSADMIN (HQ). Store-revenue is STORE_MANAGER-only, so it must be hidden.
describe('ReportsHome (role-gated catalogue)', () => {
  it('shows HQ reports for an HQ role and hides the SM-only report', async () => {
    renderWithProviders(<ReportsHome />, { route: '/reports' });

    expect(await screen.findByText('Doanh thu hợp nhất (HQ)')).toBeInTheDocument();
    expect(screen.getByText('Rà soát truy cập')).toBeInTheDocument(); // ceoviewer/ssadmin
    expect(screen.queryByText('Doanh thu cửa hàng')).not.toBeInTheDocument(); // STORE_MANAGER only
  });
});
