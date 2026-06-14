<script setup>
import { computed, ref, onMounted } from 'vue'
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

function getStatusLabel(statusKey) {
  const labels = {
    all: state.language === 'en' ? 'All' : 'ทั้งหมด',
    new: state.language === 'en' ? 'New' : 'ออเดอร์ใหม่',
    preparing: state.language === 'en' ? 'Preparing' : 'กำลังปรุง',
    ready: state.language === 'en' ? 'Ready' : 'พร้อมเสิร์ฟ',
    completed: state.language === 'en' ? 'Completed' : 'เสร็จสิ้น',
    'allergy orders': state.language === 'en' ? 'Allergy Orders' : 'ออเดอร์แพ้อาหาร',
  }
  return labels[statusKey?.toLowerCase()] || statusKey
}

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

const orderTotal = computed(() => selected.value ? selected.value.items.reduce((sum, item) => sum + item.price * item.quantity, 0) : 0)
const canCancel = computed(() => selected.value && !['completed', 'cancelled'].includes(selected.value.status))
const steps = ['new', 'preparing', 'ready', 'completed']

onMounted(() => {
  const savedLanguage = localStorage.getItem("zank-language");
  if (savedLanguage) {
    state.language = savedLanguage;
  }
})
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search order number, table, or item" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <h1 class="text-4xl font-black">
          {{ state.language === 'en' ? 'Order Management' : 'การจัดการคำสั่งซื้อ' }}
        </h1>
        <p class="mt-2 text-muted">
          {{ state.language === 'en' ? 'Monitor customer orders and review order details.' : 'ตรวจสอบสถานะคำสั่งซื้อจากลูกค้าและดูรายละเอียดประวัติรายการอาหาร' }}
        </p>

        <section class="mt-6 grid gap-4 sm:grid-cols-2 md:grid-cols-4">
          <article v-for="(count, status) in counts" :key="status" class="section-card p-5 flex flex-col justify-between">
            <p class="text-sm font-bold capitalize text-muted">
              {{ getStatusLabel(status) }}
            </p>
            <strong class="text-3xl font-black text-brand mt-2 block">{{ count }}</strong>
          </article>
        </section>

        <div class="mt-6 flex flex-wrap gap-2">
          <button 
            v-for="status in statuses" 
            :key="status" 
            class="rounded-full px-5 py-2.5 text-sm font-bold shadow-sm border border-stone-100/50 transition hover:opacity-90 active:scale-95" 
            :class="filter === status ? 'bg-softGreen text-brand ring-2 ring-brand/10' : 'bg-white text-muted'" 
            @click="filter = status"
          >
            {{ getStatusLabel(status) }}
          </button>
        </div>

        <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_400px] items-start">
          
          <article class="section-card overflow-hidden">
            <div class="hidden bg-pale px-5 py-4 text-xs font-black text-brand tracking-wider uppercase lg:grid lg:grid-cols-[1fr_.8fr_1fr_1.2fr_1fr_auto]">
              <span>{{ state.language === 'en' ? 'Order No' : 'เลขที่ออเดอร์' }}</span>
              <span>{{ state.language === 'en' ? 'Table' : 'โต๊ะ' }}</span>
              <span>{{ state.language === 'en' ? 'Items' : 'จำนวนรายการ' }}</span>
              <span>{{ state.language === 'en' ? 'Allergy Alert' : 'ข้อมูลแพ้อาหาร' }}</span>
              <span>{{ state.language === 'en' ? 'Status' : 'สถานะ' }}</span>
              <span class="text-right pr-4">{{ state.language === 'en' ? 'Action' : 'จัดการ' }}</span>
            </div>
            
            <div v-if="filteredOrders.length === 0" class="p-10 text-center text-muted">
              {{ state.language === 'en' ? 'No orders found matching this filter.' : 'ไม่พบคำสั่งซื้อในหมวดหมู่นี้' }}
            </div>

            <button 
              v-else
              v-for="order in filteredOrders" 
              :key="order.id" 
              class="grid w-full gap-3 border-t border-stone-100 p-5 text-left transition hover:bg-pale lg:grid-cols-[1fr_.8fr_1fr_1.2fr_1fr_auto] lg:items-center" 
              :class="selected?.id === order.id ? 'bg-pale ring-2 ring-brand/20' : ''"
              @click="selected = order"
            >
              <strong class="text-stone-900">#{{ order.orderNumber }}</strong>
              <span class="font-medium text-stone-600">{{ state.language === 'en' ? 'Table' : 'โต๊ะ' }} {{ order.tableNumber }}</span>
              <span class="text-stone-600">{{ order.items.length }} {{ state.language === 'en' ? 'items' : 'รายการ' }}</span>
              <span :class="order.allergies.length ? 'text-red-600 font-bold' : 'text-stone-400'">
                {{ order.allergies.length ? order.allergies.join(', ') : (state.language === 'en' ? 'None' : 'ไม่มี') }}
              </span>
              <StatusPill :status="order.status" />
              <span class="font-bold text-brand text-right lg:pr-4 text-sm whitespace-nowrap">
                {{ state.language === 'en' ? 'View Details' : 'ดูรายละเอียด' }}
              </span>
            </button>
          </article>

          <aside 
            v-if="selected" 
            class="section-card p-5 sticky top-24 shadow-strong z-10 flex flex-col h-[calc(100vh-140px)] bg-white overflow-y-auto custom-scrollbar"
          >
            <div class="border-b border-stone-100 pb-3">
              <h2 class="text-xl font-black text-stone-900">
                {{ state.language === 'en' ? 'Order' : 'คำสั่งซื้อ' }} #{{ selected.orderNumber }}
              </h2>
              <p class="mt-1 text-sm text-muted">
                {{ state.language === 'en' ? 'Table' : 'โต๊ะ' }} {{ selected.tableNumber }} · {{ selected.time }}
              </p>
              <div class="mt-3"><StatusPill :status="selected.status" /></div>
            </div>
            
            <div class="flex-1 overflow-y-auto py-4 space-y-4">
              <p v-if="selected.allergies.length" class="rounded-2xl bg-red-50 px-4 py-3 text-sm font-bold text-red-700 border border-red-100 animate-pulse">
                {{ state.language === 'en' ? 'Allergy Alert:' : 'แจ้งเตือนลูกค้าแพ้อาหาร:' }} {{ selected.allergies.join(', ') }}
              </p>
              
              <p v-if="selected.customerNote" class="rounded-2xl bg-pale px-4 py-3 text-sm text-stone-600 border border-stone-100/50 italic">
                {{ state.language === 'en' ? 'Customer note:' : 'หมายเหตุจากลูกค้า:' }} “{{ selected.customerNote }}”
              </p>
              
              <div class="space-y-2.5">
                <p v-for="item in selected.items" :key="item.name" class="flex justify-between text-sm items-center bg-stone-50/50 p-2 rounded-xl border border-stone-100/30">
                  <span class="text-stone-800 font-medium"><span class="font-black text-brand mr-1">{{ item.quantity }}×</span> {{ item.name }}</span>
                  <strong class="text-stone-900">{{ item.price * item.quantity }} Baht</strong>
                </p>
              </div>
            </div>
            
            <div class="border-t border-stone-100 pt-4 bg-white mt-auto">
              <p class="flex justify-between text-lg font-black text-stone-900 mb-4">
                <span>{{ state.language === 'en' ? 'Total' : 'ยอดรวมสุทธิ' }}</span>
                <span class="text-brand text-xl">{{ orderTotal }} Baht</span>
              </p>
              
              <div class="grid grid-cols-2 gap-2 mb-4">
                <span 
                  v-for="step in steps" 
                  :key="step" 
                  class="rounded-xl border py-2 text-center text-xs font-bold" 
                  :class="steps.indexOf(step) <= steps.indexOf(selected.status) ? 'border-brand bg-pale text-brand' : 'border-stone-100 text-muted'"
                >
                  {{ getStatusLabel(step) }}
                </span>
              </div>
              
              <button v-if="canCancel" class="w-full rounded-full border border-red-200 bg-red-50 py-3 font-black text-red-700 transition hover:bg-red-100 active:scale-95" @click="cancelOrder(selected.orderNumber)">
                {{ state.language === 'en' ? 'Cancel Order' : 'ยกเลิกคำสั่งซื้อนี้' }}
              </button>
              <p v-else class="rounded-2xl bg-stone-100 py-3 text-center text-sm font-bold text-muted">
                {{ state.language === 'en' ? 'No further action available.' : 'เสร็จสิ้นขั้นตอนแล้ว ไม่สามารถจัดการเพิ่มเติมได้' }}
              </p>
            </div>
          </aside>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>