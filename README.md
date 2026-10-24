# DeskIQ — Intelligent Document Management Platform

[![Next.js](https://img.shields.io/badge/Next.js-16_App_Router-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-3178C6?style=flat-square&logo=typescript)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4.0-06B6D4?style=flat-square&logo=tailwindcss)](https://tailwindcss.com/)
[![Supabase](https://img.shields.io/badge/Supabase-Postgres_&_Auth-3FCF8E?style=flat-square&logo=supabase)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

**DeskIQ** is a production-grade Software-as-a-Service (SaaS) document management platform designed for secure file uploading, deep organization, full-text search, and real-time collaboration. It features role-based access control, comprehensive activity tracking, and visual storage analytics.

Built on an **hybrid data architecture**, the platform runs completely out of the box with zero external configuration in a robust **Demo Mode** (powered by local JSON metadata and disk storage), while offering enterprise-ready integration with **Supabase** for production environments.

---

## 📋 Table of Contents

- [Core Features](#-core-features)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Operating Modes](#-operating-modes)
  - [1. Demo Mode (Zero-Config)](#1-demo-mode-zero-config)
  - [2. Production Mode (Supabase)](#2-production-mode-supabase)
- [Environment Variables](#-environment-variables)
- [Project Architecture](#-project-architecture)
- [Security Architecture](#-security-architecture)
- [Deployment](#-deployment)
- [License](#-license)

---

## ✨ Core Features

### 🌐 Marketing & Landing Page (`/`)
* Fully responsive landing page featuring a dynamic hero section, interactive feature highlights, workflow walkthrough, transparent pricing, dynamic FAQ, and structured footer.
* Optimized SEO metadata and Open Graph tags.

### 🔐 Authentication & Security (`/login`, `/register`)
* Robust server-side input validation powered by **Zod**.
* Secure, signed `httpOnly` session cookies with high-entropy hashing (Supabase Auth in production / `scrypt` with per-user salts in demo mode).

### 📊 Analytics Dashboard (`/dashboard`)
* Real-time storage consumption metrics, file-type breakdown stats, and usage trend charts powered by **Recharts**.
* Recent document feeds and activity timelines with graceful skeleton loaders on every route.

### 📁 Document Management (`/dashboard/documents`, `/dashboard/folders`)
* Advanced multi-format upload pipeline (PDF, Word, Excel, plain text, images) with strict client- and server-side MIME type and size checks.
* URL-driven state (`searchParams`) enabling server-side rendering (SSR), bookmarkable searches, multi-criteria filters (category, folder, date), and column sorting.
* Comprehensive document detail views featuring format previews, metadata inspection, direct downloads, and asset lifecycle management (rename, move, delete).
* Hierarchical folder organisation with safety confirmation dialogs.

### ⚙️ User Settings (`/dashboard/profile`, `/dashboard/settings`)
* Profile customization, password rotation, accessibility preferences (interface density, reduced motion toggles), and account deletion workflows with security prompts.

### 🛡️ Administration Suite (`/admin`)
* Strictly protected via server-side `requireAdmin` route guards.
* Platform-wide telemetry, user directory management (role promotion/demotion and user pruning), and global document moderation tables.

---

## 🛠️ Tech Stack

| Layer | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | **Next.js 16** | App Router, React 19, Turbopack, Server Actions, API Route Handlers |
| **Language** | **TypeScript** | Strict type safety across client and server boundaries |
| **Styling** | **Tailwind CSS v4** | Modern utility-first CSS framework with custom design tokens |
| **UI Components** | **Lucide React & Sonner** | Scalable icon system and modern toast notification engine |
| **Database & Auth** | **Supabase (PostgreSQL)** | Managed relational database secured via Row Level Security (RLS) |
| **Storage** | **Supabase Storage / Local Disk** | Private asset storage with temporary signed token generation |
| **Validation** | **Zod & React Hook Form** | End-to-end schema validation for forms and API requests |
| **Telemetry / Charts**| **Recharts** | Declarative charting library for storage and activity analytics |

---

## 🚀 Quick Start

### Prerequisites
* **Node.js** 18.x or newer installed on your machine.
* Package manager: **npm**, **yarn**, or **pnpm**.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/deskiq.git
   cd deskiq
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   ```

4. Open **http://localhost:3000** in your browser. Without Supabase environment variables, the app will automatically launch in **Demo Mode**.

---

## ⚙️ Operating Modes

### 1. Demo Mode (Zero-Config)
When `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are omitted, DeskIQ switches seamlessly to its local storage driver (`src/lib/store/demo.ts`):
* **Persistence Layer:** Database metadata is stored locally under `.demo/db.json`, and raw binary assets reside in `.demo/uploads/` (both git-ignored).
* **Pre-seeded Accounts:**

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@novadesk.app` | `admin1234` |
| **User** | `demo@novadesk.app` | `demo1234` |
| **User** | `ava@novadesk.app` | `demo1234` |
| **User** | `marcus@novadesk.app` | `demo1234` |
| **User** | `lena@novadesk.app` | `demo1234` |

> *Tip: You can completely reset the local state at any time by deleting the `.demo/` directory.*

---

### 2. Production Mode (Supabase)

To link the application to a live Supabase backend:

1. Create a new project at [Supabase](https://supabase.com).
2. Open the SQL Editor in your Supabase dashboard and execute **`supabase/schema.sql`** to provision tables, indexes, triggers, the `is_admin()` helper function, Row Level Security (RLS) policies, and the private storage bucket.
3. (Optional) Run **`supabase/seed.sql`** to populate sample data and test users.
4. Duplicate `.env.example` as `.env.local` and populate your credentials.

---

## 🔑 Environment Variables

Create a `.env.local` file at the root of your project directory:

```env
# Public Supabase credentials (enables production mode)
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key

# Server-only secrets (required for administrative deletions)
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Server-only secret for signing local demo session cookies
DEMO_SESSION_SECRET=generate_a_long_random_string_here
```

> **Security Warning:** Never expose server secrets (like `SUPABASE_SERVICE_ROLE_KEY` or `DEMO_SESSION_SECRET`) to the client browser by prefixing them with `NEXT_PUBLIC_`.

---

## 📁 Project Architecture

```text
deskiq/
├── src/
│   ├── app/                   # Next.js App Router endpoints & layouts
│   │   ├── admin/             # Privileged administrative views
│   │   ├── api/               # Secure backend REST route handlers
│   │   ├── dashboard/         # Protected user workspace and file management
│   │   ├── (auth)/            # Authentication flows (login, register)
│   │   ├── layout.tsx         # Root application shell & global providers
│   │   └── page.tsx           # Marketing landing page
│   ├── components/            # Modular UI elements (layouts, datagrids, dialogs)
│   ├── lib/                   # Core business logic and helpers
│   │   ├── store/             # Abstracted data layer (Demo vs. Supabase implementations)
│   │   ├── supabase/          # Supabase client factories (browser, server, admin)
│   │   ├── auth.ts            # Session verification & role-guard decorators
│   │   ├── validations.ts     # Centralized Zod validation schemas
│   │   └── errors.ts          # Centralized error-to-friendly message mapping
│   └── types/                 # Shared DTOs and database schema typings
├── supabase/
│   ├── schema.sql             # Relational DDL definitions, RLS rules & storage buckets
│   └── seed.sql               # Initial PostgreSQL record seeds
└── public/                    # Static brand assets and icons
```

---

## 🔒 Security Architecture

* **Enforced Server-Side Authorization:** Route pages execute `requireUser()` or `requireAdmin()` hooks. API mutations re-verify session ownership before executing database operations.
* **Database Row Level Security (RLS):** All Postgres tables and storage objects are governed by fine-grained policies defined in `supabase/schema.sql`, guaranteeing data isolation between tenants.
* **Private Storage Streams:** Files are never exposed via public static URLs. Binary payloads are streamed safely through an authenticated backend route (`/api/documents/[id]/file`) or redirected to short-lived signed URLs in production.
* **Input Sanitization & Validation:** All incoming payloads are strictly parsed against Zod schemas at the API boundary prior to handling.
* **Fault Tolerance:** Unhandled application errors are mapped to friendly user messages (`src/lib/errors.ts`) without exposing stack traces.

---

## 🌐 Deployment (Vercel)

DeskIQ is optimized for deployment on **Vercel**:

1. Push your repository to GitHub, GitLab, or Bitbucket.
2. Import the project into your Vercel dashboard.
3. Configure the environment variables matching your `.env.local` configuration under **Project Settings → Environment Variables**.
4. Trigger a production deployment. Vercel will automatically run `npm run build`.

```bash
# Alternative via Vercel CLI
npx vercel
```

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
