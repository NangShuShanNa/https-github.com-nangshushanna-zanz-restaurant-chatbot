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

// --- Reactive Variables for Database Records ---
const restaurantName = ref("");
const restaurantId = ref("");
const menuItemsList = ref([]); // Holds raw data from menu_items table

// --- Dynamic Computed Properties for Cards & Content ---
const liveOrders = computed(
  () =>
    state.orders.filter(
      (order) => !["completed", "cancelled"].includes(order.status),
    ).length,
);

// Count records explicitly set to 'available'
const availableItemsCount = computed(
  () => menuItemsList.value.filter((item) => item.availability === "available").length,
);

// Extract and array-map elements configured as 'sold_out'
const soldOutItemsList = computed(
  () => menuItemsList.value.filter((item) => item.availability === "sold_out"),
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

/**
 * Initializes language parameters and queries database for current user session values
 */
async function initializeDashboard() {
  try {
    // Sync language selection parameters from localstorage configs
    const savedLanguage = localStorage.getItem("zank-language");
    if (savedLanguage) {
      state.language = savedLanguage;
    }

    // Pull operational credentials directly from native localStorage fallback payloads
    const savedUserJson = localStorage.getItem("zank-active-user");
    if (!savedUserJson) throw new Error("No active session found.");

    const localUser = JSON.parse(savedUserJson);
    restaurantId.value = localUser.restaurant_id;
    restaurantName.value = localUser.restaurant_name || "Zank Restaurant";

    // Query menu items directly from public.menu_items table
    if (restaurantId.value) {
      const { data: menuData, error: menuError } = await supabase
        .from("menu_items")
        .select("*")
        .eq("restaurant_id", restaurantId.value);

      if (menuError) throw menuError;
      if (menuData) {
        menuItemsList.value = menuData;
      }
    }
  } catch (error) {
    console.error("Dashboard initialization runtime failure:", error.message);
    restaurantName.value = "Zank Restaurant";
  }
}

onMounted(() => {
  initializeDashboard();
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
                {{ state.language === 'en' ? 'Owner Dashboard' : 'หน้าหลักสำหรับเจ้าของร้าน' }}
              </h1>
            </div>

            <p class="mt-2 text-muted">
              {{ state.language === 'en' ? 'Overview of restaurant orders and menu availability.' : 'ภาพรวมสถานะคำสั่งซื้อของร้านอาหารและการเปิดใช้งานเมนู' }}
            </p>
          </div>
        </div>

        <section class="grid gap-5 md:grid-cols-3">
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">
              {{ state.language === 'en' ? 'Live Orders' : 'คำสั่งซื้อปัจจุบัน' }}
            </p>
            <strong class="mt-2 block text-4xl text-brand">{{ liveOrders }}</strong>
            <span class="text-sm text-muted">
              {{ state.language === 'en' ? 'Currently active' : 'กำลังดำเนินการ' }}
            </span>
          </article>
          
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">
              {{ state.language === 'en' ? 'Available Items' : 'เมนูพร้อมขาย' }}
            </p>
            <strong class="mt-2 block text-4xl text-brand">{{ availableItemsCount }}</strong>
            <span class="text-sm text-muted">
              {{ state.language === 'en' ? 'Ready for customers' : 'พร้อมบริการลูกค้า' }}
            </span>
          </article>
          
          <article class="section-card p-5">
            <p class="text-sm font-bold text-muted">
              {{ state.language === 'en' ? 'Sold Out Items' : 'เมนูที่หมด' }}
            </p>
            <strong class="mt-2 block text-4xl text-brand">{{ soldOutItemsList.length }}</strong>
            <span class="text-sm text-muted">
              {{ state.language === 'en' ? 'Unavailable today' : 'ไม่พร้อมขายวันนี้' }}
            </span>
          </article>
        </section>

        <section class="mt-6 grid gap-5 xl:grid-cols-[1fr_320px]">
          <article class="section-card overflow-hidden">
            <div class="border-b border-stone-100 p-5">
              <h2 class="font-black">
                {{ state.language === 'en' ? 'Recent Orders' : 'คำสั่งซื้อล่าสุด' }}
              </h2>
            </div>
            <div class="divide-y divide-stone-100">
              <div
                v-for="order in state.orders.slice(0, 5)"
                :key="order.id"
                class="grid gap-3 p-5 sm:grid-cols-[1fr_1fr_1fr_1fr] sm:items-center"
              >
                <strong>#{{ order.orderNumber }}</strong>
                <span>{{ state.language === 'en' ? 'Table' : 'โต๊ะ' }} {{ order.tableNumber }}</span>
                <StatusPill :status="order.status" />
                <span class="text-sm text-muted">{{ order.time }}</span>
              </div>
            </div>
          </article>

          <article class="section-card p-5">
            <h2 class="font-black">
              {{ state.language === 'en' ? 'Menu Availability' : 'สถานะรายการเมนู' }}
            </h2>
            <div class="mt-4 space-y-3">
              <p
                v-for="item in soldOutItemsList"
                :key="item.id"
                class="flex items-center justify-between rounded-2xl bg-pale px-4 py-3 text-sm"
              >
                <span class="font-bold">
                  {{ state.language === 'th' ? (item.name_th || item.name) : item.name }}
                </span>
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
      <h2 class="text-lg font-black text-red-600">
        {{ state.language === 'en' ? 'Login Required' : 'จำเป็นต้องเข้าสู่ระบบ' }}
      </h2>

      <p class="mt-3 text-sm text-stone-600">
        {{ state.language === 'en' ? 'If you leave this page, you must log in again.' : 'หากคุณออกจากหน้านี้ คุณจะต้องเข้าสู่ระบบใหม่อีกครั้งเพื่อเข้าใช้งาน' }}
      </p>

      <div class="mt-6 flex justify-end gap-3">
        <button class="rounded-xl border px-4 py-2" @click="cancelExit">
          {{ state.language === 'en' ? 'Cancel' : 'ยกเลิก' }}
        </button>

        <button
          class="rounded-xl bg-red-600 px-4 py-2 text-white"
          @click="confirmExit"
        >
          {{ state.language === 'en' ? 'Exit' : 'ออกจากหน้านี้' }}
        </button>
      </div>
    </div>
  </div>
</template>