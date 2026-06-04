<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { Pencil, Plus, Trash2 } from '@lucide/vue'
import MobileNav from '../../components/MobileNav.vue'
import SideNav from '../../components/SideNav.vue'
import StatusPill from '../../components/StatusPill.vue'
import TagList from '../../components/TagList.vue'
import TopBar from '../../components/TopBar.vue'
import { useAppState } from '../../services/appState'

const { state, saveMenuItem, deleteMenuItem } = useAppState()
const ownerNav = [
  { label: 'Dashboard', to: '/owner/dashboard', short: 'Home' },
  { label: 'Menu Management', to: '/owner/menu-management', short: 'Menu' },
  { label: 'Orders', to: '/owner/orders' },
  { label: 'Staff Accounts', to: '/owner/staff-accounts', short: 'Staff' },
  { label: 'Logout', to: '/logout', short: 'Logout' },
]
const selected = ref(state.menuItems[0])
const form = reactive({})

function load(item) {
  selected.value = item
  Object.assign(form, {
    ...item,
    ingredientsText: item.ingredients.join(', '),
    allergensText: item.allergens.join(', '),
    dietaryText: item.dietaryTags.join(', '),
    tasteText: item.tasteProfiles.join(', '),
  })
}

watch(selected, (item) => item && load(item), { immediate: true })

const complete = computed(() => form.name && form.category && form.price && form.ingredientsText && form.tasteText && form.availability)

function submit() {
  const savedItem = saveMenuItem({
    id: form.id,
    name: form.name,
    category: form.category,
    price: Number(form.price),
    description: form.description,
    image: form.image,
    ingredients: form.ingredientsText.split(',').map((x) => x.trim()).filter(Boolean),
    allergens: form.allergensText.split(',').map((x) => x.trim()).filter(Boolean),
    dietaryTags: form.dietaryText.split(',').map((x) => x.trim()).filter(Boolean),
    tasteProfiles: form.tasteText.split(',').map((x) => x.trim()).filter(Boolean),
    spiceLevel: form.spiceLevel,
    availability: form.availability,
  })
  load(savedItem)
}

function addNew() {
  load({
    id: '',
    name: 'New Menu Item',
    category: 'Starters',
    price: 0,
    image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80',
    description: '',
    ingredients: [],
    allergens: [],
    dietaryTags: [],
    tasteProfiles: [],
    spiceLevel: 'None',
    availability: 'available',
  })
}

function removeItem(item) {
  deleteMenuItem(item.id)
  const nextItem = state.menuItems[0]
  if (nextItem) load(nextItem)
}
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search menu items or ingredients" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-4xl font-black">Menu Management</h1>
            <p class="mt-2 text-muted">Manage dishes, ingredients, allergens, taste profiles, and availability.</p>
          </div>
          <button class="primary-btn inline-flex items-center gap-2" @click="addNew"><Plus :size="18" /> Add Menu Item</button>
        </div>

        <section class="grid gap-6 xl:grid-cols-[1fr_420px]">
          <article class="section-card overflow-hidden">
            <div class="divide-y divide-stone-100">
              <article
                v-for="item in state.menuItems"
                :key="item.id"
                class="grid cursor-pointer gap-4 p-5 transition hover:bg-pale lg:grid-cols-[80px_1.2fr_.7fr_.7fr_1fr_auto] lg:items-center"
                :class="selected?.id === item.id ? 'bg-pale ring-2 ring-brand/20' : ''"
                @click="load(item)"
              >
                <img :src="item.image" :alt="item.name" class="h-20 w-20 rounded-2xl object-cover" />
                <div><strong>{{ item.name }}</strong><p class="text-sm text-muted">{{ item.category }}</p></div>
                <span class="font-bold text-brand">{{ item.price }} Baht</span>
                <StatusPill :status="item.availability" />
                <TagList :tags="[...item.tasteProfiles.slice(0, 1), ...item.allergens.slice(0, 1).map(a => `Contains ${a}`)]" />
                <div class="flex flex-wrap gap-2">
                  <button class="secondary-btn inline-flex items-center gap-2 py-2 text-sm" @click.stop="load(item)">
                    <Pencil :size="16" />
                    Edit
                  </button>
                  <button class="rounded-full border border-red-100 px-4 py-2 text-sm font-bold text-red-600 transition hover:bg-red-50" @click.stop="removeItem(item)">
                    <Trash2 :size="16" class="inline" />
                    Delete
                  </button>
                </div>
              </article>
            </div>
          </article>

          <form class="section-card p-5" @submit.prevent="submit">
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-xl font-black">Edit Item</h2>
              <span class="rounded-full px-3 py-1 text-xs font-bold" :class="complete ? 'bg-pale text-brand' : 'bg-orange-50 text-orange-700'">{{ complete ? 'Complete' : 'Missing data' }}</span>
            </div>
            <div class="grid gap-3">
              <input v-model="form.name" class="field" placeholder="Name" />
              <div class="grid gap-3 sm:grid-cols-2">
                <select v-model="form.category" class="field"><option>Starters</option><option>Main Courses</option><option>Drinks</option></select>
                <input v-model="form.price" class="field" type="number" placeholder="Price" />
              </div>
              <textarea v-model="form.description" class="field" placeholder="Description"></textarea>
              <input v-model="form.image" class="field" placeholder="Image URL" />
              <textarea v-model="form.ingredientsText" class="field" placeholder="Ingredients, comma separated"></textarea>
              <input v-model="form.allergensText" class="field" placeholder="Allergens, comma separated" />
              <input v-model="form.dietaryText" class="field" placeholder="Dietary tags" />
              <input v-model="form.tasteText" class="field" placeholder="Taste profile" />
              <div class="grid gap-3 sm:grid-cols-2">
                <select v-model="form.spiceLevel" class="field"><option>None</option><option>Mild</option><option>Medium</option><option>Hot</option></select>
                <select v-model="form.availability" class="field"><option value="available">Available</option><option value="sold_out">Sold out</option></select>
              </div>
              <button class="primary-btn">Save Changes</button>
            </div>
          </form>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>
