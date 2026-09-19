# Ledgerly — Business Finance & Document Control

A polished finance dashboard and document-control foundation built for Supabase.

## Included
- Responsive finance dashboard UI with cash-flow visualisation, KPI cards, activity table, document health and responsive navigation.
- Documents, invoices, contacts, transactions and workspace data model.
- Supabase Auth-ready schema with tenant isolation through Row Level Security.
- Private `documents` Storage bucket for business files.
- No API keys are hard-coded; connect your Supabase project from the frontend when wiring data.

## Run locally
Open `index.html` directly, or serve the folder with any static server:

```bash
python -m http.server 5173
```

Then open http://localhost:5173.

## Supabase setup
1. Create a Supabase project.
2. Run [`supabase/schema.sql`](supabase/schema.sql) in the SQL Editor.
3. Add Supabase JS and initialise `createClient` in `index.html` using environment-specific configuration (never commit service-role keys).
4. Replace the current demo values with queries scoped to the authenticated user's `workspace_id`.

The visual layer intentionally works with demo data before a Supabase project is connected, so the UI can be reviewed immediately.
