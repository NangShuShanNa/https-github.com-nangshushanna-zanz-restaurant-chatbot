<script setup>
import { Eye, EyeOff, Lock, Mail, ShieldCheck } from "@lucide/vue";
import { computed, ref, watch, onMounted } from "vue";
import { useRouter } from "vue-router";
import AppLogo from "../../components/AppLogo.vue";
import { supabase } from "../../supabaseClient";
import { useAppState } from "../../services/appState";

const props = defineProps({
  type: { type: String, required: true }, 
});

const router = useRouter();
const { state } = useAppState();

const email = ref("");
const password = ref("");
const showPassword = ref(false);
const showError = ref(false);
const errorMessage = ref("Invalid email or password.");

const title = computed(() =>
  props.type === "owner" ? "Admin Login" : "Staff Login",
);
const subtitle = computed(() =>
  props.type === "owner"
    ? "Manage menus, ingredients, allergens, and customer orders."
    : "Access live orders and update order status.",
);
const target = computed(() =>
  props.type === "owner" ? "/owner/dashboard" : "/staff/live-orders",
);

const emailPlaceholder = computed(() =>
  props.type === "owner" ? "e.g., admin@zank.com" : "e.g., kitchen@zank.com",
);

watch(email, (newValue) => {
  email.value = newValue.replace(/[^a-zA-Z0-9@._+-]/g, "");
});

watch(password, (newValue) => {
  password.value = newValue.replace(
    /[^a-zA-Z0-9!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/g,
    "",
  );
});

async function submit() {
  try {
    showError.value = false;

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.value)) {
      errorMessage.value =
        "Please enter a valid email address format (e.g., user@example.com).";
      showError.value = true;
      return;
    }

    if (!password.value) {
      errorMessage.value = "Password field cannot be empty.";
      showError.value = true;
      return;
    }

    console.log("-----------------------------------------");
    console.log("Checking credentials via RPC for:", email.value);

    const { data: profileData, error: profileError } = await supabase
      .rpc("verify_staff_login", {
        user_email: email.value,
        input_password: password.value,
      })
      .maybeSingle();

    console.log("Response received from Supabase RPC");

    if (profileError) {
      console.error("Supabase RPC Error:", profileError);
      errorMessage.value = "An error occurred while accessing the database.";
      throw profileError;
    }

    if (!profileData) {
      console.warn("Authentication failed: invalid email or password hash mismatch");
      errorMessage.value = "Invalid email or password.";
      showError.value = true;
      return;
    }

    console.log("Profile authenticated successfully:", profileData);

    const currentRole = profileData.role;
    let isRoleValid = false;

    if (props.type === "owner") {
      isRoleValid = currentRole === "admin";
    } else if (props.type === "staff") {
      isRoleValid = ["kitchen_staff", "reception_staff"].includes(currentRole);
    }

    console.log("Role Restrictions Verification");
    console.log("User Role:", currentRole);
    console.log("Login Type:", props.type);
    console.log("Role access authorization:", isRoleValid);

    if (!isRoleValid) {
      errorMessage.value = `This account does not have permission to access the ${title.value}.`;
      showError.value = true;
      return;
    }

    const userData = {
      id: profileData.id,
      email: profileData.email,
      role: currentRole, 
      restaurant_id: profileData.restaurant_id,
      restaurant_name: profileData.restaurant_name,
    };

    state.activeUser = userData;

    localStorage.setItem("zank-active-user", JSON.stringify(userData));

    console.log("CUSTOM LOGIN SUCCESS");
    console.log("USER SESSION REGISTERED:", userData);
    console.log("-----------------------------------------");

    router.push(target.value);
  } catch (error) {
    console.error("Login verification exception error:", error);
    showError.value = true;
  }
}

onMounted(() => {
  if (state.activeUser) {
    state.activeUser = null;
    localStorage.removeItem("zank-active-user");
  }
});
</script>

<template>
  <main class="page-shell min-h-screen px-5 py-8">
    <header class="mx-auto flex max-w-6xl items-center justify-between">
      <AppLogo />
      <span class="text-sm font-bold text-muted">EN / TH</span>
    </header>

    <section
      class="mx-auto mt-12 max-w-md rounded-[2rem] bg-white p-8 shadow-strong"
    >
      <div class="text-center">
        <div
          class="mx-auto mt-6 grid h-12 w-12 place-items-center rounded-full bg-pale text-brand"
        >
          <ShieldCheck :size="26" />
        </div>
        <h1 class="mt-5 text-3xl font-black">{{ title }}</h1>
        <p class="mt-2 text-sm leading-relaxed text-muted">{{ subtitle }}</p>
        <p class="mt-4 text-sm font-semibold text-brand">
          For authorized users only.
        </p>
      </div>

      <form class="mt-7 space-y-4" @submit.prevent="submit">
        <label class="block text-sm font-bold">
          Email address
          <span
            class="mt-2 flex items-center gap-2 rounded-2xl border border-stone-200 px-4 py-3"
          >
            <Mail :size="18" class="text-muted" />
            <input
              v-model="email"
              class="w-full outline-none"
              type="email"
              :placeholder="emailPlaceholder"
            />
          </span>
        </label>
        <label class="block text-sm font-bold">
          <span class="flex justify-between">
            Password
            <RouterLink to="/forgot-password" class="text-xs text-brand"
              >Forgot password?</RouterLink
            >
          </span>
          <span
            class="mt-2 flex items-center gap-2 rounded-2xl border border-stone-200 px-4 py-3"
          >
            <Lock :size="18" class="text-muted" />
            <input
              v-model="password"
              class="w-full outline-none"
              :type="showPassword ? 'text' : 'password'"
              placeholder="Enter your password"
            />
            <button
              type="button"
              class="grid h-8 w-8 shrink-0 place-items-center rounded-full text-muted transition hover:bg-pale hover:text-brand focus:outline-none focus:ring-2 focus:ring-brand/30"
              :aria-label="showPassword ? 'Hide password' : 'Show password'"
              :title="showPassword ? 'Hide password' : 'Show password'"
              @click="showPassword = !showPassword"
            >
              <EyeOff v-if="showPassword" :size="18" />
              <Eye v-else :size="18" />
            </button>
          </span>
        </label>

        <p v-if="showError" class="text-sm font-semibold text-red-600">
          {{ errorMessage }}
        </p>

        <label class="flex items-center gap-2 text-sm text-muted">
          <input type="checkbox" />
          Remember me
        </label>
        <button class="primary-btn w-full">Sign In</button>
      </form>

      <RouterLink
        to="/"
        class="mt-6 block text-center text-sm font-bold text-brand"
        >← Back to interface selection</RouterLink
      >
      <p
        class="mt-6 border-t border-stone-100 pt-5 text-center text-xs text-muted"
      >
        Only authorized accounts can access this dashboard.
      </p>
    </section>
  </main>
</template>