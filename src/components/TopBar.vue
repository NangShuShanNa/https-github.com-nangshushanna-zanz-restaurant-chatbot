<script setup>
import { Globe2, Search, ShoppingCart, UserCircle } from '@lucide/vue'
import { computed, ref } from 'vue'
import AppLogo from './AppLogo.vue'
import { useAppState } from '../services/appState'

defineProps({
  cartCount: { type: Number, default: 0 },
  searchPlaceholder: { type: String, default: 'Search dishes, ingredients, or taste' },
  owner: { type: Boolean, default: false },
})

const { state, toggleLanguage, t } = useAppState()
const showAccountMenu = ref(false)

const accountLabel = computed(() => {
  if (state.activeUser?.role === 'owner') return state.language === 'en' ? 'Owner / Admin' : 'เจ้าของร้าน / แอดมิน'
  if (state.activeUser?.role === 'kitchen_staff') return state.language === 'en' ? 'Kitchen Staff' : 'พนักงานครัว'
  if (state.activeUser?.role === 'reception_staff') return state.language === 'en' ? 'Reception Staff' : 'พนักงานต้อนรับ'
  return state.language === 'en' ? 'Customer' : 'ลูกค้า'
})

const accountActions = computed(() => {
  if (state.activeUser?.role === 'owner') {
    return [
      { label: state.language === 'en' ? 'Owner Dashboard' : 'แดชบอร์ดเจ้าของร้าน', to: '/owner/dashboard' },
      { label: state.language === 'en' ? 'Menu Management' : 'จัดการเมนู', to: '/owner/menu-management' },
      { label: state.language === 'en' ? 'Logout' : 'ออกจากระบบ', to: '/logout' },
    ]
  }
  if (['kitchen_staff', 'reception_staff'].includes(state.activeUser?.role)) {
    return [
      { label: state.language === 'en' ? 'Live Orders' : 'ออเดอร์สด', to: '/staff/live-orders' },
      { label: state.language === 'en' ? 'Menu Items' : 'รายการเมนู', to: '/staff/menu-items' },
      { label: state.language === 'en' ? 'Logout' : 'ออกจากระบบ', to: '/logout' },
    ]
  }
  return [
    { label: state.language === 'en' ? 'Open Menu' : 'เปิดเมนู', to: '/customer/menu' },
    { label: state.language === 'en' ? 'Check Order Status' : 'ตรวจสอบสถานะออเดอร์', to: '/customer/order-status' },
    { label: state.language === 'en' ? 'Interface Selection' : 'เลือกหน้าการใช้งาน', to: '/' },
  ]
})
</script>

<template>
  <header class="sticky top-0 z-20 flex h-20 items-center gap-4 border-b border-stone-100 bg-white/95 px-5 backdrop-blur">
    <AppLogo />
    <label class="ml-auto flex h-11 min-w-0 flex-1 max-w-xl items-center gap-3 rounded-full bg-pale px-4 text-sm text-muted">
      <Search :size="18" />
      <input class="min-w-0 flex-1 bg-transparent outline-none" :placeholder="t(searchPlaceholder)" />
    </label>
    <button class="hidden items-center gap-2 rounded-full px-3 py-2 text-sm font-semibold text-stone-700 transition hover:bg-pale sm:flex" @click="toggleLanguage">
      <Globe2 :size="20" />
      <span>{{ state.language === 'en' ? 'EN / TH' : 'TH / EN' }}</span>
    </button>
    <RouterLink
      v-if="!owner"
      to="/customer/cart"
      class="relative z-30 inline-flex h-11 w-11 cursor-pointer items-center justify-center rounded-full text-stone-900 transition hover:bg-pale focus:outline-none focus:ring-2 focus:ring-brand/40"
      :aria-label="state.language === 'en' ? 'Open cart' : 'เปิดตะกร้า'"
      :title="state.language === 'en' ? 'Open cart' : 'เปิดตะกร้า'"
    >
      <ShoppingCart :size="25" />
      <span v-if="cartCount" class="absolute -right-2 -top-2 grid h-5 w-5 place-items-center rounded-full bg-brand text-xs font-bold text-white">{{ cartCount }}</span>
    </RouterLink>
    <div class="relative flex items-center gap-2">
      <button class="rounded-full p-2 transition hover:bg-pale" :aria-label="state.language === 'en' ? 'Open account menu' : 'เปิดเมนูบัญชี'" @click="showAccountMenu = !showAccountMenu">
        <UserCircle :size="30" />
      </button>
      <span v-if="owner" class="hidden text-sm font-semibold text-muted md:inline">{{ state.language === 'en' ? 'Owner' : 'เจ้าของร้าน' }}</span>
      <div v-if="showAccountMenu" class="absolute right-0 top-12 z-50 w-64 rounded-3xl border border-stone-100 bg-white p-3 shadow-strong">
        <div class="border-b border-stone-100 px-3 pb-3">
          <p class="text-xs font-bold uppercase tracking-wide text-muted">{{ state.language === 'en' ? 'Account' : 'บัญชี' }}</p>
          <p class="mt-1 font-black text-stone-900">{{ accountLabel }}</p>
          <p class="text-xs text-muted">{{ state.activeUser?.email || (state.language === 'en' ? 'No login required' : 'ไม่ต้องเข้าสู่ระบบ') }}</p>
        </div>
        <div class="mt-2 grid gap-1">
          <RouterLink
            v-for="action in accountActions"
            :key="action.to"
            :to="action.to"
            class="rounded-2xl px-3 py-2 text-sm font-bold text-stone-700 hover:bg-pale hover:text-brand"
            @click="showAccountMenu = false"
          >
            {{ action.label }}
          </RouterLink>
        </div>
      </div>
    </div>
  </header>
</template>
