<script setup>
import { computed, ref, onMounted, onUnmounted } from "vue";
import { useRouter } from "vue-router";
import MobileNav from "../../components/MobileNav.vue";
import SideNav from "../../components/SideNav.vue";
import StatusPill from "../../components/StatusPill.vue";
import TopBar from "../../components/TopBar.vue";
import { useAppState } from "../../services/appState";
import { supabase } from "../../supabaseClient";

const router = useRouter();
const { state, signOut } = useAppState();

const showExitModal = ref(false);

const ownerNav = [
  { label: "Dashboard", to: "/owner/dashboard", short: "Home" },
  { label: "Menu Management", to: "/owner/menu-management", short: "Menu" },
  { label: "Orders", to: "/owner/orders" },
  { label: "Staff Accounts", to: "/owner/staff-accounts", short: "Staff" },
  { label: "Logout", to: "/logout", short: "Logout" },
];

const liveOrders = computed(
  () =>
    state.orders.filter(
      (order) => !["completed", "cancelled"].includes(order.status),
    ).length,
);

const availableItems = computed(
  () =>
    state.menuItems.filter((item) => item.availability === "available").length,
);

const soldOutItems = computed(() =>
  state.menuItems.filter((item) => item.availability === "sold_out"),
);

function logout() {
  signOut();
  localStorage.removeItem("zank-active-user");
  router.push("/");
}

function handleBackButton() {
  showExitModal.value = true;

  history.pushState(null, "", location.href);
}

function confirmExit() {
  signOut();

  localStorage.removeItem("zank-active-user");

  showExitModal.value = false;

  router.push("/owner/login");
}

function cancelExit() {
  showExitModal.value = false;
}

onMounted(() => {
  history.pushState(null, "", location.href);

  window.addEventListener("popstate", handleBackButton);
});

onUnmounted(() => {
  window.removeEventListener("popstate", handleBackButton);
});

const restaurantName = ref("");

async function fetchRestaurantName() {
  try {
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError) throw authError;

    if (user) {
      const { data, error } = await supabase
        .from("profiles")
        .select("restaurant_name")
        .eq("id", user.id)
        .single();

      if (error) throw error;

      if (data && data.restaurant_name) {
        restaurantName.value = data.restaurant_name;
      } else {
        restaurantName.value = "Zank Restaurant";
      }
    }
  } catch (error) {
    console.error("Error fetching restaurant name:", error.message);
    restaurantName.value = "Zank Restaurant";
  }
}

onMounted(() => {
  fetchRestaurantName();
});
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search menu or orders" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <div class="flex items-center gap-3 flex-wrap">
              <h1 class="text-4xl font-black text-stone-900">
                Owner Dashboard
              </h1>

              <span
                v-if="restaurantName"
                class="inline-flex items-center rounded-full bg-gradient-to-r from-amber-400 to-orange-500 px-6 py-2 text-xl font-extrabold text-white shadow-lg shadow-orange-300/50"
              >
                {{ restaurantName }}
              </span>
            </div>

            <p class="mt-2 text-muted">
              Overview of restaurant orders and menu availability.
            </p>
          </div>
        </div>

        <section class="grid gap-5 md:grid-cols-3">
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">Live Orders</p>
            <strong class="mt-2 block text-4xl text-brand">{{
              liveOrders
            }}</strong
            ><span class="text-sm text-muted">Currently active</span>
          </article>
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">Available Items</p>
            <strong class="mt-2 block text-4xl text-brand">{{
              availableItems
            }}</strong
            ><span class="text-sm text-muted">Ready for customers</span>
          </article>
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">Sold Out Items</p>
            <strong class="mt-2 block text-4xl text-brand">{{
              soldOutItems.length
            }}</strong
            ><span class="text-sm text-muted">Unavailable today</span>
          </article>
        </section>

        <section class="mt-6 grid gap-5 xl:grid-cols-[1fr_320px]">
          <article class="section-card overflow-hidden">
            <div class="border-b border-stone-100 p-5">
              <h2 class="font-black">Recent Orders</h2>
            </div>
            <div class="divide-y divide-stone-100">
              <div
                v-for="order in state.orders.slice(0, 5)"
                :key="order.id"
                class="grid gap-3 p-5 sm:grid-cols-[1fr_1fr_1fr_1fr] sm:items-center"
              >
                <strong>#{{ order.orderNumber }}</strong>
                <span>Table {{ order.tableNumber }}</span>
                <StatusPill :status="order.status" />
                <span class="text-sm text-muted">{{ order.time }}</span>
              </div>
            </div>
          </article>

          <article class="section-card p-5">
            <h2 class="font-black">Menu Availability</h2>
            <div class="mt-4 space-y-3">
              <p
                v-for="item in soldOutItems"
                :key="item.id"
                class="flex items-center justify-between rounded-2xl bg-pale px-4 py-3 text-sm"
              >
                <span class="font-bold">{{ item.name }}</span>
                <StatusPill status="sold_out" />
              </p>
            </div>
          </article>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>

  <div
    v-if="showExitModal"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
  >
    <div class="w-full max-w-md rounded-3xl bg-white p-6 shadow-xl">
      <h2 class="text-lg font-black text-red-600">Login Required</h2>

      <p class="mt-3 text-sm text-stone-600">
        If you leave this page, you must log in again.
      </p>

      <div class="mt-6 flex justify-end gap-3">
        <button class="rounded-xl border px-4 py-2" @click="cancelExit">
          Cancel
        </button>

        <button
          class="rounded-xl bg-red-600 px-4 py-2 text-white"
          @click="confirmExit"
        >
          Exit
        </button>
      </div>
    </div>
  </div>
</template>
