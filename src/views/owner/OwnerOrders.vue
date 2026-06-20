<script setup>
import { computed, ref, onMounted, onUnmounted } from "vue";
import { supabase } from "../../supabaseClient";
import MobileNav from "../../components/MobileNav.vue";
import SideNav from "../../components/SideNav.vue";
import StatusPill from "../../components/StatusPill.vue";
import TopBar from "../../components/TopBar.vue";
import { useAppState } from "../../services/appState";

const { state } = useAppState();
const orders = ref([]);
const selected = ref(null);
const filter = ref("all");
const loading = ref(true);
let realTimeSubscription = null;

const ownerNav = [
  { label: "Dashboard", to: "/owner/dashboard", short: "Home" },
  { label: "Menu Management", to: "/owner/menu-management", short: "Menu" },
  { label: "Orders", to: "/owner/orders" },
  { label: "Staff Accounts", to: "/owner/staff-accounts", short: "Staff" },
  { label: "Logout", to: "/logout", short: "Logout" },
];

const statuses = [
  "all",
  "new",
  "preparing",
  "ready",
  "completed",
  "allergy orders",
];
const steps = ["new", "preparing", "ready", "completed"];

function mapDbStatusToUi(dbStatus) {
  const mapping = {
    pending: "new",
    preparing: "preparing",
    ready: "ready",
    served: "completed",
  };
  return mapping[dbStatus] || dbStatus;
}

function mapUiStatusToDb(uiStatus) {
  const mapping = {
    new: "pending",
    preparing: "preparing",
    ready: "ready",
    completed: "served",
  };
  return mapping[uiStatus] || uiStatus;
}

function formatOrder(dbOrder) {
  const dbItems = dbOrder.order_items || [];

  const formattedItems = dbItems.map((item) => {
    // แก้ไขจุดนี้: ดึงค่าจากคอลัมน์ price_at_order ตามโครงสร้างตารางจริงของคุณ
    let itemPrice = parseFloat(item.price_at_order || item.price || 0);

    return {
      name: item.menu_name || "ไม่ระบุชื่อเมนู",
      quantity: parseInt(item.quantity || 1),
      price: itemPrice,
      note: item.note || "",
    };
  });

  // กรองเมนูที่มี note ขึ้นต้นด้วย No (เช่น "No onion") เป็น Allergy Alert
  const allergyList = formattedItems
    .filter((item) => item.note && /^no/i.test(item.note.trim()))
    .map((item) => item.note.trim());

  return {
    id: dbOrder.id,
    orderNumber: dbOrder.order_code || dbOrder.id,
    tableNumber: dbOrder.table_number || "N/A",
    status: mapDbStatusToUi(dbOrder.status),
    allergies: allergyList,
    items: formattedItems,
    customerNote: dbOrder.customer_note || "",
    totalPrice: parseFloat(dbOrder.total_price || 0), // ดึงราคารวมจากตาราง orders
    time: new Date(dbOrder.created_at).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    }),
    raw: dbOrder,
  };
}

async function fetchOrders() {
  loading.value = true;
  const { data, error } = await supabase
    .from("orders")
    .select("*, order_items(*)")
    .order("created_at", { ascending: true });

  if (!error && data) {
    orders.value = data.map(formatOrder);

    if (selected.value) {
      const updatedSelected = orders.value.find(
        (o) => o.id === selected.value.id,
      );
      if (updatedSelected) {
        selected.value = updatedSelected;
      } else {
        selected.value = orders.value.length > 0 ? orders.value[0] : null;
      }
    } else if (orders.value.length > 0) {
      selected.value = orders.value[0];
    }
  } else {
    console.error("Error fetching orders:", error);
  }
  loading.value = false;
}

