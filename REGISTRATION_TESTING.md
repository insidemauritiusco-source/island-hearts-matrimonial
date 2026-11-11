# Island Hearts — email signup and moderation testing

The development branch is NOT production ready. Do not merge or publish the member portal until every test passes.

## Email authentication
1. Check Email provider and "Confirm email" in the Supabase dashboard:
   https://supabase.com/dashboard/project/eqzomyybqrfojjbfutrn/auth/providers
2. Configure the exact trusted staging URL under:
   https://supabase.com/dashboard/project/eqzomyybqrfojjbfutrn/auth/url-configuration
3. Configure trusted SMTP before public use.
4. Use only an authorized test account to test signup, confirmation, pre-confirmation login rejection, login, logout, password reset, and resend rate limits.
5. Do not claim the test passed until it has actually been run.

## Review and approval workflow
- Member-submitted profile defaults to pending and hidden.
- Authenticated clients have no profile UPDATE policy and cannot approve themselves.
- Moderation audit log and admin roster have no client grants.
- A human moderator can review pending profiles in the trusted SQL editor:
  `select user_id,display_name,age,city from public.ih_profiles where approval_status='pending';`
- Moderation decisions must be performed by authorized staff through a secure, audited server-side workflow. A working admin panel is not yet implemented. Do not issue service_role or secret keys to the client.

## Security checklist
- Anonymous callers are refused access to all Island Hearts tables.
- Users cannot read or change another member's pending profile.
- Users cannot approve themselves or edit approval status.
- Users cannot read private messages without an accepted connection.
- Blocks prevent discovery and communication.
- Reports are private to the author and staff.
- Verify actual multi-account RLS behaviour before launch.
- Add age validation beyond self-attestation, content moderation, consent, privacy notices, deletion/export processes, rate limiting, and private photo storage.

## Current limitations
Database tables and restrictive RLS were installed. Email settings cannot be inspected or modified through the currently available Supabase tools. No real email confirmation flow has been tested. The public GitHub Pages main branch remains an unchanged demo.
