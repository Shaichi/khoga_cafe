import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Dev server proxies /api -> Spring Boot (localhost:8080) so the browser sees a
// single origin. This keeps the HttpOnly `khoga_token` cookie same-origin (no CORS
// / SameSite friction during local development).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:8080', // IPv4 explicit — avoids Node resolving localhost to ::1
        changeOrigin: true,
      },
    },
  },
});
