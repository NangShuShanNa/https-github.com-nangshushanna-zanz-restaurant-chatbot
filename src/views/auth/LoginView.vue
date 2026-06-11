<script setup>
import { Eye, EyeOff, Lock, Mail, ShieldCheck } from "@lucide/vue";
import { computed, ref } from "vue";
import { onMounted } from 'vue';
import { useRouter } from "vue-router";
import AppLogo from "../../components/AppLogo.vue";
import { supabase } from "../../supabaseClient";
import { useAppState } from "../../services/appState";

const props = defineProps({
  type: { type: String, required: true }, // Expects 'owner' or 'staff'
});

const router = useRouter();
const { state } = useAppState();

// 🌟 Starts with an empty field instead of autofilling real credentials
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
const demoPassword = computed(() =>
  props.type === "owner" ? "admin123" : "staff123",
);

// 🌟 Dynamically generates a helpful grey placeholder example inside the input box
const emailPlaceholder = computed(() =>
  props.type === "owner" ? "e.g., admin@zank.com" : "e.g., kitchen@zank.com",
);

// Real-time Block: Restrict input fields to English characters, numbers, and basic symbols only
function validateEnglishOnly(event, type) {
  const input = event.target;
  let cleanedValue = "";

  if (type === "email") {
    // Allows A-Z, a-z, 0-9, and specific characters used in emails (@, ., _, -, +)
    cleanedValue = input.value.replace(/[^a-zA-Z0-9@._+-]/g, "");
  } else if (type === "password") {
    // Allows A-Z, a-z, 0-9, and standard password special characters
    cleanedValue = input.value.replace(
      /[^a-zA-Z0-9!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/g,
      "",
    );
  }

  // Update the ref values instantly
  if (type === "email") email.value = cleanedValue;
  if (type === "password") password.value = cleanedValue;
}

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

    // Login with Supabase
    const { data: authData, error: authError } =
      await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
      });

    if (authError) {
      errorMessage.value = "Invalid email or password.";
      throw authError;
    }

    const userId = authData.user.id;
    const userEmail = authData.user.email;

    // Get role from profiles table
    let { data: profileData, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", userId)
      .maybeSingle();

    if (profileError) {
      errorMessage.value = "An error occurred while verifying permissions.";
      throw profileError;
    }

    // Create profile automatically if not found
    if (!profileData) {
      const defaultRole = props.type === "owner" ? "admin" : "staff";

      const { data: newProfile, error: insertError } = await supabase
        .from("profiles")
        .insert([
          {
            id: userId,
            email: userEmail,
            role: defaultRole,
          },
        ])
        .select("role")
        .single();

      if (insertError) {
        errorMessage.value = "Failed to initialize user permissions.";
        throw insertError;
      }

      profileData = newProfile;
    }

    const currentRole = profileData.role;
    const expectedRole = props.type === "owner" ? "admin" : "staff";

    // Prevent wrong role login
    if (currentRole !== expectedRole) {
      errorMessage.value = `This account does not have permission to access the ${title.value}.`;

      await supabase.auth.signOut();
      showError.value = true;
      return;
    }

    // Save active user
    const userData = {
      id: userId,
      email: userEmail,
      role: currentRole,
    };

    state.activeUser = userData;

    // Save to localStorage
    localStorage.setItem("zank-active-user", JSON.stringify(userData));

    console.log("LOGIN SUCCESS");
    console.log("USER:", userData);
    console.log("LOCAL STORAGE:", localStorage.getItem("zank-active-user"));

    router.push(target.value);
  } catch (error) {
    console.error("Login error:", error);
    showError.value = true;
  }
}

onMounted(() => {
  const { state } = useAppState()

  if (state.activeUser) {
    state.activeUser = null
    localStorage.removeItem('zank-active-user')
  }
})
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
              @input="validateEnglishOnly($event, 'email')"
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
              @input="validateEnglishOnly($event, 'password')"
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
