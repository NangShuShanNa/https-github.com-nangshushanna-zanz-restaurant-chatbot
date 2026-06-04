<script setup>
import { computed, ref } from 'vue'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import StatusPill from '../../components/StatusPill.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const { state, cancelOrder } = useAppState()
const selected = ref(state.orders[0])
const filter = ref('all')
const ownerNav = [
  { label: 'Dashboard', to: '/owner/dashboard', short: 'Home' },
  { label: 'Menu Management', to: '/owner/menu-management', short: 'Menu' },
  { label: 'Orders', to: '/owner/orders' },
  { label: 'Staff Accounts', to: '/owner/staff-accounts', short: 'Staff' },
  { label: 'Logout', to: '/logout', short: 'Logout' },
]
const statuses = ['all', 'new', 'preparing', 'ready', 'completed', 'allergy orders']
const filteredOrders = computed(() => state.orders.filter((order) => {
  if (filter.value === 'all') return true
  if (filter.value === 'allergy orders') return order.allergies.length
  return order.status === filter.value
}))
const counts = computed(() => ({
  new: state.orders.filter((order) => order.status === 'new').length,
  preparing: state.orders.filter((order) => order.status === 'preparing').length,
  ready: state.orders.filter((order) => order.status === 'ready').length,
  completed: state.orders.filter((order) => order.status === 'completed').length,
}))
const orderTotal = computed(() => selected.value.items.reduce((sum, item) => sum + item.price * item.quantity, 0))
const canCancel = computed(() => selected.value && !['completed', 'cancelled'].includes(selected.value.status))
const steps = ['new', 'preparing', 'ready', 'completed']
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search order number, table, or item" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <h1 class="text-4xl font-black">Order Management</h1>
        <p class="mt-2 text-muted">Monitor customer orders and review order details.</p>

        <section class="mt-6 grid gap-4 md:grid-cols-4">
          <article v-for="(count, status) in counts" :key="status" class="section-card p-4">
            <p class="text-sm font-bold capitalize text-muted">{{ status }}</p>
            <strong class="text-3xl text-brand">{{ count }}</strong>
          </article>
        </section>

        <div class="mt-6 flex flex-wrap gap-2">
          <button v-for="status in statuses" :key="status" class="rounded-full px-4 py-2 text-sm font-bold capitalize shadow-sm" :class="filter === status ? 'bg-softGreen text-brand' : 'bg-white text-muted'" @click="filter = status">
            {{ status }}
          </button>
        </div>

        <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_380px]">
          <article class="section-card overflow-hidden">
            <div class="hidden bg-pale px-5 py-4 text-sm font-black text-brand lg:grid lg:grid-cols-[1fr_.8fr_.8fr_.8fr_.8fr_.8fr]">
              <span>Order No</span><span>Table</span><span>Items</span><span>Allergy</span><span>Status</span><span>Action</span>
            </div>
            <button v-for="order in filteredOrders" :key="order.id" class="grid w-full gap-3 border-t border-stone-100 p-5 text-left hover:bg-pale lg:grid-cols-[1fr_.8fr_.8fr_.8fr_.8fr_.8fr] lg:items-center" @click="selected = order">
              <strong>#{{ order.orderNumber }}</strong>
              <span>{{ order.tableNumber }}</span>
              <span>{{ order.items.length }} items</span>
              <span>{{ order.allergies.length ? order.allergies.join(', ') : 'None' }}</span>
              <StatusPill :status="order.status" />
              <span class="font-bold text-brand">View Details</span>
            </button>
          </article>

          <aside v-if="selected" class="section-card p-5">
            <h2 class="text-xl font-black">Order #{{ selected.orderNumber }}</h2>
            <p class="mt-1 text-muted">Table {{ selected.tableNumber }} · {{ selected.time }}</p>
            <div class="mt-4"><StatusPill :status="selected.status" /></div>
            <p v-if="selected.allergies.length" class="mt-4 rounded-2xl bg-red-50 px-4 py-3 text-sm font-bold text-red-700">
              Allergy Alert: {{ selected.allergies.join(', ') }}
            </p>
            <p v-if="selected.customerNote" class="mt-3 rounded-2xl bg-pale px-4 py-3 text-sm text-muted">Customer note: “{{ selected.customerNote }}”</p>
            <div class="mt-5 space-y-2">
              <p v-for="item in selected.items" :key="item.name" class="flex justify-between text-sm">
                <span>{{ item.quantity }}× {{ item.name }}</span>
                <strong>{{ item.price * item.quantity }} Baht</strong>
              </p>
            </div>
            <p class="mt-4 flex justify-between border-t border-stone-100 pt-4 text-lg font-black">
              <span>Total</span><span class="text-brand">{{ orderTotal }} Baht</span>
            </p>
            <div class="mt-6 grid grid-cols-2 gap-2">
              <span v-for="step in steps" :key="step" class="rounded-2xl border px-3 py-2 text-center text-xs font-bold capitalize" :class="steps.indexOf(step) <= steps.indexOf(selected.status) ? 'border-brand bg-pale text-brand' : 'border-stone-100 text-muted'">{{ step }}</span>
            </div>
            <button v-if="canCancel" class="mt-6 w-full rounded-full border border-red-200 bg-red-50 px-4 py-3 font-black text-red-700" @click="cancelOrder(selected.orderNumber)">Cancel Order</button>
            <p v-else class="mt-6 rounded-2xl bg-stone-100 px-4 py-3 text-center text-sm font-bold text-muted">No further action available.</p>
          </aside>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>
