# AGENTS.md — Efficient-Labs commercial layer rules

You are operating inside `Efficient-Labs/` — the commercial front, SaaS landing pages, marketing assets, and public integrations.

## Identity
- This workspace contains public marketing, SaaS frontend, and Stripe integration code.
- Conflicting rules defer to: Claude Code → `CLAUDE.md`; Antigravity → `GEMINI.md`.

## Hard rules
- **No Secrets**: Never commit live Stripe keys, OAuth client secrets, or database URLs. All secrets belong in `.env.local` (gated and off-limits to git).
- **Aesthetic Excellence**: All UI edits must respect the modern CSS tokens in `styles/theme.css`. Maintain rich aesthetics (gradients, smooth animations, Google typography).
- **PR Gating**: All changes must land via PR. Operator review is required for payment endpoints and marketing landing page copies.
- **Verification**: Run local build test `npm run build` to verify production compiling before any push.
- **Sign Commits**: Ensure all commits are co-authored by your active agent name (e.g. `Co-Authored-By: Antigravity (Gemini 3.x) <noreply@google.com>`).

