# Subscription Admin — Prod Operations

Skill for managing subscriptions in production via the admin tRPC API at `api.diane.app`.

## Prerequisites

- `ADMIN_API_KEY` env var must be set (or known — ask the user)
- Production API is at `https://api.diane.app`
- tRPC endpoint: `https://api.diane.app/trpc`
- All admin endpoints require `x-admin-key` header

## Available Operations

### 1. Find User by Email

Use `mcp__postgres-prod__query` to find a user ID from an email:

```sql
SELECT id, email, name, created_at FROM "user" WHERE email = 'user@example.com';
```

### 2. Check Current Subscription

```sql
SELECT s.*,
  COALESCE(SUM(sa.adjustment_days), 0) as total_bonus_days
FROM subscriptions s
LEFT JOIN subscription_adjustments sa ON sa.subscription_id = s.id
WHERE s.user_id = '<USER_ID>'
GROUP BY s.id
ORDER BY CASE WHEN s.status IN ('active', 'trialing') THEN 0 ELSE 1 END, s.created_at DESC
LIMIT 1;
```

### 3. Extend Subscription (add free days)

```bash
curl -s -X POST "https://api.diane.app/trpc/admin.extendSubscription" \
  -H "Content-Type: application/json" \
  -H "x-admin-key: ${ADMIN_API_KEY}" \
  -d '{"userId":"<USER_ID>","days":<DAYS>,"reason":"<REASON>","adminNote":"<NOTE>"}'
```

**Reasons**: `referral`, `bug_compensation`, `manual`, `promotion`
**Days**: 1-365

This also syncs with RevenueCat (grants a promotional entitlement).

### 4. Create/Update Subscription

```bash
curl -s -X POST "https://api.diane.app/trpc/admin.upsertSubscription" \
  -H "Content-Type: application/json" \
  -H "x-admin-key: ${ADMIN_API_KEY}" \
  -d '{
    "userId": "<USER_ID>",
    "status": "active",
    "plan": "monthly",
    "source": "admin_manual"
  }'
```

**Statuses**: `active`, `trialing`, `canceled`, `past_due`, `paused`
**Plans**: `free`, `monthly`, `quarterly`, `annual`

### 5. View Adjustment History

```bash
curl -s "https://api.diane.app/trpc/admin.listAdjustments?input=%7B%22userId%22%3A%22<USER_ID>%22%7D" \
  -H "x-admin-key: ${ADMIN_API_KEY}"
```

### 6. Batch Upsert (up to 500)

```bash
curl -s -X POST "https://api.diane.app/trpc/admin.batchUpsertSubscriptions" \
  -H "Content-Type: application/json" \
  -H "x-admin-key: ${ADMIN_API_KEY}" \
  -d '{"subscriptions":[{"userId":"<ID>","status":"active","plan":"annual"}]}'
```

## Workflow: Give Free Days to a User

1. Ask user for: **email**, **number of days**, **reason**
2. Look up user ID via prod DB: `SELECT id FROM "user" WHERE email = '...'`
3. Check current subscription status via prod DB
4. If no subscription exists: use `upsertSubscription` to create one first (status: active, plan: monthly, source: admin_manual)
5. Call `extendSubscription` with the user ID, days, reason, and a descriptive admin note
6. Verify via prod DB that `current_period_end` was updated and `subscription_adjustments` row was created
7. Report the new expiration date to the admin

## Workflow: Activate Pro for a User (no payment)

1. Look up user ID
2. Call `upsertSubscription` with status=active, plan=annual (or monthly), source=admin_manual
3. Then call `extendSubscription` with desired days + reason

## tRPC Request Format Note

tRPC mutations use POST with JSON body directly (not wrapped in `input`).
tRPC queries use GET with `input` as URL-encoded JSON query param.

The `x-admin-key` header is validated by the `adminProcedure` middleware — it must match the `ADMIN_API_KEY` env var on the server.

## Safety

- Always confirm user email + ID before making changes
- Always check current subscription state before modifying
- Always include a descriptive `adminNote` for audit trail
- Extension syncs with RevenueCat automatically (promotional entitlement)
