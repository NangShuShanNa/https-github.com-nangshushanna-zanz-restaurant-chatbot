<script setup>
import { reactive, ref, onMounted } from "vue";
import { createClient } from "@supabase/supabase-js"; // Imported to create a temporary client instance
import MobileNav from "../../components/MobileNav.vue";
import SideNav from "../../components/SideNav.vue";
import TopBar from "../../components/TopBar.vue";
import { useAppState } from "../../services/appState";
import { supabase } from "../../supabaseClient";

const { state } = useAppState();

const ownerNav = [
  { label: "Dashboard", to: "/owner/dashboard", short: "Home" },
  { label: "Menu Management", to: "/owner/menu-management", short: "Menu" },
  { label: "Orders", to: "/owner/orders" },
  { label: "Staff Accounts", to: "/owner/staff-accounts", short: "Staff" },
  { label: "Logout", to: "/logout", short: "Logout" },
];

const staffItems = ref([]);
const currentOwnerId = ref(null); // Stores the ID of the Owner/Admin who creates the staff
const currentOwnerRestaurantId = ref(null);
const currentRestaurantName = ref(""); // Stores the fetched restaurant name
const isLoading = ref(false);

const form = reactive({
  fullName: "",
  email: "",
  role: "staff",
  password: "",
  confirmPassword: "",
});

async function fetchStaffData() {
  isLoading.value = true;
  try {
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();
    if (authError || !user) throw new Error("Please log in again.");

    // Save the current logged-in owner's ID
    currentOwnerId.value = user.id;

    // 1. Fetch the owner profile first
    const { data: ownerProfile, error: profileError } = await supabase
      .from("profiles")
      .select("restaurant_id")
      .eq("id", user.id)
      .single();

    if (profileError) throw profileError;

    currentOwnerRestaurantId.value = ownerProfile.restaurant_id;

    // 2. Fetch the restaurant name separately using the restaurant_id
    if (ownerProfile.restaurant_id) {
      const { data: restaurantData, error: restaurantError } = await supabase
        .from("restaurants")
        .select("name")
        .eq("id", ownerProfile.restaurant_id)
        .single();

      if (!restaurantError && restaurantData) {
        currentRestaurantName.value = restaurantData.name;
      }
    }

    // 3. Fetch all staff members belonging to the same restaurant
    const { data: staffData, error: staffError } = await supabase
      .from("profiles")
      .select("*")
      .eq("restaurant_id", ownerProfile.restaurant_id)
      .neq("role", "admin");

    if (staffError) throw staffError;

    staffItems.value = staffData.map((item) => ({
      id: item.id,
      fullName: item.name || "-",
      email: item.email,
      role: item.role,
      lastLogin: item.last_login || item.lastLogin || "-",
    }));
  } catch (error) {
    alert("Error loading staff data: " + error.message);
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchStaffData();
});

async function submit() {
  if (!form.fullName || !form.email || !form.password || form.password !== form.confirmPassword) {
    alert("Please fill out all required fields and ensure passwords match.")
    return
  }
  
  if (!currentOwnerRestaurantId.value) {
    alert("Restaurant ID not found. Unable to create staff account.")
    return
  }

  try {
    isLoading.value = true
    const cleanEmail = form.email.trim()

    // 1. Initialize an isolated temporary Supabase client to prevent session overriding
    const tempSupabase = createClient(
      import.meta.env.VITE_SUPABASE_URL, 
      import.meta.env.VITE_SUPABASE_ANON_KEY, 
      { auth: { persistSession: false, autoRefreshToken: false } }
    )

    // 2. Register the new staff account into Supabase Auth
    const { data: signUpData, error: signUpError } = await tempSupabase.auth.signUp({
      email: cleanEmail,
      password: form.password,
    })

    if (signUpError) throw signUpError

    // 3. Force-update the row created by your database trigger setup
    if (signUpData?.user) {
      
      // Give the background DB trigger a brief moment to write its baseline row
      await new Promise(resolve => setTimeout(resolve, 350))

      // Execute a structural override matching your exact database columns
      const { error: profileError } = await supabase
        .from('profiles')
        .update({
          name: form.fullName, // Explicitly targets your 'name' text field seen in the screenshot
          role: form.role,
          restaurant_id: currentOwnerRestaurantId.value,
          restaurant_name: currentRestaurantName.value,
          created_by: currentOwnerId.value
        })
        .eq('id', signUpData.user.id)
      
      if (profileError) {
        // Fallback fallback handler if no trigger exists and rows affected returned 0
        if (profileError.message.includes('0 rows') || profileError.details?.includes('0 rows')) {
          const { error: insertError } = await supabase
            .from('profiles')
            .insert([{
              id: signUpData.user.id,
              email: cleanEmail,
              name: form.fullName,
              role: form.role,
              restaurant_id: currentOwnerRestaurantId.value,
              restaurant_name: currentRestaurantName.value,
              created_by: currentOwnerId.value
            }])
          if (insertError) throw insertError
        } else {
          throw profileError
        }
      }
    }

    // Refresh data lists to present changes immediately
    await fetchStaffData()

    // Clear reactive form structures
    Object.assign(form, { fullName: '', email: '', role: 'staff', password: '', confirmPassword: '' })
    alert("Staff account created and registered successfully!")

  } catch (error) {
    alert("Failed to create account: " + error.message)
  } finally {
    isLoading.value = false
  }
}

