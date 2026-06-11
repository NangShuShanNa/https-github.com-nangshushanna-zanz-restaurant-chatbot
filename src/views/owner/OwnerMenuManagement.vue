<script setup>
import { computed, reactive, ref, watch, onMounted } from "vue";
import { Pencil, Plus, Trash2, X } from "@lucide/vue";
import MobileNav from "../../components/MobileNav.vue";
import SideNav from "../../components/SideNav.vue";
import StatusPill from "../../components/StatusPill.vue";
import TagList from "../../components/TagList.vue";
import TopBar from "../../components/TopBar.vue";

// Import Supabase client database connection
import { supabase } from "../../supabaseClient";

const ownerNav = [
  { label: "Dashboard", to: "/owner/dashboard", short: "Home" },
  { label: "Menu Management", to: "/owner/menu-management", short: "Menu" },
  { label: "Orders", to: "/owner/orders" },
  { label: "Staff Accounts", to: "/owner/staff-accounts", short: "Staff" },
  { label: "Logout", to: "/logout", short: "Logout" },
];

const menuItems = ref([]);
const selected = ref(null);
const isLoading = ref(false);
const isModalOpen = ref(false); // Controls visibility for the "Add New" Modal Popup
const contentLanguage = ref("en"); // Used only for the traditional Edit form side-tab

// Form reactive states (Separated to prevent data collision)
const form = reactive({}); // For Side-by-Side traditional Edit Item
const addForm = reactive({}); // For Center-PopUp Add New Item

// 1. Fetch menu data from Supabase
async function fetchMenuItems() {
  isLoading.value = true;
  try {
    const { data, error } = await supabase
      .from("menu_items")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw error;

    menuItems.value = data.map((item) => ({
      id: item.id,
      name: item.name,
      nameTh: item.name_th,
      category: item.category,
      price: item.price,
      image: item.image,
      description: item.description,
      descriptionTh: item.description_th,
      ingredients: item.ingredients || [],
      ingredientsTh: item.ingredients_th || [],
      allergens: item.allergens || [],
      allergensTh: item.allergens_th || [],
      dietaryTags: item.dietary_tags || [],
      dietaryTagsTh: item.dietary_tags_th || [],
      tasteProfiles: item.taste_profiles || [],
      tasteProfilesTh: item.taste_profiles_th || [],
      spiceLevel: item.spice_level,
      availability: item.availability,
    }));

    // Auto-select first item on load if available
    if (menuItems.value.length > 0 && !selected.value) {
      load(menuItems.value[0]);
    }
  } catch (error) {
    alert("Error fetching data: " + error.message);
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchMenuItems();
});

// 2. Load item data into the Edit Form
function load(item) {
  selected.value = item;
  Object.assign(form, {
    ...item,
    ingredientsText: (item.ingredients || []).join(", "),
    allergensText: (item.allergens || []).join(", "),
    dietaryText: (item.dietaryTags || []).join(", "),
    tasteText: (item.tasteProfiles || []).join(", "),
    ingredientsThText: (item.ingredientsTh || []).join(", "),
    allergensThText: (item.allergensTh || []).join(", "),
    dietaryThText: (item.dietaryTagsTh || []).join(", "),
    tasteThText: (item.tasteProfilesTh || []).join(", "),
  });
}

// Watch selected item to dynamically sync the edit form side-panel
watch(selected, (item) => item && load(item), { immediate: true });

// Check validation status for both forms
const complete = computed(
  () =>
    form.name &&
    form.nameTh &&
    form.category &&
    form.price &&
    form.description &&
    form.descriptionTh &&
    form.ingredientsText &&
    form.ingredientsThText &&
    form.tasteText &&
    form.tasteThText &&
    form.availability,
);

const addComplete = computed(
  () =>
    addForm.name &&
    addForm.nameTh &&
    addForm.category &&
    addForm.price &&
    addForm.description &&
    addForm.descriptionTh &&
    addForm.ingredientsText &&
    addForm.ingredientsThText &&
    addForm.tasteText &&
    addForm.tasteThText &&
    addForm.availability,
);

