<script setup>
import { computed, ref, onMounted } from "vue";
import { Globe2, ShoppingCart, UserCircle, LogOut } from "@lucide/vue";
import AppLogo from "./AppLogo.vue";
import { useAppState } from "../services/appState";
import { supabase } from "../supabaseClient";
import { useRouter } from "vue-router";

defineProps({
  cartCount: { type: Number, default: 0 },
  modelValue: { type: String, default: "" },
  searchPlaceholder: {
    type: String,
    default: "Search dishes, ingredients, or taste",
  },
  owner: { type: Boolean, default: false },
});

defineEmits(["update:modelValue"]);

const router = useRouter();
const { state, toggleLanguage: baseToggleLanguage } = useAppState();

const userEmail = ref("");
const dbRole = ref("");

/**
 * Custom toggle language function that also persists the choice globally across screens
 */
function handleToggleLanguage() {
  // 1. Execute the state manager's original translation switch
  baseToggleLanguage();

  // 2. Persist the updated configuration state globally into localStorage
  localStorage.setItem("zank-language", state.language);
}

const accountLabel = computed(() => {
  const role = dbRole.value?.toLowerCase();
  if (role === "admin" || role === "owner") {
    return state.language === "en" ? "Owner / Admin" : "เจ้าของร้าน / แอดมิน";
  }
  if (role === "kitchen_staff" || role === "reception_staff") {
    return state.language === "en" ? "Staff" : "พนักงาน";
  }
  return state.language === "en" ? "Customer" : "ลูกค้าทั่วไป";
});

async function fetchUserData() {
  try {
    // Sync language selection from previous global layout configurations
    const savedLanguage = localStorage.getItem("zank-language");
    if (savedLanguage && state.language !== savedLanguage) {
      state.language = savedLanguage;
    }

    // Switched to using sessionStorage to ensure multiple login tabs remain independent and do not conflict.
    const savedUserJson = sessionStorage.getItem("zank-active-user");

    if (savedUserJson) {
      const localUser = JSON.parse(savedUserJson);

      userEmail.value = localUser.email;
      dbRole.value = localUser.role || "customer";
      state.activeUser = localUser;
    } else {
      userEmail.value = state.language === "en" ? "Guest" : "ลูกค้าทั่วไป";
      dbRole.value = "customer";
    }
  } catch (error) {
    console.error("Error fetching user data from sessionStorage:", error);
    userEmail.value = state.language === "en" ? "Guest" : "ลูกค้าทั่วไป";
    dbRole.value = "customer";
  }
}

async function handleLogout() {
  // Clear user data from sessionStorage upon logging out.
  sessionStorage.removeItem("zank-active-user");
  state.activeUser = null;
  await supabase.auth.signOut();
  router.push("/");
}

onMounted(() => {
  fetchUserData();
});
</script>

<template>
  <header
    class="sticky top-0 z-20 flex h-20 items-center justify-between border-b border-stone-100 bg-white/95 px-5 backdrop-blur"
  >
    <div class="flex items-center gap-4">
      <AppLogo
        :to="
          dbRole?.toLowerCase() === 'admin' || dbRole?.toLowerCase() === 'owner'
            ? '/owner/dashboard'
            : '/'
        "
      />
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

      <div
        class="relative flex items-center gap-2 rounded-full border border-stone-100 p-3 pr-4 bg-stone-50"
      >
        <div class="rounded-full text-stone-600">
          <UserCircle :size="30" />
        </div>

        <div class="hidden flex-col text-left leading-tight md:flex">
          <span
            class="text-sm font-bold text-stone-900 max-w-[150px] truncate"
            >{{ userEmail }}</span
          >
          <span class="text-xs font-medium text-stone-500">{{
            accountLabel
          }}</span>
        </div>
      </div>
    </div>
  </header>
</template>
