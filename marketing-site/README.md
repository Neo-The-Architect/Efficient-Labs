# Efficient Labs Marketing Site

Local-only Astro scaffold for the Efficient Labs public website.

## Commands

```bash
npm install
npm run dev
npm run build
npm run preview
```

## Launch Boundary

This scaffold does not deploy anything, create spend, add analytics, connect Stripe live mode, or publish public forms.

- Waitlist form is visually present but non-live.
- Audit order CTA is visually present but non-live.
- Public DNS, Cloudflare Pages, Stripe, and launch announcements require explicit operator approval.

## Pre-Launch Indexing

`public/robots.txt` intentionally disallows crawling while the site is local/pre-launch. Remove or relax this only during the explicit public launch gate.
