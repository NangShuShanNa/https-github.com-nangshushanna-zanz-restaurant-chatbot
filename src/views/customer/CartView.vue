<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { Trash2 } from '@lucide/vue'
import { useRouter } from 'vue-router'
import MobileNav from '../../components/MobileNav.vue'
import QuantityControl from '../../components/QuantityControl.vue'
import SideNav from '../../components/SideNav.vue'
import TagList from '../../components/TagList.vue'
import TopBar from '../../components/TopBar.vue'
import ChatPanel from '../../components/ChatPanel.vue'
import { useAppState } from '../../services/appState'

const router = useRouter()
const { state, cartItems, subtotal, total, serviceFee, conflictItems, updateCartItem, removeFromCart, createOrder, localizeMenuItem } = useAppState()
const tableNumber = ref('T-24')
const customerNote = ref('')
const noteDrafts = reactive({})
const savedNoteId = ref('')

const navItems = [
  { label: 'Starters', to: '/customer/menu', short: 'Menu' },
  { label: 'Main Courses', to: '/customer/menu', short: 'Mains' },
  { label: 'Drinks', to: '/customer/menu' },
  { label: 'Check Order Status', to: '/customer/order-status', short: 'Status' },
]

const conflictsById = computed(() => Object.fromEntries(conflictItems.value.map((item) => [item.id, true])))
const localizedCartItems = computed(() => cartItems.value.map(localizeMenuItem))

watch(
  cartItems,
  (items) => {
    items.forEach((item) => {
      if (noteDrafts[item.id] === undefined) noteDrafts[item.id] = item.note || ''
    })
  },
  { immediate: true },
)

function saveItemNote(item) {
  updateCartItem(item.id, { note: noteDrafts[item.id] || '' })
  savedNoteId.value = item.id
}

function submitOrder() {
  if (!cartItems.value.length) return
  const order = createOrder({ tableNumber: tableNumber.value, customerNote: customerNote.value })
  router.push(`/customer/order-confirmation/${order.orderNumber}`)
}
</script>

<template>
  <div class="page-shell">
    <TopBar :cart-count="cartItems.length" />
    <div class="content-shell">
      <SideNav :items="navItems" bottom-label="Back to Menu" />
      <main class="main-panel">
        <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
          <section>
            <h1 class="text-4xl font-black">Review Your Order</h1>
            <p class="mt-2 text-muted">Check your basket before submitting.</p>
            <p class="mt-4 text-sm text-muted">
              <strong class="text-stone-900">Preferences:</strong>
              {{ state.customerPreferences.join(', ') }}
              <button class="ml-2 font-bold text-brand">Edit</button>
            </p>

            <div class="mt-6 space-y-4">
              <article v-for="item in localizedCartItems" :key="item.id" class="section-card grid gap-4 p-4 md:grid-cols-[140px_1fr_auto]">
                <img :src="item.image" :alt="item.displayName" class="h-32 w-full rounded-2xl object-cover md:w-36" />
                <div>
                  <div class="flex flex-wrap justify-between gap-3">
                    <h2 class="text-xl font-black">{{ item.displayName }}</h2>
                    <strong class="text-brand">{{ item.price }} Baht</strong>
                  </div>
                  <p class="mt-2 text-sm text-muted">{{ item.displayDescription }}</p>
                  <TagList class="mt-3" :tags="[...item.displayTasteProfiles.slice(0, 1), ...item.displayDietaryTags.slice(0, 1), ...item.displayAllergens.map(a => `Contains ${a}`).slice(0, 1)]" />
                  <div v-if="conflictsById[item.id]" class="mt-3 rounded-2xl bg-orange-50 px-4 py-3 text-sm font-semibold text-orange-800">
                    Warning: This item contains {{ item.allergens.join(', ') }}.
                    <button class="ml-3 font-black text-red-600" @click="removeFromCart(item.id)">Remove</button>
                    <button class="ml-3 font-black text-brand">Replace</button>
                  </div>
                  <div class="mt-3 flex flex-col gap-2 sm:flex-row">
                    <input
                      class="field py-2"
                      :value="noteDrafts[item.id] ?? item.note"
                      placeholder="Add note"
                      @input="noteDrafts[item.id] = $event.target.value"
                    />
                    <button class="secondary-btn shrink-0 py-2 text-sm" @click="saveItemNote(item)">Save Note</button>
                  </div>
                  <p v-if="savedNoteId === item.id" class="mt-2 text-xs font-bold text-brand">Note saved for this item.</p>
                </div>
                <div class="flex items-center justify-between gap-3 md:flex-col">
                  <QuantityControl :model-value="item.quantity" @update:model-value="updateCartItem(item.id, { quantity: $event })" />
                  <button class="text-red-500" @click="removeFromCart(item.id)"><Trash2 :size="22" /></button>
                </div>
              </article>
            </div>

            <div class="mt-6 grid gap-5 lg:grid-cols-2">
              <section class="section-card p-5">
                <h2 class="font-black">Dining Information</h2>
                <div class="mt-4 grid gap-4 sm:grid-cols-2">
                  <label class="text-sm font-bold">Table number<input v-model="tableNumber" class="field mt-2" /></label>
                  <label class="text-sm font-bold">Kitchen note<input v-model="customerNote" class="field mt-2" placeholder="e.g., no onion, less spicy" /></label>
                </div>
              </section>
              <section class="section-card p-5">
                <h2 class="font-black">Order Summary</h2>
                <div class="mt-4 space-y-3 text-sm">
                  <p class="flex justify-between"><span>Subtotal</span><strong>{{ subtotal }} Baht</strong></p>
                  <p class="flex justify-between"><span>Service Fee</span><strong>{{ cartItems.length ? serviceFee : 0 }} Baht</strong></p>
                  <p class="flex justify-between border-t border-stone-100 pt-3 text-lg"><span>Total</span><strong class="text-brand">{{ total }} Baht</strong></p>
                </div>
                <button class="primary-btn mt-5 w-full" @click="submitOrder">Submit Order</button>
                <p class="mt-3 text-center text-xs text-muted">Order number will be created after submitting.</p>
              </section>
            </div>
          </section>
          <ChatPanel class="hidden xl:flex" />
        </div>
      </main>
    </div>
    <MobileNav :items="navItems" />
  </div>
</template>
