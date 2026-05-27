import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  output: 'static',
  site: 'https://efficientlabs.ai',
  integrations: [
    sitemap({
      // Exclude form-flow / error pages from the sitemap — they're not
      // discovery surfaces.
      filter: (page) =>
        !page.includes('/audit/thank-you') &&
        !page.includes('/audit/cancelled') &&
        !page.includes('/404'),
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
    }),
  ],
});

