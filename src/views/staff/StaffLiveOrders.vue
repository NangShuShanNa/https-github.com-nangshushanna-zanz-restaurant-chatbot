<script setup>
import { computed, ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { Globe2, ShoppingCart, UserCircle } from "@lucide/vue";
import MobileNav from "../../components/MobileNav.vue";
import SideNav from "../../components/SideNav.vue";
import StatusPill from "../../components/StatusPill.vue";
import TopBar from "../../components/TopBar.vue";
import { useAppState } from "../../services/appState";

const router = useRouter();
const { state, toggleLanguage, updateOrderStatus, signOut } = useAppState();

const columns = computed(() => [
  {
    status: "new",
    title: state.language === "en" ? "New Tasks" : "ออเดอร์ใหม่",
    action: state.language === "en" ? "Start Preparing" : "เริ่มเตรียมอาหาร",
    next: "preparing",
  },
  {
    status: "preparing",
    title: state.language === "en" ? "Preparing" : "กำลังปรุง",
    action: state.language === "en" ? "Mark Ready" : "ปรุงเสร็จแล้ว",
    next: "ready",
  },
  {
    status: "ready",
    title: state.language === "en" ? "Ready for Pickup" : "พร้อมเสิร์ฟ",
    action: state.language === "en" ? "Mark Completed" : "เสิร์ฟเรียบร้อย",
    next: "completed",
  },
  {
    status: "completed",
    title: state.language === "en" ? "Completed" : "เสร็จสิ้น",
    action: "",
    next: "",
  },
]);

const navItems = computed(() => [
  {
    label: state.language === "en" ? "Live Orders" : "ออเดอร์สด",
    to: "/staff/live-orders",
    short: "Orders",
  },
  {
    label: state.language === "en" ? "Menu Items" : "รายการเมนู",
    to: "/staff/menu-items",
    short: "Menu",
  },
  {
    label: state.language === "en" ? "Logout" : "ออกจากระบบ",
    to: "/logout",
    short: "Logout",
  },
]);

const filterButtons = computed(() => [
  { id: "all", en: "All Matches", th: "ทั้งหมด" },
  { id: "dine_in", en: "Dine-In Only", th: "ทานที่ร้าน" },
  { id: "allergies", en: "Allergy Alerts", th: "แจ้งเตือนการแพ้" },
  { id: "ready_soon", en: "Ready Soon", th: "ใกล้เสร็จ" },
]);

const liveCount = computed(
  () =>
    state.orders.filter(
      (order) => !["completed", "cancelled"].includes(order.status),
    ).length,
);

function logout() {
  signOut();
  router.push("/");
}
</script>

<template>
  <div class="page-shell">
    <TopBar
      :search-placeholder="
        state.language === 'en'
          ? 'Search orders, table, or item'
          : 'ค้นหาออเดอร์, โต๊ะ หรือรายการอาหาร'
      "
    />

    <div class="content-shell">
      <SideNav :items="navItems" />

      <main class="main-panel">
        <header class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-4xl font-black tracking-tight text-stone-900">
              {{
                state.language === "en"
                  ? "Kitchen Order Tracker"
                  : "ระบบติดตามออเดอร์ห้องครัว"
              }}
            </h1>
            <p class="mt-2 text-muted">
              {{
                state.language === "en"
                  ? "Monitor live incoming orders and update production tracking states."
                  : "จัดการสถานะรายการอาหารที่กำลังสั่งเข้ามาในระบบห้องครัวแบบสดใหม่"
              }}
            </p>
          </div>
        </header>

        <div class="mb-6 flex flex-wrap items-center gap-2">
          <button
            v-for="(btn, idx) in filterButtons"
            :key="btn.id"
            :class="
              idx === 0
                ? 'rounded-full bg-brand px-4 py-2 text-xs font-bold text-white shadow-sm'
                : 'rounded-full bg-white px-4 py-2 text-xs font-medium text-stone-600 shadow-sm transition hover:bg-stone-50'
            "
          >
            {{ state.language === "en" ? btn.en : btn.th }}
          </button>
        </div>

        <section class="grid gap-6 sm:grid-cols-2 xl:grid-cols-4 items-start">
          <div
            v-for="column in columns"
            :key="column.status"
            class="flex flex-col rounded-3xl bg-white p-4 shadow-soft border min-h-[600px] transition-all duration-200"
            :class="[
              column.status === 'new'
                ? 'border-blue-100 ring-4 ring-blue-50/30'
                : '',
              column.status === 'preparing'
                ? 'border-amber-100 ring-4 ring-amber-50/30'
                : '',
              column.status === 'ready'
                ? 'border-brand/20 ring-4 ring-pale/40'
                : '',
              column.status === 'completed'
                ? 'border-stone-200 bg-stone-50/40'
                : '',
            ]"
          >
            <div
              class="mb-4 flex items-center justify-between pb-3 border-b"
              :class="[
                column.status === 'new' ? 'border-blue-100' : '',
                column.status === 'preparing' ? 'border-amber-100' : '',
                column.status === 'ready' ? 'border-stone-100' : '',
                column.status === 'completed' ? 'border-stone-200' : '',
              ]"
            >
              <div class="flex items-center gap-2">
                <span
                  class="h-2.5 w-2.5 rounded-full"
                  :class="[
                    column.status === 'new' ? 'bg-blue-500 animate-pulse' : '',
                    column.status === 'preparing' ? 'bg-amber-500' : '',
                    column.status === 'ready' ? 'bg-brand' : '',
                    column.status === 'completed' ? 'bg-stone-400' : '',
                  ]"
                ></span>
                <h2
                  class="font-black text-stone-800 tracking-wide text-sm uppercase"
                >
                  {{ column.title }}
                </h2>
              </div>

              <span
                class="grid h-6 min-w-6 place-items-center rounded-full px-2 text-xs font-black shadow-xs"
                :class="[
                  column.status === 'new'
                    ? 'bg-blue-50 text-blue-700 border border-blue-100'
                    : '',
                  column.status === 'preparing'
                    ? 'bg-amber-50 text-amber-700 border border-amber-100'
                    : '',
                  column.status === 'ready'
                    ? 'bg-pale text-brand border border-brand/10'
                    : '',
                  column.status === 'completed'
                    ? 'bg-stone-200 text-stone-600'
                    : '',
                ]"
              >
                {{
                  state.orders.filter((order) => order.status === column.status)
                    .length
                }}
              </span>
            </div>

            <div class="flex-1 space-y-4 overflow-y-auto max-h-[700px] pr-1">
              <article
                v-for="order in state.orders.filter(
                  (order) => order.status === column.status,
                )"
                :key="order.id"
                class="section-card rounded-2xl bg-white p-5 border border-stone-100/80 transition-all duration-200 hover:shadow-md hover:-translate-y-0.5"
                :class="
                  column.status === 'completed'
                    ? 'opacity-70 grayscale-[30%]'
                    : ''
                "
              >
                <div class="flex items-start justify-between gap-3">
                  <div>
                    <h3 class="font-black text-lg text-stone-900">
                      #{{ order.orderNumber }}
                    </h3>
                    <p class="text-xs font-medium text-stone-500 mt-0.5">
                      {{ state.language === "en" ? "Table" : "โต๊ะ" }}
                      {{ order.tableNumber }} &middot; {{ order.time }}
                    </p>
                  </div>
                  <StatusPill :status="order.status" />
                </div>

                <div
                  class="mt-4 space-y-2.5 border-t border-stone-100 pt-3 text-sm text-stone-800"
                >
                  <div
                    v-for="item in order.items"
                    :key="item.name"
                    class="leading-relaxed"
                  >
                    <p class="font-medium">
                      <span class="text-brand font-bold mr-1.5"
                        >{{ item.quantity }}&times;</span
                      >
                      {{ item.name }}
                    </p>
                    <span
                      v-if="item.note"
                      class="mt-0.5 block text-xs font-medium text-amber-700 bg-amber-50 rounded px-2 py-0.5 w-fit"
                    >
                      {{
                        state.language === "en" ? "Mod" : "หมายเหตุเพิ่มเติม"
                      }}: {{ item.note }}
                    </span>
                  </div>
                </div>

                <div
                  v-if="order.allergies.length"
                  class="mt-4 rounded-xl bg-red-50 border border-red-100 p-3 text-xs font-bold text-red-800 shadow-xs"
                >
                  {{
                    state.language === "en"
                      ? "ALLERGY ALERT"
                      : "แจ้งเตือนข้อมูลคนแพ้อาหาร"
                  }}: {{ order.allergies.join(", ") }}
                </div>

                <blockquote
                  v-if="order.customerNote"
                  class="mt-3 rounded-xl bg-stone-50 border border-stone-200/50 px-3 py-2 text-xs italic text-stone-600"
                >
                  &ldquo;{{ order.customerNote }}&rdquo;
                </blockquote>

                <div class="mt-5 border-t border-stone-100 pt-3">
                  <button
                    v-if="column.action"
                    class="w-full rounded-xl py-2.5 text-xs font-bold tracking-wider uppercase transition active:scale-95 shadow-sm border"
                    :class="[
                      column.status === 'new'
                        ? 'bg-blue-600 hover:bg-blue-700 text-white border-transparent'
                        : '',
                      column.status === 'preparing'
                        ? 'bg-amber-500 hover:bg-amber-600 text-white border-transparent'
                        : '',
                      column.status === 'ready'
                        ? 'bg-brand hover:bg-brandDark text-white border-transparent'
                        : '',
                    ]"
                    @click="updateOrderStatus(order.orderNumber, column.next)"
                  >
                    {{ column.action }}
                  </button>
                  <div
                    v-else
                    class="rounded-xl bg-stone-100 border border-stone-200 py-2 text-center text-xs font-bold text-stone-500 tracking-wide uppercase"
                  >
                    {{
                      state.language === "en"
                        ? "Archived Out"
                        : "จัดเก็บเรียบร้อย"
                    }}
                  </div>
                </div>
              </article>
            </div>
          </div>
        </section>
      </main>
    </div>

    <MobileNav :items="navItems" />
  </div>
</template>
