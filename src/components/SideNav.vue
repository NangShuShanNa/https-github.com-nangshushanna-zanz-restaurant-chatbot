<script setup>
import {
  ClipboardList,
  Home,
  LogOut,
  MenuSquare,
  Monitor,
  Settings,
  Soup,
  Utensils,
  Wine,
  Users,
  History,
  LayoutDashboard,
} from "@lucide/vue";

import { ref } from "vue";
import { useRouter } from "vue-router";
import { useAppState } from "../services/appState";

defineProps({
  items: { type: Array, required: true },
  bottomLabel: { type: String, default: "" },
});

const router = useRouter();

const { t, signOut } = useAppState();

const showLogoutModal = ref(false);

const iconMap = {
  Starters: Utensils,
  "Main Courses": Soup,
  Drinks: Wine,
  "Check Order Status": ClipboardList,
  "Live Orders": Monitor,
  "Menu Items": MenuSquare,
  Dashboard: LayoutDashboard,
  "Menu Management": MenuSquare,
  Orders: ClipboardList,
  "Staff Accounts": Users,
  Logout: LogOut,
  Settings,
  "Order History": History,
  Home,
};

function handleNavClick(item, event) {
  if (item.label === "Logout") {
    event.preventDefault();
    showLogoutModal.value = true;
  }
}

function confirmLogout() {
  signOut();

  localStorage.removeItem("zank-active-user");

  showLogoutModal.value = false;

  router.push("/");
}

function cancelLogout() {
  showLogoutModal.value = false;
}
</script>

<template>
  <aside
    class="hidden w-64 shrink-0 rounded-r-3xl bg-white p-5 shadow-soft lg:flex lg:flex-col"
  >
    <nav class="space-y-2">
      <template v-for="item in items" :key="item.label">
        <!-- Logout -->
        <button
          v-if="item.label === 'Logout'"
          @click="showLogoutModal = true"
          class="flex w-full items-center gap-3 rounded-2xl px-4 py-3 text-left text-sm font-semibold text-stone-700 transition hover:bg-pale"
        >
          <component :is="iconMap[item.label] || Home" :size="20" />

          {{ t(item.label) }}
        </button>

        <!-- Other Menu -->
        <RouterLink
          v-else
          :to="item.to"
          class="flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold text-stone-700 transition hover:bg-pale"
          active-class="bg-softGreen text-stone-950"
        >
          <component :is="iconMap[item.label] || Home" :size="20" />

          {{ t(item.label) }}
        </RouterLink>
      </template>
    </nav>

    <RouterLink
      v-if="bottomLabel"
      to="/customer/menu"
      class="mt-auto rounded-full bg-brand px-5 py-3 text-center text-sm font-bold text-white shadow-soft"
    >
      {{ t(bottomLabel) }}
    </RouterLink>

    <!-- Logout Modal -->
    <div
      v-if="showLogoutModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    >
      <div class="w-full max-w-md rounded-3xl bg-white p-6 shadow-xl">
        <h2 class="text-lg font-black text-red-600">Confirm Logout</h2>

        <p class="mt-3 text-sm text-stone-600">
          Are you sure you want to log out?

          <br />
          You will need to sign in again.
        </p>

        <div class="mt-6 flex justify-end gap-3">
          <button class="rounded-xl border px-4 py-2" @click="cancelLogout">
            Cancel
          </button>

          <button
            class="rounded-xl bg-red-600 px-4 py-2 text-white"
            @click="confirmLogout"
          >
            Logout
          </button>
        </div>
      </div>
    </div>
  </aside>
</template>
