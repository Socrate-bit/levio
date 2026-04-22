# Realtime Architecture

## Principle

HTTP queries are **only** used at startup to seed initial state. All subsequent mutations and state changes MUST flow through the **realtime gateway (WebSocket)** and **Zustand stores**.

Never use `invalidate()`, `refetch()`, or any tRPC query re-fetch to update UI after a real-time event. Instead:
1. Gateway dispatches the event (CARD_CREATE, JOB_STATUS, etc.)
2. `data-sync.ts` or `useGenerationJobs` handles the event
3. Zustand stores or local state are updated directly from the event payload
4. UI components read from stores / merged state via `useMemo`

## Stores

| Store | Purpose |
|-------|---------|
| `data-store` | Lessons, folders, user stats — seeded via HTTP, updated via gateway |
| `job-store` | Global job tracking — bridges chat-created jobs with lesson-level hooks |
| `chat-store` | Chat messages, streaming state, tool call statuses |

## Key Files

- `lib/data-sync.ts` — Global gateway event handler (lessons, folders, jobs, cards count)
- `lib/useGenerationJobs.ts` — Per-lesson hook accumulating cards/groups/sources from gateway
- `stores/job-store.ts` — Global job registry shared between chat and lesson pages
- `lib/gateway.ts` — WebSocket singleton + `useGatewayEvent` hook

## Loading States

Job loading states (queued → processing → completed/failed) are driven by `JOB_PROGRESS` and `JOB_STATUS` gateway events. These are handled globally in `data-sync.ts` which updates both `job-store` and `chat-store`. Never poll HTTP endpoints for job status.
