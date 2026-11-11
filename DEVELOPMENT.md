# Island Hearts — Secure Member Platform (development branch)
The main branch is the existing LIVE **demo**, with fictional profiles. This development branch is **not production-ready**.

## Backend separation
Use a **new dedicated Supabase project**; do not apply the SQL to LinkBook or Virelo. Create it only after reviewing pricing. `database/schema.sql` is a deliberately restrictive security foundation; do not execute it until reviewed and tested on a separate project.

## Planned public functionality
- Adult-only (18+) account signup and email confirmation, plus age verification strategy
- Member profile creation and moderated approval
- Search approved profiles without publishing email or private details
- Connections require invitation and acceptance before messaging
- User block and abuse report
- Private photo bucket with moderation and per-user RLS; never make uploaded identity documents public
- Admin review dashboard on **server-side only** with audited admin assignment
- Rate limiting, consent, privacy policy, deletion requests, and safety procedures

## Incomplete / intentionally locked down
- No live signup or backend credentials yet
- Profile changes, moderation approvals, accepting invitations, and admin access require trusted backend endpoints.
- Storage setup, private photo processing, consent, anti-spam and age verification pending.
- Before production: add automated RLS negative tests, moderation abuse tests, account-deletion flow, accessibility and mobile testing.

## Deployment
GitHub Pages publishes only the default `main` branch right now. **Do not merge this branch until tested**. Do not put Supabase service role keys, database passwords or private user data in GitHub.
