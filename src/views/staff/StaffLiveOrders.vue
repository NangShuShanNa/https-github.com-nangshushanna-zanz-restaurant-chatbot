<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import StatusPill from '../../components/StatusPill.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const router = useRouter()
const { state, updateOrderStatus, signOut } = useAppState()
const columns = [
  { status: 'new', title: 'New', action: 'Start Preparing', next: 'preparing' },
  { status: 'preparing', title: 'Preparing', action: 'Mark Ready', next: 'ready' },
  { status: 'ready', title: 'Ready', action: 'Mark Completed', next: 'completed' },
  { status: 'completed', title: 'Completed', action: '', next: '' },
]
const navItems = [
  { label: 'Live Orders', to: '/staff/live-orders', short: 'Orders' },
  { label: 'Menu Items', to: '/staff/menu-items', short: 'Menu' },
  { label: 'Logout', to: '/logout', short: 'Logout' },
]

const liveCount = computed(() => state.orders.filter((order) => !['completed', 'cancelled'].includes(order.status)).length)

function logout() {
  signOut()
  router.push('/')
}
</script>

<template>
  <div class="page-shell">
    <TopBar search-placeholder="Search orders, table, or item" />
    <div class="content-shell">
      <SideNav :items="navItems" />
      <main class="main-panel">
        <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-4xl font-black">Kitchen Order Tracker</h1>
            <p class="mt-2 text-muted">Monitor orders and update customer status.</p>
          </div>
          <div class="flex gap-2">
            <span class="rounded-full bg-brand px-4 py-2 text-sm font-bold text-white">Live Orders: {{ liveCount }}</span>
            <button class="secondary-btn py-2" @click="logout">Logout</button>
          </div>
        </div>

        <div class="mb-5 flex flex-wrap gap-2">
          <span class="rounded-full bg-white px-4 py-2 text-sm font-bold text-brand shadow-sm">All</span>
          <span class="rounded-full bg-white px-4 py-2 text-sm font-bold text-muted shadow-sm">Dine-in</span>
          <span class="rounded-full bg-white px-4 py-2 text-sm font-bold text-muted shadow-sm">Allergy orders</span>
          <span class="rounded-full bg-white px-4 py-2 text-sm font-bold text-muted shadow-sm">Ready soon</span>
        </div>

        <section class="grid gap-5 xl:grid-cols-4">
          <div v-for="column in columns" :key="column.status" class="rounded-3xl bg-white/60 p-4">
            <h2 class="mb-4 flex items-center justify-between font-black text-brand">
              {{ column.title }}
              <span class="rounded-full bg-brand px-2.5 py-1 text-xs text-white">{{ state.orders.filter(order => order.status === column.status).length }}</span>
            </h2>

            <div class="space-y-4">
              <article v-for="order in state.orders.filter(order => order.status === column.status)" :key="order.id" class="section-card p-4">
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <h3 class="font-black">Order #{{ order.orderNumber }}</h3>
                    <p class="text-sm text-muted">Table {{ order.tableNumber }} · {{ order.time }}</p>
                  </div>
                  <StatusPill :status="order.status" />
                </div>
                <div class="mt-4 space-y-2 text-sm">
                  <p v-for="item in order.items" :key="item.name">
                    <strong>{{ item.quantity }}× {{ item.name }}</strong>
                    <span v-if="item.note" class="block text-muted">Note: {{ item.note }}</span>
                  </p>
                </div>
                <p v-if="order.allergies.length" class="mt-4 rounded-2xl bg-red-50 px-3 py-2 text-sm font-bold text-red-700">
                  Allergy Alert: {{ order.allergies.join(', ') }}
                </p>
                <p v-if="order.customerNote" class="mt-3 rounded-2xl bg-pale px-3 py-2 text-sm text-muted">“{{ order.customerNote }}”</p>
                <button v-if="column.action" class="primary-btn mt-4 w-full py-2 text-sm" @click="updateOrderStatus(order.orderNumber, column.next)">
                  {{ column.action }}
                </button>
                <p v-else class="mt-4 rounded-2xl bg-pale px-3 py-2 text-center text-sm font-bold text-brand">Completed</p>
              </article>
            </div>
          </div>
        </section>
      </main>
    </div>
    <MobileNav :items="navItems" />
  </div>
</template>