// 3. Submit Update for existing item (Side panel)
async function submitEdit() {
  const payload = {
    name: form.name,
    category: form.category,
    price: Number(form.price),
    description: form.description,
    image: form.image,
    ingredients: form.ingredientsText
      ? form.ingredientsText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    allergens: form.allergensText
      ? form.allergensText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    dietary_tags: form.dietaryText
      ? form.dietaryText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    taste_profiles: form.tasteText
      ? form.tasteText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    name_th: form.nameTh,
    description_th: form.descriptionTh,
    ingredients_th: form.ingredientsThText
      ? form.ingredientsThText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    allergens_th: form.allergensThText
      ? form.allergensThText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    dietary_tags_th: form.dietaryThText
      ? form.dietaryThText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    taste_profiles_th: form.tasteThText
      ? form.tasteThText
          .split(",")
          .map((x) => x.trim())
          .filter(Boolean)
      : [],
    spice_level: form.spiceLevel,
    availability: form.availability,
  };

  try {
    const { error } = await supabase
      .from("menu_items")
      .update(payload)
      .eq("id", form.id);
    if (error) throw error;

    await fetchMenuItems();
    alert("Item updated successfully!");
  } catch (error) {
    alert("Error updating data: " + error.message);
  }
}

// 4. Initialize empty form states and Open the Modal for Adding New Item
function addNew() {
  Object.assign(addForm, {
    name: "",
    nameTh: "",
    category: "",
    price: 0,
    image: "",
    description: "",
    descriptionTh: "",
    ingredientsText: "",
    ingredientsThText: "",
    allergensText: "",
    allergensThText: "",
    dietaryText: "",
    dietaryThText: "",
    tasteText: "",
    tasteThText: "",
    spiceLevel: "None",
    availability: "available",
  });
  isModalOpen.value = true;
}

// 5. Submit Insertion for new item (Modal)
// 5. Submit Insertion for new item (Modal)
async function submitAdd() {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      alert("ไม่พบข้อมูลผู้ใช้งาน หรือเซสชันหมดอายุ กรุณาล็อกอินใหม่อีกครั้ง");
      return;
    }

    const payload = {
      owner_id: user.id,
      name: addForm.name,
      category: addForm.category,
      price: Number(addForm.price),
      description: addForm.description,
      image: addForm.image,
      ingredients: addForm.ingredientsText
        ? addForm.ingredientsText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      allergens: addForm.allergensText
        ? addForm.allergensText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      dietary_tags: addForm.dietaryText
        ? addForm.dietaryText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      taste_profiles: addForm.tasteText
        ? addForm.tasteText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      name_th: addForm.nameTh,
      description_th: addForm.descriptionTh,
      ingredients_th: addForm.ingredientsThText
        ? addForm.ingredientsThText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      allergens_th: addForm.allergensThText
        ? addForm.allergensThText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      dietary_tags_th: addForm.dietaryThText
        ? addForm.dietaryThText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      taste_profiles_th: addForm.tasteThText
        ? addForm.tasteThText
            .split(",")
            .map((x) => x.trim())
            .filter(Boolean)
        : [],
      spice_level: addForm.spiceLevel,
      availability: addForm.availability,
    };

    const { error } = await supabase.from("menu_items").insert([payload]);
    if (error) throw error;

    isModalOpen.value = false;
    await fetchMenuItems();
    alert("New item added successfully!");
  } catch (error) {
    alert("Error creating item: " + error.message);
  }
}

// 6. Delete item from Supabase
async function removeItem(item) {
  if (!confirm(`Are you sure you want to delete ${item.name}?`)) return;

  try {
    const { error } = await supabase
      .from("menu_items")
      .delete()
      .eq("id", item.id);
    if (error) throw error;

    menuItems.value = menuItems.value.filter((i) => i.id !== item.id);
    if (menuItems.value.length > 0) {
      load(menuItems.value[0]);
    } else {
      selected.value = null;
    }
  } catch (error) {
    alert("Error deleting item: " + error.message);
  }
}
</script>

