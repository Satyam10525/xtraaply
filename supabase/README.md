# Supabase Setup

This folder contains the first backend foundation for the Xtraaplywood project.

## Files

- `schema.sql`
  Creates the database tables, helper functions, redemption logic, and row-level security policies.
- `seed.sql`
  Inserts starter categories, products, variants, rewards, and a few demo QR codes for local testing.

## Suggested setup order

1. Create a new Supabase project.
2. In the Supabase dashboard, open the SQL editor.
3. Run [`schema.sql`](C:/Users/KIIT/xtraaplywood/supabase/schema.sql).
4. Run [`seed.sql`](C:/Users/KIIT/xtraaplywood/supabase/seed.sql).
5. In Authentication:
   - enable email/password auth
   - optionally disable social providers for now
6. Replace the demo QR codes in `seed.sql` with your real printed codes before launch.

## What this schema gives you

- User profiles linked to Supabase Auth
- Product catalog tables
- QR code table with one-time redemption
- Point transaction ledger
- Reward claim workflow
- Enquiry storage
- RLS policies for public vs authenticated vs admin access

## Important implementation note

The browser should **not** write directly to `qr_codes` or manually update point balances.

Use these SQL functions instead:

- `public.redeem_qr_code(input_code text)`
- `public.claim_reward(input_reward_id uuid)`

These keep the data changes consistent and reduce abuse risk.

## Next coding steps

1. Add Supabase client setup to the frontend.
2. Replace the demo auth flow in `login.html`.
3. Replace fake enquiry submission in `contact.html`.
4. Replace demo rewards data in `rewards.html`.
5. Replace hardcoded products in `products.html` with database reads.

## Recommended admin workflow for now

Skip building an admin panel initially.

Use the Supabase dashboard to manage:
- products
- rewards
- QR codes
- enquiries
- reward claims

That will save time and get the full project finished faster.