async function updateOrderStatus(orderId, currentUiStatus) {
  const currentIdx = steps.indexOf(currentUiStatus);
  if (currentIdx >= steps.length - 1) return;

  const nextUiStatus = steps[currentIdx + 1];
  const nextDbStatus = mapUiStatusToDb(nextUiStatus);

  const orderIndex = orders.value.findIndex((o) => o.id === orderId);
  if (orderIndex !== -1) orders.value[orderIndex].status = nextUiStatus;
  if (selected.value && selected.value.id === orderId)
    selected.value.status = nextUiStatus;

  const { error } = await supabase
    .from("orders")
    .update({ status: nextDbStatus })
    .eq("id", orderId);

  if (error) {
    console.error("Error updating status:", error);
    fetchOrders();
  }
}

async function cancelOrder(orderId) {
  const confirmCancel = confirm(
    state.language === "en"
      ? "Are you sure you want to cancel this order?"
      : "คุณแน่ใจหรือไม่ที่จะยกเลิกคำสั่งซื้อนี้?",
  );
  if (!confirmCancel) return;

  const { error } = await supabase
    .from("orders")
    .update({ status: "cancelled" })
    .eq("id", orderId);

  if (!error) {
    fetchOrders();
  } else {
    console.error("Error cancelling order:", error);
  }
}

function getStatusLabel(statusKey) {
  const labels = {
    all: state.language === "en" ? "All" : "ทั้งหมด",
    new: state.language === "en" ? "New" : "ออเดอร์ใหม่",
    preparing: state.language === "en" ? "Preparing" : "กำลังปรุง",
    ready: state.language === "en" ? "Ready" : "พร้อมเสิร์ฟ",
    completed: state.language === "en" ? "Completed" : "เสร็จสิ้น",
    "allergy orders":
      state.language === "en" ? "Allergy Orders" : "ออเดอร์แพ้อาหาร",
  };
  return labels[statusKey?.toLowerCase()] || statusKey;
}

const filteredOrders = computed(() =>
  orders.value.filter((order) => {
    if (filter.value === "all") return true;
    if (filter.value === "allergy orders")
      return order.allergies && order.allergies.length > 0;
    return order.status === filter.value;
  }),
);

const counts = computed(() => ({
  new: orders.value.filter((order) => order.status === "new").length,
  preparing: orders.value.filter((order) => order.status === "preparing")
    .length,
  ready: orders.value.filter((order) => order.status === "ready").length,
  completed: orders.value.filter((order) => order.status === "completed")
    .length,
}));

const orderTotal = computed(() =>
  selected.value ? selected.value.totalPrice : 0,
);

const canCancel = computed(
  () =>
    selected.value &&
    !["completed", "cancelled"].includes(selected.value.status),
);
const canAdvance = computed(
  () =>
    selected.value && steps.indexOf(selected.value.status) < steps.length - 1,
);

onMounted(() => {
  const savedLanguage = localStorage.getItem("zank-language");
  if (savedLanguage) {
    state.language = savedLanguage;
  }

  fetchOrders();

  realTimeSubscription = supabase
    .channel("public:orders-changes")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "orders" },
      () => fetchOrders(),
    )
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "order_items" },
      () => fetchOrders(),
    )
    .subscribe();
});

