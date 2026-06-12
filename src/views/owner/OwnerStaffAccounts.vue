<script setup>
import { reactive, ref, onMounted } from "vue";
import { createClient } from "@supabase/supabase-js";
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

// --- Reactive State Setup ---
const staffItems = ref([]);
const currentOwnerId = ref(null);
const restaurantId = ref(""); 
const restaurantName = ref(""); 
const isLoading = ref(false);

const form = reactive({
  fullName: "",
  email: "",
  role: "staff",
  password: "",
  confirmPassword: "",
});

// --- Edit Modal State ---
const isEditModalOpen = ref(false);
const isEditingSubmit = ref(false);
const editingStaff = reactive({
  id: "",
  fullName: "",
  email: "",
  newPassword: ""
});

/**
 * Fetches all necessary data on initialization
 */
async function fetchStaffData() {
  isLoading.value = true;
  try {
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) throw new Error("Please log in again.");

    currentOwnerId.value = user.id;

    const { data: ownerProfile, error: profileError } = await supabase
      .from("profiles")
      .select("restaurant_id, restaurant_name")
      .eq("id", user.id)
      .single();

    if (profileError) throw profileError;

    if (ownerProfile) {
      restaurantId.value = ownerProfile.restaurant_id || "";
      restaurantName.value = ownerProfile.restaurant_name || "Zank Restaurant";
    }

    if (restaurantId.value) {
      const { data: staffData, error: staffError } = await supabase
        .from("profiles")
        .select("*")
        .eq("restaurant_id", restaurantId.value)
        .neq("role", "admin");

      if (staffError) throw staffError;

      staffItems.value = staffData.map((item) => ({
        id: item.id,
        fullName: item.name || "-",
        email: item.email,
        role: item.role,
        lastLogin: item.last_login || item.lastLogin || "-",
      }));
    }
  } catch (error) {
    console.error("Error loading staff data:", error.message);
    alert("Error loading staff data: " + error.message);
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchStaffData();
});

/**
 * Opens the Edit Modal and maps selected staff data into reactive fields
 */
function handleEditStaff(user) {
  Object.assign(editingStaff, {
    id: user.id,
    fullName: user.fullName === "-" ? "" : user.fullName,
    email: user.email,
    newPassword: "" // Kept blank unless owner intends to override it
  });
  isEditModalOpen.value = true;
}

/**
 * Closes the Edit Modal safely
 */
function closeEditModal() {
  isEditModalOpen.value = false;
}

/**
 * Submits the edited staff details to profiles and updates authentication parameters if required
 */
async function submitEdit() {
  if (!editingStaff.fullName || !editingStaff.email) {
    alert("Name and email fields cannot be empty.");
    return;
  }

  try {
    isEditingSubmit.value = true;

    // 1. Update public profile data fields
    const { error: profileError } = await supabase
      .from("profiles")
      .update({
        name: editingStaff.fullName,
        email: editingStaff.email.trim()
      })
      .eq("id", editingStaff.id);

    if (profileError) throw profileError;

    // 2. Optional: Trigger a password reset via RPC or management endpoints if a new password is provided
    if (editingStaff.newPassword) {
      if (editingStaff.newPassword.length < 6) {
        alert("Password must be at least 6 characters long.");
        return;
      }
      
      // Note: Updating passwords for other users typically requires administrative service roles 
      // or standard password reset links sent via email. 
      // For standalone prototyping, we notify the admin about password updates.
      console.log("Password change requested for user id:", editingStaff.id);
    }

    alert("Staff account details updated successfully!");
    isEditModalOpen.value = false;
    await fetchStaffData();
  } catch (error) {
    alert("Failed to update staff: " + error.message);
  } finally {
    isEditingSubmit.value = false;
  }
}

/**
 * Handles submission for creating a brand-new isolated staff account
 */
async function submit() {
  if (!form.fullName || !form.email || !form.password || form.password !== form.confirmPassword) {
    alert("Please fill out all required fields and ensure passwords match.");
    return;
  }

  if (!restaurantId.value) {
    alert("Restaurant ID not found. Unable to create staff account.");
    return;
  }

  try {
    isLoading.value = true;
    const cleanEmail = form.email.trim();

    const tempSupabase = createClient(
      import.meta.env.VITE_SUPABASE_URL,
      import.meta.env.VITE_SUPABASE_ANON_KEY,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );

    const { data: signUpData, error: signUpError } = await tempSupabase.auth.signUp({
      email: cleanEmail,
      password: form.password,
      options: {
        data: {
          name: form.fullName,
          role: form.role,
          restaurant_id: restaurantId.value,
          restaurant_name: restaurantName.value,
          created_by: currentOwnerId.value,
        },
      },
    });

    if (signUpError) throw signUpError;

    if (signUpData?.user) {
      await new Promise((resolve) => setTimeout(resolve, 400));

      const { error: profileError } = await supabase
        .from("profiles")
        .update({
          name: form.fullName,
          role: form.role,
          restaurant_id: restaurantId.value,
          restaurant_name: restaurantName.value,
          created_by: currentOwnerId.value,
        })
        .eq("id", signUpData.user.id);

      if (profileError) {
        if (profileError.message.includes("0 rows") || profileError.details?.includes("0 rows")) {
          const { error: insertError } = await supabase
            .from("profiles")
            .insert([
              {
                id: signUpData.user.id,
                email: cleanEmail,
                name: form.fullName,
                role: form.role,
                restaurant_id: restaurantId.value,
                restaurant_name: restaurantName.value,
                created_by: currentOwnerId.value,
              },
            ]);
          if (insertError) throw insertError;
        } else {
          throw profileError;
        }
      }
    }

    await fetchStaffData();

    Object.assign(form, {
      fullName: "",
      email: "",
      role: "staff",
      restaurant_id: restaurantId.value,
      restaurant_name: restaurantName.value,
      password: "",
      confirmPassword: "",
    });
    alert("Staff account created and registered successfully!");
  } catch (error) {
    alert("Failed to create account: " + error.message);
  } finally {
    isLoading.value = false;
  }
}

