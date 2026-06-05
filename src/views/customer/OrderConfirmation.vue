<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import TopBar from '../../components/TopBar.vue'
import SideNav from '../../components/SideNav.vue'
import MobileNav from '../../components/MobileNav.vue'
import ChatPanel from '../../components/ChatPanel.vue'
import StatusPill from '../../components/StatusPill.vue'
import { useAppState } from '../../services/appState'

const route = useRoute()
const { state } = useAppState()
const order = computed(() => state.orders.find((entry) => entry.orderNumber === route.params.orderNumber) || state.orders[0])
const navItems = [
  { label: 'Starters', to: '/customer/menu', short: 'Menu' },
  { label: 'Main Courses', to: '/customer/menu', short: 'Mains' },
  { label: 'Drinks', to: '/customer/menu' },
  { label: 'Check Order Status', to: '/customer/order-status', short: 'Status' },
]

function itemName(item) {
  return state.language === 'th' && item.nameTh ? item.nameTh : item.name
}
</script>

<template>
  <div class="page-shell">
    <TopBar />
    <div class="content-shell">
      <SideNav :items="navItems" bottom-label="Back to Menu" />
      <main class="main-panel grid gap-6 xl:grid-cols-[1fr_360px]">
        <section class="section-card mx-auto w-full max-w-2xl p-8 text-center">
          <div class="mx-auto mb-5 grid h-16 w-16 place-items-center rounded-full bg-softGreen text-3xl">✓</div>
          <h1 class="text-4xl font-black">Order Submitted</h1>
          <p class="mt-2 text-muted">Your order has been sent to the kitchen.</p>
          <p class="mt-8 text-sm font-bold text-muted">Order No.</p>
          <p class="text-5xl font-black text-brand">{{ order.orderNumber }}</p>
          <div class="mt-4"><StatusPill :status="order.status" /></div>
          <p class="mt-4 text-muted">Table {{ order.tableNumber }} · {{ order.time }}</p>
          <div class="mt-6 rounded-3xl bg-pale p-5 text-left">
            <div v-for="item in order.items" :key="item.name" class="py-2 text-sm">
              <div class="flex justify-between gap-4">
                <span>{{ itemName(item) }} × {{ item.quantity }}</span>
                <strong>{{ item.price * item.quantity }} Baht</strong>
              </div>
              <p v-if="item.note" class="mt-1 rounded-2xl bg-white px-3 py-2 text-xs font-semibold text-muted">Note: {{ item.note }}</p>
            </div>
          </div>
          <p class="mt-5 text-sm text-muted">Use your order number to check status later.</p>
          <div class="mt-6 flex flex-wrap justify-center gap-3">
            <RouterLink to="/customer/order-status" class="primary-btn">Check Order Status</RouterLink>
            <RouterLink to="/customer/menu" class="secondary-btn">Back to Menu</RouterLink>
          </div>
        </section>
        <ChatPanel class="hidden xl:flex" />
      </main>
    </div>
    <MobileNav :items="navItems" />
  </div>
</template>
