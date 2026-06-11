import { createRouter, createWebHistory } from "vue-router";
import RoleSelection from "../views/shared/RoleSelection.vue";
import LogoutView from "../views/shared/LogoutView.vue";
import LoginView from "../views/auth/LoginView.vue";
import ForgotPassword from "../views/auth/ForgotPassword.vue";
import CustomerMenu from "../views/customer/CustomerMenu.vue";
import CartView from "../views/customer/CartView.vue";
import OrderConfirmation from "../views/customer/OrderConfirmation.vue";
import OrderStatus from "../views/customer/OrderStatus.vue";
import StaffLiveOrders from "../views/staff/StaffLiveOrders.vue";
import StaffMenuItems from "../views/staff/StaffMenuItems.vue";
import OwnerDashboard from "../views/owner/OwnerDashboard.vue";
import OwnerMenuManagement from "../views/owner/OwnerMenuManagement.vue";
import OwnerOrders from "../views/owner/OwnerOrders.vue";
import OwnerStaffAccounts from "../views/owner/OwnerStaffAccounts.vue";
import { useAppState } from "../services/appState";

const routes = [
  { path: "/", component: RoleSelection },
  { path: "/logout", component: LogoutView },
  { path: "/forgot-password", component: ForgotPassword },
  { path: "/staff/login", component: LoginView, props: { type: "staff" } },
  { path: "/owner/login", component: LoginView, props: { type: "owner" } },
  { path: "/customer/menu", component: CustomerMenu },
  { path: "/customer/cart", component: CartView },
  {
    path: "/customer/order-confirmation/:orderNumber",
    component: OrderConfirmation,
  },
  { path: "/customer/order-status", component: OrderStatus },
  {
    path: "/staff/live-orders",
    component: StaffLiveOrders,
    meta: { requiresStaff: true },
  },
  {
    path: "/staff/menu-items",
    component: StaffMenuItems,
    meta: { requiresStaff: true },
  },
  {
    path: "/owner/dashboard",
    component: OwnerDashboard,
    meta: { requiresOwner: true },
  },
  {
    path: "/owner/menu-management",
    component: OwnerMenuManagement,
    meta: { requiresOwner: true },
  },
  {
    path: "/owner/orders",
    component: OwnerOrders,
    meta: { requiresOwner: true },
  },
  {
    path: "/owner/staff-accounts",
    component: OwnerStaffAccounts,
    meta: { requiresOwner: true },
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
});

router.beforeEach((to) => {
  const { state } = useAppState();

  const publicPages = ["/", "/owner/login", "/staff/login", "/forgot-password"];

  if (!publicPages.includes(to.path) && !state.activeUser) {
    return "/";
  }
});

export default router;
