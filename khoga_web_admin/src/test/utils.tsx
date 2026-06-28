import { render } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import type { ReactElement, ReactNode } from 'react';
import { AuthProvider } from '../auth/AuthContext';

interface RenderOptions {
  /** Initial URL the MemoryRouter starts at. */
  route?: string;
  /**
   * Route pattern the `ui` is mounted under. Defaults to the literal `route`,
   * which is enough for pages that don't read params. Pass e.g. '/profile/:id'
   * when the page uses useParams().
   */
  path?: string;
}

/**
 * Renders a page wrapped in the same providers the real app uses (router +
 * auth), so tests exercise real code paths. AuthProvider fetches GET /profile
 * on mount — MSW handlers must answer it (see test/handlers.ts).
 */
export function renderWithProviders(ui: ReactElement, options: RenderOptions = {}) {
  const { route = '/', path } = options;
  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>
        {path ? (
          <Routes>
            <Route path={path} element={ui} />
          </Routes>
        ) : (
          ui
        )}
      </AuthProvider>
    </MemoryRouter>,
  );
}

/** Bare provider wrapper for rendering arbitrary trees (e.g. full <App/>). */
export function Providers({ children, route = '/' }: { children: ReactNode; route?: string }) {
  return (
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>{children}</AuthProvider>
    </MemoryRouter>
  );
}
