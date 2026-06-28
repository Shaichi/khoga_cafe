import { defineConfig } from 'vitest/config';

// Test-only config (kept separate from vite.config.ts to avoid the
// vite-vs-vitest-bundled-vite plugin type clash). No @vitejs/plugin-react here:
// it only adds Fast Refresh, which tests don't need — esbuild's automatic JSX
// runtime is enough to transform .tsx files.
export default defineConfig({
  esbuild: { jsx: 'automatic' },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: false,
    // Fixed jsdom origin so MSW relative-path handlers resolve deterministically.
    environmentOptions: { jsdom: { url: 'http://localhost:5173' } },
  },
});
