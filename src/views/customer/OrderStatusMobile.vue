<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { supabase } from "../../supabaseClient";
import { ArrowLeft } from "lucide-vue-next";
import { useAppState } from "../../services/appState";

const { state } = useAppState();
const route = useRoute();
const router = useRouter();
const orders = ref([]);
const loading = ref(true);

// --- ระบบจัดการภาษา ---
const t = {
  header: { en: "Order Status", th: "สถานะออเดอร์" },
  orderCode: { en: "Order Code", th: "รหัสออเดอร์" },
  items: { en: "Items", th: "รายการอาหาร" },
  total: { en: "Total", th: "ยอดรวม" },
  noHistory: { en: "No order history found", th: "ไม่พบประวัติการสั่งซื้อ" },
};
const text = (key) => t[key][state.language || "en"];

const fetchOrders = async () => {
  const tableId = route.params.orderId;

  const { data, error } = await supabase
    .from("orders")
    .select("*, order_items(*)")
    .eq("table_number", tableId)
    .neq("status", "paid")
    .order("created_at", { ascending: false });

  if (data) {
    orders.value = data;
  }
  loading.value = false;
};

let subscription;
onMounted(async () => {
  await fetchOrders();

  subscription = supabase
    .channel("order-status-channel")
    .on(
      "postgres_changes",
      {
        event: "UPDATE",
        schema: "public",
        table: "orders",
        filter: `table_number=eq.${route.params.orderId}`,
      },
      (payload) => {
        const index = orders.value.findIndex((o) => o.id === payload.new.id);
        if (index !== -1) {
          orders.value[index].status = payload.new.status;
        }
      },
    )
    .subscribe();
});

onUnmounted(() => {
  if (subscription) supabase.removeChannel(subscription);
});

// --- ปรับสี Status ให้ตรงกับหน้า Owner ---
const getStatusColor = (status) => {
  switch (status?.toLowerCase()) {
    case "pending": // เทียบเท่า 'new'
    case "new":
      return "bg-blue-100 text-blue-700 ring-2 ring-blue-400/20";
    case "cooking": // เทียบเท่า 'preparing'
    case "preparing":
      return "bg-amber-100 text-amber-700 ring-2 ring-amber-400/20";
    case "ready":
      return "bg-emerald-100 text-emerald-700 ring-2 ring-emerald-400/20";
    case "served": // เทียบเท่า 'completed'
    case "completed":
      return "bg-green-100 text-green-700 ring-2 ring-green-400/20";
    case "cancelled":
      return "bg-red-100 text-red-700 ring-2 ring-red-400/20";
    default:
      return "bg-stone-100 text-stone-600";
  }
};

// --- แปลงคำศัพท์ Status ให้ลูกค้าอ่านง่าย ---
const getStatusText = (status) => {
  const s = status?.toLowerCase();
  if (state.language === "th") {
    if (s === "pending" || s === "new") return "ออเดอร์ใหม่";
    if (s === "cooking" || s === "preparing") return "กำลังปรุง";
    if (s === "ready") return "พร้อมเสิร์ฟ";
    if (s === "served" || s === "completed") return "เสร็จสิ้น";
    if (s === "cancelled") return "ยกเลิกแล้ว";
  } else {
    if (s === "pending") return "New";
    if (s === "cooking") return "Preparing";
    if (s === "ready") return "Ready";
    if (s === "served") return "Completed";
    if (s === "cancelled") return "Cancelled";
  }
  return status;
};
</script>

<template>
  <div class="mobile-shell bg-stone-50 min-h-screen p-4">
    <div v-if="loading" class="text-center pt-20 text-stone-500 font-medium">
      Loading...
    </div>

    <div v-else class="max-w-md mx-auto">
      <header class="flex items-center mb-6">
        <button
          @click="router.back()"
          class="p-2 bg-white rounded-full shadow-sm active:scale-95 transition-transform"
        >
          <ArrowLeft />
        </button>
        <h1 class="ml-4 font-black text-lg text-stone-800">
          {{ text("header") }}
        </h1>
      </header>

      <div v-for="order in orders" :key="order.id" class="mb-8">
        <div
          class="bg-white rounded-3xl shadow-sm border border-stone-200 overflow-hidden transition-all hover:shadow-md"
        >
          <div
            class="p-6 text-center border-b border-stone-100 border-dashed relative"
          >
            <p class="text-stone-400 text-xs font-bold uppercase mb-2">
              {{ text("orderCode") }}
            </p>
            <h2 class="text-3xl font-black text-stone-900 mb-5">
              {{ order.order_code }}
            </h2>

            <!-- ป้ายสถานะสีใหม่ -->
            <div
              :class="[
                'inline-block px-5 py-2 rounded-full font-black uppercase text-xs tracking-wider shadow-sm transition-colors',
                getStatusColor(order.status),
              ]"
            >
              {{ getStatusText(order.status) }}
            </div>
          </div>

          <div class="p-6">
            <h3 class="font-bold text-stone-800 mb-4">{{ text("items") }}</h3>

            <div class="space-y-3">
              <div
                v-for="item in order.order_items"
                :key="item.id"
                class="flex justify-between py-2 border-b border-stone-50"
              >
                <span class="font-medium text-stone-700">
                  <span class="text-stone-400 font-bold mr-1"
                    >{{ item.quantity }}x</span
                  >
                  {{ item.menu_name }}
                </span>
                <span class="font-semibold text-stone-600">
                  {{ item.price_at_order.toLocaleString() }}
                  {{ state.language === "en" ? "B." : "บ." }}
                </span>
              </div>
            </div>

            <div
              class="flex justify-between mt-6 pt-2 font-black text-lg text-stone-900"
            >
              <span>{{ text("total") }}</span>
              <span
                >{{ order.total_price.toLocaleString() }}
                {{ state.language === "en" ? "B." : "บ." }}</span
              >
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="orders.length === 0"
        class="text-center text-stone-500 bg-white p-8 rounded-3xl border border-stone-200 shadow-sm"
      >
        {{ text("noHistory") }}
      </div>
    </div>
  </div>
</template>
