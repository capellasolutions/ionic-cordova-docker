import { defineConfig } from 'vitest/config';

// Ionic ships ESM that uses directory imports (e.g. `@ionic/core/components`),
// which Node's ESM resolver rejects when Vitest externalizes them. Inlining the
// Ionic packages lets Vite transform/resolve them instead, so component specs
// that import Ionic standalone components run under jsdom.
export default defineConfig({
  test: {
    server: {
      deps: {
        inline: [/@ionic\/angular/, /@ionic\/core/, /ionicons/],
      },
    },
  },
});
