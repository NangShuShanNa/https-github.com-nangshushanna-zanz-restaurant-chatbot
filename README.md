# ZANK AI Restaurant Chatbot

Responsive Vue implementation for the AI Restaurant Chatbot project.

## Stack

- Vue 3 + Vite
- Tailwind CSS
- Vue Router
- Supabase-ready data layer
- PostgreSQL schema for self-hosted Supabase
- Playwright for smoke testing

## Run Locally

```bash
npm install
npm run dev
```

Open:

```text
http://127.0.0.1:5173/
```

## Build

```bash
npm run build
```

## Current Implementation

The app currently runs with local sample data so the full UI can be tested before connecting Supabase.

Implemented flows:

- Role selection
- Customer menu
- Menu item detail modal
- Chef AI panel with database-style filtering
- Cart review
- Allergy/preference conflict warning
- Order submission
- Order confirmation
- Check order status
- Staff login
- Staff live orders
- Staff menu item availability
- Owner login
- Owner dashboard
- Owner menu management
- Owner order monitoring
- Owner staff accounts
- Forgot password UI
- Logout to role selection
- Responsive desktop/mobile layouts

## Demo Login

Owner:

```text
admin@zank.com
admin123
```

Staff:

```text
kitchen@zank.com
staff123
```

Wrong passwords are rejected in the demo login.

## Supabase Self-Hosting

Use the Supabase Docker guide:

```text
https://supabase.com/docs/guides/self-hosting/docker
```

Environment example:

```bash
cp .env.example .env
```

Set:

```text
VITE_SUPABASE_URL=http://localhost:8000
VITE_SUPABASE_ANON_KEY=<your anon key>
```

Database files:

```text
supabase/schema.sql
supabase/seed.sql
```

Run `schema.sql` first, then `seed.sql`.

## Main Database Tables

- `profiles`
- `menu_items`
- `orders`
- `order_items`
- `chatbot_conversations`

## Notes

- Customer does not need login.
- Staff and owner routes are protected.
- Staff operates order status.
- Owner monitors orders and manages menu/staff accounts.
- Payment, delivery, print ticket, settings, analytics, voice input, and order history are intentionally out of scope.