async function handleRemoveStaff(userId) {
  if (
    !confirm("Are you sure you want to remove this staff from your restaurant?")
  )
    return;
  try {
    isLoading.value = true;

    const { error } = await supabase
      .from("profiles")
      .update({ restaurant_id: null })
      .eq("id", userId);

    if (error) throw error;
    await fetchStaffData();
    alert("Staff removed successfully.");
  } catch (error) {
    alert("Failed to remove staff: " + error.message);
  } finally {
    isLoading.value = false;
  }
}
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search staff name or email" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <h1 class="text-4xl font-black">Staff Accounts</h1>
        <p class="mt-2 text-muted">
          Create staff logins and manage access to live orders.
        </p>

        <section class="mt-6 grid gap-6 xl:grid-cols-[1fr_380px]">
          <article class="section-card overflow-hidden">
            <div
              class="hidden bg-pale px-5 py-4 text-sm font-black text-brand lg:grid lg:grid-cols-[1fr_1.5fr_1fr_1fr]"
            >
              <span>Name</span><span>Email</span><span>Role</span
              ><span>Actions</span>
            </div>

            <div v-if="isLoading" class="p-5 text-center text-muted">
              Loading staff accounts...
            </div>

            <div
              v-else-if="staffItems.length === 0"
              class="p-5 text-center text-muted"
            >
              No staff accounts found for your restaurant.
            </div>

            <div
              v-else
              v-for="user in staffItems"
              :key="user.id"
              class="grid gap-3 border-t border-stone-100 p-5 lg:grid-cols-[1fr_1.5fr_1fr_1fr] lg:items-center"
            >
              <strong>{{ user.fullName }}</strong>
              <span class="text-sm text-muted">{{ user.email }}</span>
              <span
                class="rounded-full px-3 py-1 text-xs font-bold w-fit bg-pale text-brand uppercase"
              >
                {{ user.role }}
              </span>
              <div class="flex flex-wrap gap-2">
                <button class="text-sm font-bold text-brand">
                  Reset Password
                </button>
                <button
                  class="text-sm font-bold text-red-600"
                  @click="handleRemoveStaff(user.id)"
                >
                  Remove
                </button>
              </div>
            </div>
          </article>

          <form class="section-card p-5 h-fit" @submit.prevent="submit">
            <h2 class="text-xl font-black">Add Staff Account</h2>
            <p class="mt-2 text-sm text-muted">
              Staff can access Live Orders and Menu Items only. Owner pages
              remain restricted.
            </p>
            <div class="mt-5 grid gap-3">
              <input
                v-model="form.fullName"
                class="field"
                placeholder="Full Name"
                required
              />
              <input
                v-model="form.email"
                class="field"
                placeholder="Email Address"
                type="email"
                required
              />
              <select v-model="form.role" class="field">
                <option value="staff">Staff</option>
              </select>
              <input
                v-model="form.password"
                class="field"
                placeholder="Temporary Password"
                type="password"
                required
              />
              <input
                v-model="form.confirmPassword"
                class="field"
                placeholder="Confirm Password"
                type="password"
                required
              />
              <button class="primary-btn" :disabled="isLoading">
                Create Account
              </button>
            </div>
          </form>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />
  </div>
</template>
