<script setup>
import { ClipboardList, Home, LogOut, MenuSquare, Monitor, Settings, Soup, Utensils, Wine, Users, History, LayoutDashboard } from '@lucide/vue'
import { useAppState } from '../services/appState'

defineProps({
  items: { type: Array, required: true },
  bottomLabel: { type: String, default: '' },
})

const iconMap = {
  Starters: Utensils,
  'Main Courses': Soup,
  Drinks: Wine,
  'Check Order Status': ClipboardList,
  'Live Orders': Monitor,
  'Menu Items': MenuSquare,
  Dashboard: LayoutDashboard,
  'Menu Management': MenuSquare,
  Orders: ClipboardList,
  'Staff Accounts': Users,
  Logout: LogOut,
  Settings,
  'Order History': History,
  Home,
}

const { t } = useAppState()
</script>

<template>
  <aside class="hidden w-64 shrink-0 rounded-r-3xl bg-white p-5 shadow-soft lg:flex lg:flex-col">
    <nav class="space-y-2">
      <RouterLink
        v-for="item in items"
        :key="item.label"
        :to="item.to"
        class="flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold text-stone-700 transition hover:bg-pale"
        active-class="bg-softGreen text-stone-950"
      >
        <component :is="iconMap[item.label] || Home" :size="20" />
        {{ t(item.label) }}
      </RouterLink>
    </nav>
    <RouterLink v-if="bottomLabel" to="/customer/menu" class="mt-auto rounded-full bg-brand px-5 py-3 text-center text-sm font-bold text-white shadow-soft">
      {{ t(bottomLabel) }}
    </RouterLink>
  </aside>
</template>