<template>
  <div class="page-shell">
    <TopBar owner search-placeholder="Search menu items or ingredients" />
    <div class="content-shell">
      <SideNav :items="ownerNav" />
      <main class="main-panel">
        <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 class="text-4xl font-black">Menu Management</h1>
            <p class="mt-2 text-muted">
              Manage dishes, ingredients, allergens, taste profiles, and
              availability.
            </p>
          </div>
          <button
            class="primary-btn inline-flex items-center gap-2"
            @click="addNew"
          >
            <Plus :size="18" /> Add Menu Item
          </button>
        </div>

        <!-- TRADITIONAL SIDE-BY-SIDE LAYOUT (Used for editing items) -->
        <section class="grid gap-6 xl:grid-cols-[1fr_420px]">
          <!-- LEFT PART: The Menu Items Table list -->
          <article class="section-card overflow-hidden">
            <div v-if="isLoading" class="p-5 text-center text-muted">
              Loading menu items...
            </div>
            <div v-else class="divide-y divide-stone-100">
              <article
                v-for="item in menuItems"
                :key="item.id"
                class="grid cursor-pointer gap-4 p-5 transition hover:bg-pale lg:grid-cols-[80px_1.2fr_.7fr_.7fr_1fr_auto] lg:items-center"
                :class="
                  selected?.id === item.id ? 'bg-pale ring-2 ring-brand/20' : ''
                "
                @click="load(item)"
              >
                <img
                  :src="item.image"
                  :alt="item.name"
                  class="h-20 w-20 rounded-2xl object-cover"
                />
                <div>
                  <strong>{{ item.name }}</strong>
                  <p
                    v-if="item.nameTh"
                    class="text-sm font-semibold text-brand"
                  >
                    {{ item.nameTh }}
                  </p>
                  <p class="text-sm text-muted">{{ item.category }}</p>
                </div>
                <span class="font-bold text-brand">{{ item.price }} Baht</span>
                <StatusPill :status="item.availability" />
                <TagList
                  :tags="[
                    ...item.tasteProfiles.slice(0, 1),
                    ...item.allergens.slice(0, 1).map((a) => `Contains ${a}`),
                  ]"
                />
                <div class="flex flex-wrap gap-2">
                  <button
                    class="rounded-full border border-red-100 px-4 py-2 text-sm font-bold text-red-600 transition hover:bg-red-50 bg-white"
                    @click.stop="removeItem(item)"
                  >
                    <Trash2 :size="16" class="inline" /> Delete
                  </button>
                </div>
              </article>
            </div>
          </article>

          <!-- RIGHT PART: Traditional Edit Item Panel (Tab-switching language) -->
          <form
            class="section-card p-5 h-fit sticky top-6"
            @submit.prevent="submitEdit"
          >
            <div class="mb-4 flex items-center justify-between">
              <h2 class="text-xl font-black">Edit Item</h2>
              <span
                class="rounded-full px-3 py-1 text-xs font-bold"
                :class="
                  complete
                    ? 'bg-pale text-brand'
                    : 'bg-orange-50 text-orange-700'
                "
                >{{ complete ? "Complete" : "Missing data" }}</span
              >
            </div>
            <div class="grid gap-3">
              <div class="grid grid-cols-2 rounded-2xl bg-pale p-1">
                <button
                  type="button"
                  class="rounded-xl px-4 py-2 text-sm font-black transition"
                  :class="
                    contentLanguage === 'en'
                      ? 'bg-white text-brand shadow-sm'
                      : 'text-muted'
                  "
                  @click="contentLanguage = 'en'"
                >
                  English
                </button>
                <button
                  type="button"
                  class="rounded-xl px-4 py-2 text-sm font-black transition"
                  :class="
                    contentLanguage === 'th'
                      ? 'bg-white text-brand shadow-sm'
                      : 'text-muted'
                  "
                  @click="contentLanguage = 'th'"
                >
                  ภาษาไทย
                </button>
              </div>

              <!-- English Edit Fields -->
              <div v-if="contentLanguage === 'en'" class="grid gap-3">
                <input
                  v-model="form.name"
                  class="field"
                  placeholder="English name"
                />
                <textarea
                  v-model="form.description"
                  class="field"
                  placeholder="English description"
                ></textarea>
                <textarea
                  v-model="form.ingredientsText"
                  class="field"
                  placeholder="English ingredients, comma separated"
                ></textarea>
                <input
                  v-model="form.allergensText"
                  class="field"
                  placeholder="English allergens, comma separated"
                />
                <input
                  v-model="form.dietaryText"
                  class="field"
                  placeholder="English dietary tags"
                />
                <input
                  v-model="form.tasteText"
                  class="field"
                  placeholder="English taste profile"
                />
              </div>

              <!-- Thai Edit Fields -->
              <div v-else class="grid gap-3">
                <input
                  v-model="form.nameTh"
                  class="field"
                  placeholder="ชื่อเมนูภาษาไทย"
                />
                <textarea
                  v-model="form.descriptionTh"
                  class="field"
                  placeholder="คำอธิบายภาษาไทย"
                ></textarea>
                <textarea
                  v-model="form.ingredientsThText"
                  class="field"
                  placeholder="วัตถุดิบภาษาไทย คั่นด้วยเครื่องหมายจุลภาค"
                ></textarea>
                <input
                  v-model="form.allergensThText"
                  class="field"
                  placeholder="สารก่อภูมิแพ้ภาษาไทย"
                />
                <input
                  v-model="form.dietaryThText"
                  class="field"
                  placeholder="แท็กประเภทอาหารภาษาไทย"
                />
                <input
                  v-model="form.tasteThText"
                  class="field"
                  placeholder="รสชาติภาษาไทย"
                />
              </div>

              <div class="grid gap-3 sm:grid-cols-2">
                <select v-model="form.category" class="field">
                  <option>Starters</option>
                  <option>Main Courses</option>
                  <option>Drinks</option>
                </select>
                <input
                  v-model="form.price"
                  class="field"
                  type="number"
                  placeholder="Price"
                />
              </div>
              <input
                v-model="form.image"
                class="field"
                placeholder="Image URL"
              />
              <div class="grid gap-3 sm:grid-cols-2">
                <select v-model="form.spiceLevel" class="field">
                  <option>None</option>
                  <option>Mild</option>
                  <option>Medium</option>
                  <option>Hot</option>
                </select>
                <select v-model="form.availability" class="field">
                  <option value="available">Available</option>
                  <option value="sold_out">Sold out</option>
                </select>
              </div>
              <button class="primary-btn">Update Item Changes</button>
            </div>
          </form>
        </section>
      </main>
    </div>
    <MobileNav :items="ownerNav" />

    <div
      v-if="isModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
    >
      <form
        class="bg-white rounded-3xl shadow-2xl w-full max-w-7xl max-h-[92vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-200"
        @submit.prevent="submitAdd"
      >
        <div
          class="border-b border-stone-100 p-5 flex items-center justify-between bg-stone-50"
        >
          <div>
            <h2 class="text-2xl font-black text-stone-800">
              Add New Menu Item
            </h2>
            <p class="text-sm text-stone-500">
              Fill out English content, Thai translations, and system
              configuration.
            </p>
          </div>
          <div class="flex items-center gap-3">
            <span
              class="rounded-full px-3 py-1 text-xs font-bold"
              :class="
                addComplete
                  ? 'bg-emerald-50 text-emerald-700'
                  : 'bg-orange-50 text-orange-700'
              "
            >
              {{ addComplete ? "Data Ready" : "Incomplete" }}
            </span>
            <button
              type="button"
              class="text-stone-400 hover:text-stone-600 p-1"
              @click="isModalOpen = false"
            >
              <X :size="20" />
            </button>
          </div>
        </div>

        <div
          class="grid grid-cols-1 lg:grid-cols-3 gap-6 p-6 overflow-y-auto bg-white divide-y lg:divide-y-0 lg:divide-x divide-stone-100"
        >
          <div class="grid gap-4 content-start lg:pr-2">
            <h3 class="text-sm font-bold text-brand uppercase tracking-wider">
              English Details
            </h3>
            <div
              class="grid gap-2 border border-stone-100 p-4 rounded-2xl bg-stone-50/50 content-start"
            >
              <span class="text-xs font-bold text-stone-400 mb-1 block"
                >ENGLISH</span
              >
              <input
                v-model="addForm.name"
                class="field"
                placeholder="English name"
                required
              />
              <textarea
                v-model="addForm.description"
                class="field h-20"
                placeholder="English description"
              ></textarea>
              <textarea
                v-model="addForm.ingredientsText"
                class="field h-16"
                placeholder="Ingredients (comma separated)"
              ></textarea>
              <input
                v-model="addForm.allergensText"
                class="field"
                placeholder="Allergens (comma separated)"
              />
              <input
                v-model="addForm.dietaryText"
                class="field"
                placeholder="Dietary tags"
              />
              <input
                v-model="addForm.tasteText"
                class="field"
                placeholder="Taste profile"
              />
            </div>
          </div>

          <div class="grid gap-4 pt-6 lg:pt-0 lg:px-4 content-start">
            <h3 class="text-sm font-bold text-brand uppercase tracking-wider">
              Thai Translations
            </h3>
            <div
              class="grid gap-2 border border-stone-100 p-4 rounded-2xl bg-stone-50/50 content-start"
            >
              <span class="text-xs font-bold text-stone-400 mb-1 block"
                >THAI LANGUAGE</span
              >
              <input
                v-model="addForm.nameTh"
                class="field"
                placeholder="ชื่อเมนูภาษาไทย"
                required
              />
              <textarea
                v-model="addForm.descriptionTh"
                class="field h-20"
                placeholder="คำอธิบายภาษาไทย"
              ></textarea>
              <textarea
                v-model="addForm.ingredientsThText"
                class="field h-16"
                placeholder="วัตถุดิบภาษาไทย (คั่นด้วยเครื่องหมายจุลภาค)"
              ></textarea>
              <input
                v-model="addForm.allergensThText"
                class="field"
                placeholder="สารก่อภูมิแพ้ภาษาไทย"
              />
              <input
                v-model="addForm.dietaryThText"
                class="field"
                placeholder="แท็กประเภทอาหารภาษาไทย"
              />
              <input
                v-model="addForm.tasteThText"
                class="field"
                placeholder="รสชาติภาษาไทย"
              />
            </div>
          </div>

          <div class="grid gap-4 pt-6 lg:pt-0 lg:pl-6 content-start">
            <h3
              class="text-sm font-bold text-stone-500 uppercase tracking-wider"
            >
              System Configuration
            </h3>
            <div
              class="grid gap-4 border border-stone-100 p-4 rounded-2xl bg-stone-50/50 content-start"
            >
              <div>
                <label class="text-xs font-bold text-stone-400 mb-1 block"
                  >Category</label
                >
                <select v-model="addForm.category" class="field">
                  <option>Starters</option>
                  <option>Main Courses</option>
                  <option>Drinks</option>
                </select>
              </div>

              <div>
                <label class="text-xs font-bold text-stone-400 mb-1 block"
                  >Price (Baht)</label
                >
                <input
                  v-model="addForm.price"
                  class="field"
                  type="number"
                  placeholder="Price"
                  required
                />
              </div>

              <div>
                <label class="text-xs font-bold text-stone-400 mb-1 block"
                  >Image URL</label
                >
                <input
                  v-model="addForm.image"
                  class="field"
                  placeholder="https://images.unsplash.com/..."
                />
                <div
                  v-if="addForm.image"
                  class="mt-2 h-28 w-full rounded-xl overflow-hidden border border-stone-200"
                >
                  <img
                    :src="addForm.image"
                    class="h-full w-full object-cover"
                    alt="Preview"
                  />
                </div>
              </div>

              <div class="grid grid-cols-2 gap-3 mt-1">
                <div>
                  <label class="text-xs font-bold text-stone-400 mb-1 block"
                    >Spice Level</label
                  >
                  <select v-model="addForm.spiceLevel" class="field">
                    <option>None</option>
                    <option>Mild</option>
                    <option>Medium</option>
                    <option>Hot</option>
                  </select>
                </div>
                <div>
                  <label class="text-xs font-bold text-stone-400 mb-1 block"
                    >Availability</label
                  >
                  <select v-model="addForm.availability" class="field">
                    <option value="available">Available</option>
                    <option value="sold_out">Sold out</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div
          class="border-t border-stone-100 p-4 bg-stone-50 flex items-center justify-end gap-3"
        >
          <button
            type="button"
            class="secondary-btn px-5 py-2.5"
            @click="isModalOpen = false"
          >
            Cancel
          </button>
          <button type="submit" class="primary-btn px-6 py-2.5">
            Create New Item
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
