<script setup>
import { reactive } from 'vue'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const { state, addStaffAccount, toggleStaffStatus } = useAppState()
const ownerNav = [
  { label: 'Dashboard', to: '/owner/dashboard', short: 'Home' },
  { label: 'Menu Management', to: '/owner/menu-management', short: 'Menu' },
  { label: 'Orders', to: '/owner/orders' },
  { label: 'Staff Accounts', to: '/owner/staff-accounts', short: 'Staff' },
  { label: 'Logout', to: '/logout', short: 'Logout' },
]
const form = reactive({
  fullName: '',
  email: '',
  role: 'kitchen_staff',
  password: '',
  confirmPassword: '',
})

function submit() {
  if (!form.fullName || !form.email || !form.password || form.password !== form.confirmPassword) return
  addStaffAccount({ fullName: form.fullName, email: form.email, role: form.role, password: form.password })
  Object.assign(form, { fullName: '', email: '', role: 'kitchen_staff', password: '', confirmPassword: '' })
}
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search staff name or email" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <h1 class="text-4xl font-black">Staff Accounts</h1>
        <p class="mt-2 text-muted">Create staff logins and manage access to live orders.</p>

        <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_380px]">
          <article class="section-card overflow-hidden">
            <div class="hidden bg-pale px-5 py-4 text-sm font-black text-brand lg:grid lg:grid-cols-[1fr_1.2fr_1fr_.8fr_1fr_1fr]">
              <span>Name</span><span>Email</span><span>Role</span><span>Status</span><span>Last Login</span><span>Actions</span>
            </div>
            <div v-for="user in state.users.filter(user => user.role !== 'owner')" :key="user.id" class="grid gap-3 border-t border-stone-100 p-5 lg:grid-cols-[1fr_1.2fr_1fr_.8fr_1fr_1fr] lg:items-center">
              <strong>{{ user.fullName }}</strong>
              <span class="text-sm text-muted">{{ user.email }}</span>
              <span class="capitalize">{{ user.role.replace('_', ' ') }}</span>
              <span class="rounded-full px-3 py-1 text-xs font-bold" :class="user.status === 'active' ? 'bg-pale text-brand' : 'bg-stone-100 text-muted'">{{ user.status }}</span>
              <span class="text-sm text-muted">{{ user.lastLogin }}</span>
              <div class="flex flex-wrap gap-2">
                <button class="text-sm font-bold text-brand">Reset Password</button>
                <button class="text-sm font-bold text-red-600" @click="toggleStaffStatus(user.id)">{{ user.status === 'active' ? 'Deactivate' : 'Activate' }}</button>
              </div>
            </div>
          </article>

          <form class="section-card p-5" @submit.prevent="submit">
            <h2 class="text-xl font-black">Add Staff Account</h2>
            <p class="mt-2 text-sm text-muted">Staff can access Live Orders and Menu Items only. Owner pages remain restricted.</p>
            <div class="mt-5 grid gap-3">
              <input v-model="form.fullName" class="field" placeholder="Full Name" />
              <input v-model="form.email" class="field" placeholder="Email Address" type="email" />
              <select v-model="form.role" class="field">
                <option value="kitchen_staff">Kitchen Staff</option>
                <option value="reception_staff">Reception Staff</option>
              </select>
              <input v-model="form.password" class="field" placeholder="Temporary Password" type="password" />
              <input v-model="form.confirmPassword" class="field" placeholder="Confirm Password" type="password" />
              <button class="primary-btn">Create Account</button>
            </div>
          </form>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>
