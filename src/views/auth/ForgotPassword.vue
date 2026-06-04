<script setup>
import { MailCheck } from '@lucide/vue'
import { ref } from 'vue'
import AppLogo from '../../components/AppLogo.vue'

const email = ref('')
const sent = ref(false)
</script>

<template>
  <main class="page-shell min-h-screen px-5 py-8">
    <header class="mx-auto flex max-w-6xl items-center justify-between">
      <AppLogo />
      <span class="text-sm font-bold text-muted">EN / TH</span>
    </header>

    <section class="mx-auto mt-16 max-w-md rounded-[2rem] bg-white p-8 shadow-strong">
      <div class="text-center">
        <div class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-pale text-brand">
          <MailCheck :size="30" />
        </div>
        <h1 class="mt-5 text-3xl font-black">Reset Password</h1>
        <p class="mt-2 text-sm leading-relaxed text-muted">Enter your registered email and we will send password reset instructions.</p>
      </div>

      <form class="mt-7 space-y-4" @submit.prevent="sent = true">
        <label class="block text-sm font-bold">
          Email address
          <input v-model="email" class="field mt-2" placeholder="name@zank.com" type="email" />
        </label>
        <button class="primary-btn w-full">Send Reset Link</button>
        <p v-if="sent" class="rounded-2xl bg-pale px-4 py-3 text-sm font-bold text-brand">If this email is registered, reset instructions will be sent.</p>
      </form>

      <div class="mt-6 flex justify-between text-sm font-bold text-brand">
        <RouterLink to="/owner/login">← Back to login</RouterLink>
        <RouterLink to="/">Interface selection</RouterLink>
      </div>
      <p class="mt-6 text-center text-xs text-muted">Only registered staff and owner accounts can reset passwords.</p>
    </section>
  </main>
</template>
