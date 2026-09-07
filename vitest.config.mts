import { defineConfig } from 'vitest/config';

// Scoped to the plugin's own src/ -- examples/ and test-app/ have their own package.json,
// deps, and test setup and are not part of this workspace.
export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
  },
});