onUnmounted(() => {
  if (realTimeSubscription) {
    supabase.removeChannel(realTimeSubscription);
  }
});
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search order number, table, or item" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <h1 class="text-4xl font-black">
          {{
            state.language === "en" ? "Order Management" : "การจัดการคำสั่งซื้อ"
          }}
        </h1>
        <p class="mt-2 text-muted">
          {{
            state.language === "en"
              ? "Monitor customer orders and review order details."
              : "ตรวจสอบสถานะคำสั่งซื้อจากลูกค้าและดูรายละเอียดประวัติรายการอาหาร"
          }}
        </p>

        <section class="mt-6 grid gap-4 sm:grid-cols-2 md:grid-cols-4">
          <article
            v-for="(count, status) in counts"
            :key="status"
            class="section-card p-5 flex flex-col justify-between"
          >
            <p class="text-sm font-bold capitalize text-muted">
              {{ getStatusLabel(status) }}
            </p>
            <strong class="text-3xl font-black text-brand mt-2 block">
              <span v-if="loading" class="animate-pulse text-stone-300"
                >...</span
              >
              <span v-else>{{ count }}</span>
            </strong>
          </article>
        </section>

        <div class="mt-6 flex flex-wrap gap-2">
          <button
            v-for="status in statuses"
            :key="status"
            class="rounded-full px-5 py-2.5 text-sm font-bold shadow-sm border border-stone-100/50 transition hover:opacity-90 active:scale-95"
            :class="
              filter === status
                ? 'bg-softGreen text-brand ring-2 ring-brand/10'
                : 'bg-white text-muted'
            "
            @click="filter = status"
          >
            {{ getStatusLabel(status) }}
          </button>
        </div>

        <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_400px] items-start">
          <article class="section-card overflow-hidden">
            <div
              class="hidden bg-pale px-5 py-4 text-xs font-black text-brand tracking-wider uppercase lg:grid lg:grid-cols-[1fr_.8fr_1fr_1.2fr_1fr_auto]"
            >
              <span>{{
                state.language === "en" ? "Order No" : "เลขที่ออเดอร์"
              }}</span>
              <span>{{ state.language === "en" ? "Table" : "โต๊ะ" }}</span>
              <span>{{
                state.language === "en" ? "Items" : "จำนวนรายการ"
              }}</span>
              <span>{{
                state.language === "en" ? "Allergy Alert" : "ข้อมูลแพ้อาหาร"
              }}</span>
              <span>{{ state.language === "en" ? "Status" : "สถานะ" }}</span>
              <span class="text-right pr-4">{{
                state.language === "en" ? "Action" : "จัดการ"
              }}</span>
            </div>

            <div
              v-if="loading && orders.length === 0"
              class="p-10 text-center text-muted animate-pulse"
            >
              {{
                state.language === "en"
                  ? "Loading orders..."
                  : "กำลังโหลดข้อมูล..."
              }}
            </div>

            <div
              v-else-if="filteredOrders.length === 0"
              class="p-10 text-center text-muted"
            >
              {{
                state.language === "en"
                  ? "No orders found matching this filter."
                  : "ไม่พบคำสั่งซื้อในหมวดหมู่นี้"
              }}
            </div>

            <button
              v-else
              v-for="order in filteredOrders"
              :key="order.id"
              class="grid w-full gap-3 border-t border-stone-100 p-5 text-left transition hover:bg-pale lg:grid-cols-[1fr_.8fr_1fr_1.2fr_1fr_auto] lg:items-center"
              :class="
                selected?.id === order.id ? 'bg-pale ring-2 ring-brand/20' : ''
              "
              @click="selected = order"
            >
              <strong class="text-stone-900">#{{ order.orderNumber }}</strong>
              <span class="font-medium text-stone-600">{{
                order.tableNumber
              }}</span>
              <span class="text-stone-600"
                >{{ order.items.length }}
                {{ state.language === "en" ? "items" : "รายการ" }}</span
              >

              <span
                :class="
                  order.allergies && order.allergies.length
                    ? 'text-red-600 font-bold'
                    : 'text-stone-400'
                "
              >
                {{
                  order.allergies && order.allergies.length
                    ? order.allergies.join(", ")
                    : state.language === "en"
                      ? "None"
                      : "ไม่มี"
                }}
              </span>

              <StatusPill :status="order.status" />
              <span
                class="font-bold text-brand text-right lg:pr-4 text-sm whitespace-nowrap"
              >
                {{ state.language === "en" ? "View Details" : "ดูรายละเอียด" }}
              </span>
            </button>
          </article>

          <aside
            v-if="selected"
            class="section-card p-5 sticky top-24 shadow-strong z-10 flex flex-col h-[calc(100vh-140px)] bg-white overflow-y-auto custom-scrollbar"
          >
            <div class="border-b border-stone-100 pb-3">
              <h2 class="text-xl font-black text-stone-900">
                {{ state.language === "en" ? "Order" : "คำสั่งซื้อ" }} #{{
                  selected.orderNumber
                }}
              </h2>
              <p class="mt-1 text-sm text-muted">
                {{ selected.tableNumber }} · {{ selected.time }}
              </p>
              <div class="mt-3"><StatusPill :status="selected.status" /></div>
            </div>

            <div class="flex-1 overflow-y-auto py-4 space-y-4">
              <p
                v-if="selected.allergies && selected.allergies.length"
                class="rounded-2xl bg-red-50 px-4 py-3 text-sm font-bold text-red-700 border border-red-100 animate-pulse"
              >
                {{
                  state.language === "en"
                    ? "Allergy Alert:"
                    : "แจ้งเตือนลูกค้าแพ้อาหาร:"
                }}
                {{ selected.allergies.join(", ") }}
              </p>

              <p
                v-if="selected.customerNote"
                class="rounded-2xl bg-pale px-4 py-3 text-sm text-stone-600 border border-stone-100/50 italic"
              >
                {{
                  state.language === "en"
                    ? "Customer note:"
                    : "หมายเหตุจากลูกค้า:"
                }}
                “{{ selected.customerNote }}”
              </p>

              <div class="space-y-2.5">
                <div
                  v-for="item in selected.items"
                  :key="item.name"
                  class="bg-stone-50/50 p-2.5 rounded-xl border border-stone-100/30"
                >
                  <div class="flex justify-between text-sm items-center">
                    <span class="text-stone-800 font-medium">
                      <span class="font-black text-brand mr-1"
                        >{{ item.quantity }}×</span
                      >
                      {{ item.name }}
                    </span>
                    <strong class="text-stone-500"
                      >{{ item.price * item.quantity }} Baht</strong
                    >
                  </div>
                  <p
                    v-if="item.note"
                    class="text-xs text-stone-500 mt-1 pl-6 italic"
                  >
                    * {{ item.note }}
                  </p>
                </div>
              </div>
            </div>

            <div class="border-t border-stone-100 pt-4 bg-white mt-auto">
              <p
                class="flex justify-between text-lg font-black text-stone-900 mb-4"
              >
                <span>{{
                  state.language === "en" ? "Total" : "ยอดรวมสุทธิ"
                }}</span>
                <span class="text-brand text-xl">{{ orderTotal }} Baht</span>
              </p>

              <div class="grid grid-cols-2 gap-2 mb-4">
                <span
                  v-for="step in steps"
                  :key="step"
                  class="rounded-xl border py-2 text-center text-xs font-bold"
                  :class="
                    steps.indexOf(step) <= steps.indexOf(selected.status)
                      ? 'border-brand bg-pale text-brand'
                      : 'border-stone-100 text-muted'
                  "
                >
                  {{ getStatusLabel(step) }}
                </span>
              </div>

              <div class="flex flex-col gap-2">
                <button
                  v-if="canAdvance"
                  class="w-full rounded-full border border-brand bg-brand py-3 font-black text-white transition hover:bg-brand/90 active:scale-95 shadow-sm"
                  @click="updateOrderStatus(selected.id, selected.status)"
                >
                  {{
                    state.language === "en"
                      ? "Mark as " +
                        getStatusLabel(
                          steps[steps.indexOf(selected.status) + 1],
                        )
                      : "อัปเดตสถานะเป็น " +
                        getStatusLabel(
                          steps[steps.indexOf(selected.status) + 1],
                        )
                  }}
                </button>

                <button
                  v-if="canCancel"
                  class="w-full rounded-full border border-red-200 bg-red-50 py-3 font-black text-red-700 transition hover:bg-red-100 active:scale-95"
                  @click="cancelOrder(selected.id)"
                >
                  {{
                    state.language === "en"
                      ? "Cancel Order"
                      : "ยกเลิกคำสั่งซื้อนี้"
                  }}
                </button>
              </div>

              <p
                v-if="!canAdvance && !canCancel"
                class="rounded-2xl bg-stone-100 py-3 text-center text-sm font-bold text-muted"
              >
                {{
                  state.language === "en"
                    ? "Order finalized. No further action available."
                    : "เสร็จสิ้นขั้นตอนแล้ว ไม่สามารถจัดการเพิ่มเติมได้"
                }}
              </p>
            </div>
          </aside>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>
