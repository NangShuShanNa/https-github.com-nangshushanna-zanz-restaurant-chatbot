<script setup>
import { useRouter } from 'vue-router'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import StatusPill from '../../components/StatusPill.vue'
import TagList from '../../components/TagList.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const router = useRouter()
const { state, toggleAvailability, signOut } = useAppState()
const navItems = [
  { label: 'Live Orders', to: '/staff/live-orders', short: 'Orders' },
  { label: 'Menu Items', to: '/staff/menu-items', short: 'Menu' },
  { label: 'Logout', to: '/logout', short: 'Logout' },
]

function logout() {
  signOut()
  router.push('/')
}
</script>

<template>
  <div class="page-shell">
    <TopBar search-placeholder="Search menu items or ingredients" />
    <div class="content-shell">
      <SideNav :items="navItems" />
      <main class="main-panel">
        <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-4xl font-black">Menu Items</h1>
            <p class="mt-2 text-muted">Check availability, ingredients, allergens, and item details.</p>
          </div>
          <button class="secondary-btn py-2" @click="logout">Logout</button>
        </div>

        <section class="section-card overflow-hidden">
          <div class="hidden bg-pale px-5 py-4 text-sm font-black text-brand lg:grid lg:grid-cols-[80px_1.4fr_.8fr_.8fr_1fr_.7fr_.8fr] lg:gap-4">
            <span>Image</span><span>Item</span><span>Category</span><span>Price</span><span>Tags</span><span>Status</span><span>Action</span>
          </div>
          <article v-for="item in state.menuItems" :key="item.id" class="grid gap-4 border-t border-stone-100 p-5 lg:grid-cols-[80px_1.4fr_.8fr_.8fr_1fr_.7fr_.8fr] lg:items-center">
            <img :src="item.image" :alt="item.name" class="h-20 w-20 rounded-2xl object-cover" />
            <div>
              <h2 class="font-black">{{ item.name }}</h2>
              <p class="text-sm text-muted">Ingredients: {{ item.ingredients.join(', ') }}</p>
              <p class="text-sm text-muted">Allergens: {{ item.allergens.length ? item.allergens.join(', ') : 'None' }}</p>
            </div>
            <p class="font-semibold">{{ item.category }}</p>
            <p class="font-bold text-brand">{{ item.price }} Baht</p>
            <TagList :tags="[...item.tasteProfiles.slice(0, 1), ...item.dietaryTags.slice(0, 1)]" />
            <StatusPill :status="item.availability" />
            <button class="secondary-btn py-2 text-sm" @click="toggleAvailability(item.id)">
              {{ item.availability === 'available' ? 'Mark Sold Out' : 'Mark Available' }}
            </button>
          </article>
        </section>
      </main>
    </div>
    <MobileNav :items="navItems" />
  </div>
</template>