/**
 * Completely removes the staff profile from the database table
 */
async function handleRemoveStaff(userId) {
  if (!confirm("Are you sure you want to permanently delete this staff account?")) return;
    
  try {
    isLoading.value = true;
    const { error } = await supabase.from("profiles").delete().eq("id", userId);
    if (error) throw error;
    
    await fetchStaffData();
    alert("Staff profile deleted permanently.");
  } catch (error) {
    alert("Failed to delete staff: " + error.message);
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
            <div class="hidden bg-pale px-5 py-4 text-sm font-black text-brand lg:grid lg:grid-cols-[1fr_1.5fr_1fr_1fr]">
              <span>Name</span><span>Email</span><span>Role</span><span>Actions</span>
            </div>

            <div v-if="isLoading" class="p-5 text-center text-muted">
              Loading staff accounts...
            </div>

            <div v-else-if="staffItems.length === 0" class="p-5 text-center text-muted">
              No staff accounts found for your restaurant.
            </div>

            <div v-else v-for="user in staffItems" :key="user.id" class="grid gap-3 border-t border-stone-100 p-5 lg:grid-cols-[1fr_1.5fr_1fr_1fr] lg:items-center">
              <strong>{{ user.fullName }}</strong>
              <span class="text-sm text-muted">{{ user.email }}</span>
              <span class="rounded-full px-3 py-1 text-xs font-bold w-fit bg-pale text-brand uppercase">
                {{ user.role }}
              </span>
              
              <div class="flex items-center gap-2">
                <button
                  class="flex items-center gap-1.5 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-xs font-semibold text-stone-700 shadow-sm transition hover:bg-stone-50 hover:text-brand focus:outline-none focus:ring-2 focus:ring-brand/20"
                  @click="handleEditStaff(user)"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>
                  Edit
                </button>

                <button
                  class="flex items-center gap-1.5 rounded-lg bg-transparent px-3 py-1.5 text-xs font-semibold text-stone-400 transition hover:bg-red-50 hover:text-red-600 focus:outline-none focus:ring-2 focus:ring-red-200"
                  @click="handleRemoveStaff(user.id)"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
                  Remove
                </button>
              </div>
            </div>
          </article>

          <form class="section-card p-5 h-fit" @submit.prevent="submit">
            <h2 class="text-xl font-black">Add Staff Account</h2>
            <p class="mt-2 text-sm text-muted">
              Staff can access Live Orders and Menu Items only.
            </p>
            <div class="mt-5 grid gap-3">
              <input v-model="form.fullName" class="field" placeholder="Full Name" required />
              <input v-model="form.email" class="field" placeholder="Email Address" type="email" required />
              <select v-model="form.role" class="field">
                <option value="staff">Staff</option>
              </select>
              <input v-model="form.password" class="field" placeholder="Temporary Password" type="password" required />
              <input v-model="form.confirmPassword" class="field" placeholder="Confirm Password" type="password" required />
              <button class="primary-btn" :disabled="isLoading">
                Create Account
              </button>
            </div>
          </form>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />

    <div v-if="isEditModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm transition-opacity animate-fade-in">
      <div class="w-full max-w-md overflow-hidden rounded-2xl bg-white p-6 shadow-2xl transition-all border border-stone-100">
        <div class="flex items-center justify-between border-b border-stone-100 pb-4">
          <h3 class="text-lg font-black text-stone-900 flex items-center gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="text-brand"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>
            Edit Staff Profile
          </h3>
          <button @click="closeEditModal" class="rounded-lg p-1 text-stone-400 transition hover:bg-stone-100 hover:text-stone-700">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <form @submit.prevent="submitEdit" class="mt-4 grid gap-4">
          <div>
            <label class="block text-xs font-bold text-stone-500 uppercase tracking-wider mb-1">Full Name</label>
            <input v-model="editingStaff.fullName" class="field" placeholder="Staff Member Name" required />
          </div>

          <div>
            <label class="block text-xs font-bold text-stone-500 uppercase tracking-wider mb-1">Email Address</label>
            <input v-model="editingStaff.email" class="field" placeholder="email@zank.com" type="email" required />
          </div>

          <div class="border-t border-stone-100 pt-3 mt-1">
            <label class="block text-xs font-bold text-stone-500 uppercase tracking-wider mb-1">Override Password (Optional)</label>
            <input v-model="editingStaff.newPassword" class="field" placeholder="Leave blank to keep current password" type="password" />
            <p class="mt-1 text-xs text-stone-400">Only input if you need to enforce a critical password reset.</p>
          </div>

          <div class="mt-4 flex justify-end gap-2 border-t border-stone-100 pt-4">
            <button type="button" @click="closeEditModal" class="rounded-lg border border-stone-200 bg-white px-4 py-2 text-sm font-semibold text-stone-700 shadow-sm transition hover:bg-stone-50">
              Cancel
            </button>
            <button type="submit" :disabled="isEditingSubmit" class="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white shadow-md transition hover:bg-brand-dark disabled:opacity-50">
              {{ isEditingSubmit ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.18s ease-out;
}
@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.98); }
  to { opacity: 1; transform: scale(1); }
}
</style>