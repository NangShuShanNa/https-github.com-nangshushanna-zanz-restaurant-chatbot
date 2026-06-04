<script setup>
import { Eye, Lock, Mail, ShieldCheck } from '@lucide/vue'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import AppLogo from '../../components/AppLogo.vue'
import { useAppState } from '../../services/appState'

const props = defineProps({
  type: { type: String, required: true },
})

const router = useRouter()
const { signIn } = useAppState()
const email = ref(props.type === 'owner' ? 'admin@zank.com' : 'kitchen@zank.com')
const password = ref('')
const showError = ref(false)

const title = computed(() => props.type === 'owner' ? 'Admin Login' : 'Staff Login')
const subtitle = computed(() => props.type === 'owner'
  ? 'Manage menus, ingredients, allergens, and customer orders.'
  : 'Access live orders and update order status.')
const target = computed(() => props.type === 'owner' ? '/owner/dashboard' : '/staff/live-orders')
const demoPassword = computed(() => props.type === 'owner' ? 'admin123' : 'staff123')

function submit() {
  const ok = signIn(props.type === 'owner' ? 'owner' : 'staff', email.value, password.value)
  if (!ok) {
    showError.value = true
    return
  }
  showError.value = false
  router.push(target.value)
}
</script>

<template>
  <main class="page-shell min-h-screen px-5 py-8">
    <header class="mx-auto flex max-w-6xl items-center justify-between">
      <AppLogo />
      <span class="text-sm font-bold text-muted">EN / TH</span>
    </header>

    <section class="mx-auto mt-12 max-w-md rounded-[2rem] bg-white p-8 shadow-strong">
      <div class="text-center">
        <AppLogo />
        <div class="mx-auto mt-6 grid h-12 w-12 place-items-center rounded-full bg-pale text-brand">
          <ShieldCheck :size="26" />
        </div>
        <h1 class="mt-5 text-3xl font-black">{{ title }}</h1>
        <p class="mt-2 text-sm leading-relaxed text-muted">{{ subtitle }}</p>
        <p class="mt-4 text-sm font-semibold text-brand">For authorized users only.</p>
      </div>

      <form class="mt-7 space-y-4" @submit.prevent="submit">
        <label class="block text-sm font-bold">
          Email address
          <span class="mt-2 flex items-center gap-2 rounded-2xl border border-stone-200 px-4 py-3">
            <Mail :size="18" class="text-muted" />
            <input v-model="email" class="w-full outline-none" type="email" />
          </span>
        </label>
        <label class="block text-sm font-bold">
          <span class="flex justify-between">
            Password
            <RouterLink to="/forgot-password" class="text-xs text-brand">Forgot password?</RouterLink>
          </span>
          <span class="mt-2 flex items-center gap-2 rounded-2xl border border-stone-200 px-4 py-3">
            <Lock :size="18" class="text-muted" />
            <input v-model="password" class="w-full outline-none" type="password" />
            <Eye :size="18" class="text-muted" />
          </span>
        </label>
        <p v-if="showError" class="text-sm font-semibold text-red-600">Invalid email or password.</p>
        <p class="rounded-2xl bg-pale px-4 py-3 text-xs font-bold text-brand">
          Demo password: {{ demoPassword }}
        </p>
        <label class="flex items-center gap-2 text-sm text-muted">
          <input type="checkbox" />
          Remember me
        </label>
        <button class="primary-btn w-full">Sign In</button>
      </form>

      <RouterLink to="/" class="mt-6 block text-center text-sm font-bold text-brand">← Back to interface selection</RouterLink>
      <p class="mt-6 border-t border-stone-100 pt-5 text-center text-xs text-muted">Only authorized accounts can access this dashboard.</p>
    </section>
  </main>
</template>
