# NovaDesk — Intelligent Document Management

A production-style SaaS document management app: upload, organize, search and share files with
folders, role-based administration, activity tracking and storage analytics.

Built with **Next.js (App Router) + TypeScript + Tailwind CSS** and **Supabase** (auth, Postgres,
storage). It runs **out of the box with no Supabase credentials** in an honest, clearly-labelled
**demo mode** backed by local JSON metadata and real files on disk.

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Quick start](#quick-start)
- [Demo mode](#demo-mode)
- [Supabase setup (production mode)](#supabase-setup-production-mode)
- [Environment variables](#environment-variables)
- [Project structure](#project-structure)
- [Commands](#commands)
- [Deploying to Vercel](#deploying-to-vercel)
- [Security notes](#security-notes)

---

## Features

**Marketing site** (`/`)
- Landing page with hero, features, how-it-works, pricing, FAQ and footer.
- SEO metadata: *NovaDesk — Intelligent Document Management*.

**Authentication** (`/login`, `/register`)
- Register / sign in with server-side validation (Zod) and friendly error messages.
- Signed, httpOnly session cookie; password hashing via Supabase Auth (or scrypt in demo mode).

**Dashboard** (`/dashboard`)
- Storage and document stats, type breakdown and usage charts (recharts), recent documents and
  activity feed.
- Skeleton loading states on every route.

**Documents** (`/dashboard/documents`)
- Upload with client + server file type/size validation (PDF, Word, Excel, text, images…).
- Full-text search, filter by category/folder/date, sort by name/size/date, grid ⇄ table views —
  all URL-driven (`searchParams`) so filtering works with server-side rendering and is shareable.
- Document detail page with preview (image/PDF/text), metadata, download, rename/move/delete.

**Folders** (`/dashboard/folders`)
- Create / rename / delete with confirmation dialogs (deleting a non-empty folder explains that
  documents are kept).

**Profile & settings** (`/dashboard/profile`, `/dashboard/settings`)
- Profile editing, password change, preferences (density, reduced motion), logout and
  **delete account** with confirmation.

**Admin panel** (`/admin`, admins only)
- Overview with platform statistics and recent activity.
- Users table: search, promote/demote roles, delete users.
- Documents table: browse and delete any document.
- Server-side `requireAdmin` guards on every admin route and API handler.

---

## Tech stack

| Layer      | Choice |
|------------|--------|
| Framework  | Next.js 16 (App Router, React 19, Turbopack) |
| Language   | TypeScript (strict) |
| Styling    | Tailwind CSS v4 + design tokens in `globals.css` |
| Database   | Supabase (Postgres + Row Level Security) |
| Auth/Files | Supabase Auth + Supabase Storage (private bucket) |
| Validation | Zod (all API inputs) |
| Forms      | react-hook-form + @hookform/resolvers |
| Charts     | recharts |
| Icons      | lucide-react |
| Toasts     | sonner |
| Linting    | ESLint (eslint-config-next) |

---

## Quick start

```bash
npm install
npm run dev
```

Open **http://localhost:3000** — that's it. With no Supabase environment variables the app starts
in **demo mode** with seeded users and sample documents (see below).

Other commands:

```bash
npm run lint   # ESLint
npm run build  # production build
npm run start  # serve the production build
```

---

## Demo mode

When `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` are **not** set, NovaDesk runs a
fully local data layer (`src/lib/store/demo.ts`):

- Metadata lives in `.demo/db.json`, uploaded files in `.demo/uploads/` (both git-ignored).
- Real, downloadable files are generated for the seeded samples (PDF, DOCX, PNG, TXT…).
- Sessions are signed cookies (`nd_session`) using scrypt-hashed passwords.
- A visible **“Demo mode” badge** appears in the UI so the state is never ambiguous.

**Seeded accounts:**

| Role  | Email               | Password    |
|-------|---------------------|-------------|
| User  | `demo@novadesk.app` | `demo1234`  |
| Admin | `admin@novadesk.app`| `admin1234` |
| User  | `ava@novadesk.app`  | `demo1234`  |
| User  | `marcus@novadesk.app`| `demo1234` |
| User  | `lena@novadesk.app` | `demo1234`  |

> Demo mode is for evaluation and local development. For real data, configure Supabase below.

Reset demo data at any time by deleting `.demo/` — it is recreated and re-seeded on the next run.

---

## Supabase setup (production mode)

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL editor, run **`supabase/schema.sql`** — creates tables, indexes, triggers, the
   `is_admin()` helper, **Row Level Security policies** and the private `documents` storage bucket.
3. Run **`supabase/seed.sql`** (optional) to create demo users and sample rows.
4. Copy `.env.example` → `.env.local` and fill in the values (see below).
5. `npm run dev` — the app detects the credentials and switches to the Supabase store
   automatically (`src/lib/store/index.ts` selects the implementation).

Notes:
- Server components read directly from the store; mutations go through App Router route handlers
  (`src/app/api/**`) which re-validate every input and enforce ownership/admin checks.
- `SUPABASE_SERVICE_ROLE_KEY` is required only for admin account/document deletion; the app
  degrades gracefully with a friendly message if it is missing.

---

## Environment variables

See [`.env.example`](.env.example).

| Variable | Where | Purpose |
|----------|-------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | public | Supabase project URL — presence enables Supabase mode |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | public | Supabase anon key (safe for the browser, RLS-protected) |
| `SUPABASE_SERVICE_ROLE_KEY` | server only | Admin operations (user/document deletion) |
| `DEMO_SESSION_SECRET` | server only | Signs the demo-mode session cookie (any long random string) |

Never prefix server secrets with `NEXT_PUBLIC_`. No secrets are ever shipped to the client.

---

## Project structure

```
src/
├── app/                    # App Router routes
│   ├── page.tsx            # Landing page
│   ├── login/ register/    # Auth pages
│   ├── dashboard/          # Documents, folders, profile, settings, detail pages
│   ├── admin/              # Admin overview, users, documents
│   ├── api/                # Route handlers (auth, documents, folders, profile, admin)
│   ├── layout.tsx          # Root layout, metadata, Toaster
│   ├── error.tsx           # Friendly error boundary (no stack traces)
│   └── not-found.tsx       # 404
├── components/             # UI (landing, auth, documents, admin, modals, skeletons…)
├── lib/
│   ├── store/              # Data layer: types + demo.ts + supabase.ts + index.ts
│   ├── supabase/           # Browser/server/admin Supabase clients
│   ├── auth.ts             # Session encode/decode + requireUser/requireAdmin guards
│   ├── validations.ts      # Zod schemas + upload validation
│   └── errors.ts           # Error → friendly message mapping
└── types/                  # Shared DTOs and DB types
supabase/
├── schema.sql              # Tables, indexes, RLS policies, storage bucket
└── seed.sql                # Demo users + sample data
```

---

## Deploying to Vercel

1. Push the repository to GitHub/GitLab/Bitbucket and import it in Vercel, or use the CLI:
   ```bash
   npx vercel
   ```
2. Set the environment variables from `.env.example` in **Project → Settings → Environment
   Variables** (at minimum the two `NEXT_PUBLIC_SUPABASE_*` values for production mode; add
   `SUPABASE_SERVICE_ROLE_KEY` for admin deletions).
3. Deploy. `npm run build` is used as the build command automatically.
4. Apply `supabase/schema.sql` (and optionally `seed.sql`) to the production database first.

Without environment variables the deployed app still runs — in demo mode, which is useful for
previews but not intended for real data.

---

## Security notes

- **Server-side authorization on every request** — pages call `requireUser()` / `requireAdmin()`;
  API handlers call `requireUserApi()` and re-check ownership before any mutation.
- **Postgres Row Level Security** — all tables and the storage bucket enforce per-user policies
  (`supabase/schema.sql`); the anon key alone can never read another user's rows or objects.
- **Private storage bucket** — files are served only through an authenticated route handler
  (`/api/documents/[id]/file`), which streams from disk in demo mode or redirects to a short-lived
  signed URL in Supabase mode.
- **Validation** — every input is validated server-side with Zod; uploads are checked for allowed
  MIME types and a size limit before anything touches storage.
- **Secrets** — service-role key and session secrets are read only on the server; the client bundle
  contains no secrets.
- **Friendly failures** — errors map to human messages (`src/lib/errors.ts`); stack traces are
  never rendered. `error.tsx` shows a recovery UI with a reference digest only.
- **Sessions** — httpOnly, signed cookies; demo passwords are scrypt-hashed with per-user salts.
- **Accessibility** — semantic landmarks, skip link, focus-visible styles, labelled dialogs
  (native `<dialog>`), `aria-current` navigation, reduced-motion support.
