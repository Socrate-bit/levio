# PostHog

## Access

- **Host**: `https://ph.diane.app` (self-hosted, reverse proxy)
- **API key**: available as `$POSTHOG_API_KEY` environment variable (injected by Conductor)
- Do NOT read keys from `.env` files — always use the env var

## Querying via API

Use Python with `urllib` to avoid shell escaping issues with `$` in PostHog property names.

```python
python3 << 'PYEOF'
import urllib.request, json, os

api_key = os.environ["POSTHOG_API_KEY"]
host = "https://ph.diane.app"

query = {"query": {"kind": "HogQLQuery", "query": "YOUR_HOGQL_HERE"}}
req = urllib.request.Request(
    f"{host}/api/projects/@current/query/",
    data=json.dumps(query).encode(),
    headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read())
    for row in data.get("results", []):
        print(row)
PYEOF
```

## Useful HogQL queries

- **Top exceptions (7d)**: exceptions are in `$exception_list` JSON array — extract with `properties.$exception_list`, parse as JSON, get `[0].type` and `[0].value`
- **Error boundaries**: `SELECT properties FROM events WHERE event = 'error_boundary_triggered' AND timestamp > now() - interval 7 day`
- **API errors**: `SELECT properties FROM events WHERE event = 'api_error' AND timestamp > now() - interval 7 day`
- **Event counts**: `SELECT event, count() as c FROM events WHERE timestamp > now() - interval 7 day GROUP BY event ORDER BY c DESC LIMIT 20`

## Integration in code

- Client-side: `apps/app/lib/posthog.ts`
- Error boundaries capture: `posthog.capture('error_boundary_triggered', { screen, error })`
- Server-side (API): uses `POSTHOG_API_KEY` + `POSTHOG_HOST` env vars
