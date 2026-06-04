<script setup>
import { ClipboardList, Lock, Monitor, Utensils } from '@lucide/vue'
import AppLogo from '../../components/AppLogo.vue'
import { useAppState } from '../../services/appState'

const { state, toggleLanguage, t } = useAppState()

const cards = [
  {
    title: 'Customer',
    description: 'Browse the menu, ask Chef AI, and place orders.',
    note: 'No login required',
    button: 'Open Menu',
    to: '/customer/menu',
    icon: Utensils,
  },
  {
    title: 'Staff',
    description: 'View live orders and update order status.',
    note: 'Login required',
    button: 'Staff Login',
    to: '/staff/login',
    icon: Monitor,
  },
  {
    title: 'Owner / Admin',
    description: 'Manage menu items and monitor restaurant orders.',
    note: 'Login required',
    button: 'Admin Login',
    to: '/owner/login',
    icon: ClipboardList,
  },
]
</script>

<template>
  <main class="page-shell grid min-h-screen place-items-center px-5 py-10">
    <div class="w-full max-w-6xl">
      <header class="mb-10 flex items-center justify-between">
        <AppLogo />
        <button class="rounded-full px-4 py-2 text-sm font-bold text-muted transition hover:bg-pale hover:text-brand" @click="toggleLanguage">
          {{ state.language === 'en' ? 'EN / TH' : 'TH / EN' }}
        </button>
      </header>

      <section class="section-card p-8 text-center md:p-12">
        <p class="mx-auto mb-4 w-fit rounded-full bg-pale px-4 py-2 text-sm font-bold text-brand">{{ t('Logged out successfully. Choose an interface to continue.') }}</p>
        <h1 class="text-4xl font-black tracking-tight md:text-5xl">{{ t('Choose Your Interface') }}</h1>
        <p class="mt-3 text-muted">{{ t('Select how you want to use the restaurant system.') }}</p>

        <div class="mt-10 grid gap-5 md:grid-cols-3">
          <article v-for="card in cards" :key="card.title" class="rounded-3xl border border-stone-100 bg-white p-6 text-left shadow-soft">
            <div class="mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-pale text-brand">
              <component :is="card.icon" :size="28" />
            </div>
            <h2 class="text-xl font-black">{{ t(card.title) }}</h2>
            <p class="mt-2 min-h-12 text-sm leading-relaxed text-muted">{{ t(card.description) }}</p>
            <RouterLink :to="card.to" class="primary-btn mt-6 block text-center">{{ t(card.button) }}</RouterLink>
            <p class="mt-3 flex items-center gap-2 text-xs font-semibold text-muted">
              <Lock v-if="card.note.includes('Login')" :size="14" />
              {{ t(card.note) }}
            </p>
          </article>
        </div>

        <p class="mt-8 text-sm text-muted">{{ t('Staff and owner access is restricted to authorized users.') }}</p>
      </section>
    </div>
  </main>
</template>
