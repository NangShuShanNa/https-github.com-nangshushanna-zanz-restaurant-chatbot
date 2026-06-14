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

// 🌟 ดึง state เข้ามาร่วมด้วยเพื่อให้หน้าจอนี้อัปเดตแบบ Dynamic ตามปุ่มด้านบน
const { state, t, signOut } = useAppState();

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
  ออเดอร์สด: Monitor,
  รายการเมนู: MenuSquare,
  ออกจากระบบ: LogOut,
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
        <button
          v-if="item.label === 'Logout'"
          @click="showLogoutModal = true"
          class="flex w-full items-center gap-3 rounded-2xl px-4 py-3 text-left text-sm font-semibold text-stone-700 transition hover:bg-pale"
        >
          <component :is="iconMap[item.label] || Home" :size="20" />

          {{ state.language === "en" ? "Logout" : "ออกจากระบบ" }}
        </button>

        <RouterLink
          v-else
          :to="item.to"
          class="flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold text-stone-700 transition hover:bg-pale"
          active-class="bg-softGreen text-stone-950"
        >
          <component :is="iconMap[item.label] || Home" :size="20" />

          {{
            item.label === "Dashboard"
              ? state.language === "en"
                ? "Dashboard"
                : "หน้าหลัก"
              : item.label === "Menu Management"
                ? state.language === "en"
                  ? "Menu Management"
                  : "จัดการเมนูอาหาร"
                : item.label === "Orders"
                  ? state.language === "en"
                    ? "Orders"
                    : "คำสั่งซื้อ"
                  : item.label === "Staff Accounts"
                    ? state.language === "en"
                      ? "Staff Accounts"
                      : "บัญชีพนักงาน"
                    : t(item.label)
          }}
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

    <div
      v-if="showLogoutModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-xs"
    >
      <div
        class="w-full max-w-md rounded-3xl bg-white p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150"
      >
        <h2 class="text-lg font-black text-red-600">
          {{ state.language === "en" ? "Confirm Logout" : "ยืนยันออกจากระบบ" }}
        </h2>

        <p class="mt-3 text-sm text-stone-600 leading-relaxed">
          {{
            state.language === "en"
              ? "Are you sure you want to log out? You will need to sign in again."
              : "คุณต้องการออกจากระบบใช่หรือไม่? คุณจำเป็นต้องกรอกรหัสเข้าสู่ระบบใหม่อีกครั้งเพื่อใช้งาน"
          }}
        </p>

        <div class="mt-6 flex justify-end gap-3">
          <button
            class="rounded-xl border border-stone-200 px-4 py-2 font-medium text-stone-600 hover:bg-stone-50"
            @click="cancelLogout"
          >
            {{ state.language === "en" ? "Cancel" : "ยกเลิก" }}
          </button>

          <button
            class="rounded-xl bg-red-600 px-4 py-2 font-semibold text-white shadow-md hover:bg-red-700 active:scale-95 transition-all"
            @click="confirmLogout"
          >
            {{ state.language === "en" ? "Logout" : "ออกจากระบบ" }}
          </button>
        </div>
      </div>
    </div>
  </aside>
</template>
