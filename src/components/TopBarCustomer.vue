<script setup>
import { ref, onMounted, computed } from "vue";
import { Globe2, ShoppingCart, Utensils } from "@lucide/vue";
import AppLogo from "./AppLogo.vue";
import { useAppState } from "../services/appState";

defineProps({
  cartCount: {
    type: Number,
    default: 0,
  },
});

const searchQuery = defineModel({ type: String, default: "" });

const { state, toggleLanguage: baseToggleLanguage } = useAppState();

const tableNumber = ref("24");

function handleToggleLanguage() {
  baseToggleLanguage();
  localStorage.setItem("zank-language", state.language);
}

const tableLabel = computed(() => {
  return state.language === "en"
    ? `Table #${tableNumber.value}`
    : `โต๊ะ #${tableNumber.value}`;
});

async function fetchTableData() {
  try {
    const savedLanguage = localStorage.getItem("zank-language");
    if (savedLanguage && state.language !== savedLanguage) {
      state.language = savedLanguage;
    }

    const savedTable = localStorage.getItem("zank-table-number");
    if (savedTable) {
      tableNumber.value = savedTable;
    }
  } catch (error) {
    console.error("Error syncing table data:", error);
  }
}

onMounted(() => {
  fetchTableData();
});
</script>

<template>
  <header
    class="sticky top-0 z-20 flex h-20 items-center justify-between border-b border-stone-100 bg-white/95 px-5 backdrop-blur"
  >
    <div class="flex items-center gap-4">
      <AppLogo to="/customer/menu" />
    </div>

    <div class="flex items-center gap-4">
      <button
        class="hidden items-center gap-2 rounded-full px-3 py-2 text-sm text-stone-700 transition hover:bg-pale sm:flex"
        @click="handleToggleLanguage"
      >
        <Globe2 :size="20" />
        <span class="flex gap-1">
          <span
            :class="
              state.language === 'en'
                ? 'font-black text-stone-900'
                : 'font-normal text-stone-400'
            "
            >EN</span
          >
          <span class="text-stone-300">/</span>
          <span
            :class="
              state.language === 'th'
                ? 'font-black text-stone-900'
                : 'font-normal text-stone-400'
            "
            >TH</span
          >
        </span>
      </button>

      <RouterLink
        to="/customer/cart"
        class="relative z-30 inline-flex h-11 w-11 cursor-pointer items-center justify-center rounded-full text-stone-900 transition hover:bg-pale focus:outline-none focus:ring-2 focus:ring-brand/40"
        :aria-label="state.language === 'en' ? 'Open cart' : 'เปิดตะกร้า'"
        :title="state.language === 'en' ? 'Open cart' : 'เปิดตะกร้า'"
      >
        <ShoppingCart :size="24" />
        <span
          v-if="cartCount"
          class="absolute -right-2 -top-2 grid h-6 w-6 place-items-center rounded-full bg-brand text-xs font-bold text-white"
        >
          {{ cartCount }}
        </span>
      </RouterLink>

      <div
        class="relative flex items-center gap-2 rounded-full border border-stone-100 p-3 pr-5 bg-stone-50"
      >
        <div class="rounded-full text-stone-600">
          <Utensils :size="22" class="mx-1 text-brand" />
        </div>
        <div class="flex flex-col text-left leading-tight">
          <span class="text-sm font-black text-stone-900">{{
            tableLabel
          }}</span>
          <span class="text-xs font-medium text-stone-400">
            {{ state.language === "en" ? "Dine-in Service" : "ทานที่ร้าน" }}
          </span>
        </div>
      </div>
    </div>
  </header>
</template>
