<script setup>
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Info, ShoppingCart } from '@lucide/vue'
import ChatPanel from '../../components/ChatPanel.vue'
import MobileNav from '../../components/MobileNav.vue'
import QuantityControl from '../../components/QuantityControl.vue'
import SideNav from '../../components/SideNav.vue'
import TagList from '../../components/TagList.vue'
import TopBar from '../../components/TopBar.vue'
import { categories } from '../../data/mockData'
import { useAppState } from '../../services/appState'

const { state, cartItems, addToCart, t } = useAppState()
const route = useRoute()
const selectedItem = ref(null)
const search = ref('')
const detailQty = ref(1)
const detailNote = ref('')

const navItems = [
  { label: 'Starters', to: '/customer/menu?category=Starters' },
  { label: 'Main Courses', to: '/customer/menu?category=Main Courses', short: 'Mains' },
  { label: 'Drinks', to: '/customer/menu?category=Drinks' },
  { label: 'Check Order Status', to: '/customer/order-status', short: 'Status' },
]

const filteredItems = computed(() => state.menuItems.filter((item) => {
  const categoryMatch = item.category === state.selectedCategory
  const text = [item.name, item.description, ...item.ingredients, ...item.dietaryTags, ...item.tasteProfiles].join(' ').toLowerCase()
  return categoryMatch && text.includes(search.value.toLowerCase())
}))

watch(
  () => route.query.category,
  (category) => {
    if (categories.includes(category)) state.selectedCategory = category
  },
  { immediate: true },
)

function openDetail(item) {
  selectedItem.value = item
  detailQty.value = 1
  detailNote.value = ''
}

function addSelected() {
  addToCart(selectedItem.value.id, detailQty.value, detailNote.value)
  selectedItem.value = null
}
</script>

<template>
  <div class="page-shell">
    <TopBar v-model="search" :cart-count="cartItems.length" />
    <div class="content-shell">
      <SideNav :items="navItems" bottom-label="Checkout" />
      <main class="main-panel">
        <div class="grid gap-6 xl:grid-cols-[1fr_380px] 2xl:grid-cols-[1fr_420px]">
          <section>
            <div class="mb-7 flex flex-wrap items-end justify-between gap-4">
              <div>
                <h1 class="text-4xl font-black">{{ t('Today’s') }} <span class="italic text-brand">{{ t('Signature') }}</span> {{ t('Curations') }}</h1>
                <p class="mt-2 max-w-2xl text-muted">{{ t('Browse dishes or ask Chef AI for recommendations based on taste, ingredients, allergies, or dietary preferences.') }}</p>
              </div>
              <RouterLink to="/customer/cart" class="primary-btn inline-flex items-center gap-2">
                <ShoppingCart :size="18" />
                {{ t('Checkout') }}
              </RouterLink>
            </div>

            <div class="mb-6 flex flex-wrap gap-2">
              <button
                v-for="category in categories"
                :key="category"
                :class="state.selectedCategory === category ? 'bg-softGreen text-brand' : 'bg-white text-muted'"
                class="rounded-full px-4 py-2 text-sm font-bold shadow-sm"
                @click="state.selectedCategory = category"
              >
                {{ t(category) }}
              </button>
            </div>

            <input v-model="search" class="field mb-6 max-w-xl" :placeholder="t('Search dishes, ingredients, or taste')" />

            <section class="grid gap-6 sm:grid-cols-2">
              <article
                v-for="item in filteredItems"
                :key="item.id"
                class="section-card overflow-hidden transition hover:-translate-y-1 hover:shadow-strong"
              >
                <button class="block w-full text-left" @click="openDetail(item)">
                  <img :src="item.image" :alt="item.name" class="h-48 w-full object-cover" />
                  <div class="p-5">
                    <div class="flex items-start justify-between gap-3">
                      <h2 class="font-black">{{ item.name }}</h2>
                      <strong class="whitespace-nowrap text-brand">{{ item.price }} {{ t('Baht') }}</strong>
                    </div>
                    <p class="mt-3 min-h-12 text-sm leading-relaxed text-muted">{{ item.description }}</p>
                    <TagList class="mt-4" :tags="[...item.tasteProfiles.slice(0, 1), ...item.dietaryTags.slice(0, 1), ...item.allergens.slice(0, 1).map(a => `Contains ${a}`)]" />
                  </div>
                </button>
                <div class="flex items-center justify-between px-5 pb-5">
                  <span v-if="item.availability === 'sold_out'" class="rounded-full bg-red-50 px-3 py-2 text-sm font-bold text-red-700">{{ t('Sold out') }}</span>
                  <button v-else class="primary-btn py-2 text-sm" @click="addToCart(item.id)">{{ t('Add to Cart') }}</button>
                  <button class="secondary-btn py-2 text-sm" @click="openDetail(item)">
                    <Info :size="16" class="inline" /> {{ t('Details') }}
                  </button>
                </div>
              </article>
            </section>
          </section>

          <div class="hidden xl:block">
            <ChatPanel class="sticky top-24 h-[calc(100vh-7rem)] min-h-[720px]" />
          </div>
        </div>
      </main>
    </div>
    <MobileNav :items="navItems" />

    <div v-if="selectedItem" class="fixed inset-0 z-50 grid place-items-center bg-black/30 p-4">
      <section class="grid max-h-[92vh] w-full max-w-4xl overflow-auto rounded-[2rem] bg-white shadow-strong md:grid-cols-[360px_1fr]">
        <img :src="selectedItem.image" :alt="selectedItem.name" class="h-72 w-full object-cover md:h-full" />
        <div class="p-6 md:p-8">
          <button class="float-right text-2xl font-bold text-muted" @click="selectedItem = null">×</button>
          <h2 class="text-3xl font-black">{{ selectedItem.name }}</h2>
          <p class="mt-1 text-xl font-black text-brand">{{ selectedItem.price }} {{ t('Baht') }}</p>
          <p class="mt-4 leading-relaxed text-muted">{{ selectedItem.description }}</p>
          <TagList class="mt-4" :tags="[...selectedItem.tasteProfiles, ...selectedItem.dietaryTags, ...selectedItem.allergens.map(a => `Contains ${a}`)]" />
          <div class="mt-6 grid gap-4 text-sm sm:grid-cols-2">
            <div><strong>{{ t('Ingredients') }}</strong><p class="text-muted">{{ selectedItem.ingredients.join(', ') }}</p></div>
            <div><strong>{{ t('Taste profile') }}</strong><p class="text-muted">{{ selectedItem.tasteProfiles.map(t).join(', ') }}</p></div>
            <div><strong>{{ t('Spice level') }}</strong><p class="text-muted">{{ t(selectedItem.spiceLevel) }}</p></div>
            <div><strong>{{ t('Allergens') }}</strong><p class="text-muted">{{ selectedItem.allergens.length ? selectedItem.allergens.map(t).join(', ') : t('None') }}</p></div>
            <div><strong>{{ t('Availability') }}</strong><p class="capitalize text-muted">{{ t(selectedItem.availability) }}</p></div>
          </div>
          <div class="mt-6 flex flex-wrap items-center gap-4">
            <QuantityControl v-model="detailQty" />
            <input v-model="detailNote" class="field flex-1" :placeholder="t('e.g., less spicy, no garlic')" />
          </div>
          <div class="mt-6 flex flex-wrap gap-3">
            <button class="primary-btn" :disabled="selectedItem.availability === 'sold_out'" @click="addSelected">{{ t('Add to Cart') }}</button>
            <button class="secondary-btn">{{ t('Ask Chef AI about this dish') }}</button>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>
