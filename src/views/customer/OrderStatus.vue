<script setup>
import { computed, ref } from 'vue'
import ChatPanel from '../../components/ChatPanel.vue'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import StatusPill from '../../components/StatusPill.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const { state } = useAppState()
const orderNumber = ref(state.lastOrderNumber)
const order = computed(() => state.orders.find((entry) => entry.orderNumber.toLowerCase() === orderNumber.value.toLowerCase()))
const steps = ['new', 'preparing', 'ready', 'completed']
const navItems = [
  { label: 'Starters', to: '/customer/menu', short: 'Menu' },
  { label: 'Main Courses', to: '/customer/menu', short: 'Mains' },
  { label: 'Drinks', to: '/customer/menu' },
  { label: 'Check Order Status', to: '/customer/order-status', short: 'Status' },
]
</script>

<template>
  <div class="page-shell">
    <TopBar />
    <div class="content-shell">
      <SideNav :items="navItems" bottom-label="Back to Menu" />
      <main class="main-panel grid gap-6 xl:grid-cols-[1fr_360px]">
        <section>
          <h1 class="text-4xl font-black">Check Order Status</h1>
          <p class="mt-2 text-muted">Enter your order number or view your active order.</p>
          <div class="section-card mt-6 flex flex-col gap-3 p-5 sm:flex-row">
            <input v-model="orderNumber" class="field" placeholder="Order number" />
            <button class="primary-btn">Find Order</button>
          </div>
          <section v-if="order" class="section-card mt-6 p-6">
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div>
                <h2 class="text-2xl font-black">Order No. {{ order.orderNumber }}</h2>
                <p class="mt-1 text-muted">Table {{ order.tableNumber }} · {{ order.time }}</p>
              </div>
              <StatusPill :status="order.status" />
            </div>
            <div class="mt-7 grid gap-4 sm:grid-cols-4">
              <div v-for="step in steps" :key="step" class="rounded-2xl border p-4 text-center" :class="steps.indexOf(step) <= steps.indexOf(order.status) ? 'border-brand bg-pale text-brand' : 'border-stone-100 bg-white text-muted'">
                <strong class="capitalize">{{ step }}</strong>
              </div>
            </div>
            <div class="mt-6 rounded-3xl bg-white p-4">
              <div v-for="item in order.items" :key="item.name" class="py-2 text-sm">
                <div class="flex justify-between gap-4">
                  <span>{{ item.name }} × {{ item.quantity }}</span>
                  <strong>{{ item.price * item.quantity }} Baht</strong>
                </div>
                <p v-if="item.note" class="mt-1 rounded-2xl bg-pale px-3 py-2 text-xs font-semibold text-muted">Note: {{ item.note }}</p>
              </div>
            </div>
            <p class="mt-5 text-sm text-muted">Status updates when staff update the order.</p>
          </section>
          <p v-else class="section-card mt-6 p-6 font-bold text-muted">No order found for this order number.</p>
        </section>
        <ChatPanel class="hidden xl:flex" />
      </main>
    </div>
    <MobileNav :items="navItems" />
  </div>
</template>
