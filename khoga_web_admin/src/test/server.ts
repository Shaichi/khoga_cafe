import { setupServer } from 'msw/node';
import { handlers } from './handlers';

/** Shared MSW server for the whole test suite (lifecycle wired in setup.ts). */
export const server = setupServer(...handlers);
