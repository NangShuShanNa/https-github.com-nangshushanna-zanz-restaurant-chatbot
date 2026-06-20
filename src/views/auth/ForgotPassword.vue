<script setup>
import { MailCheck, KeyRound, Lock, CheckCircle2 } from "@lucide/vue";
import { ref, nextTick } from "vue";
import AppLogo from "../../components/AppLogo.vue";
import emailjs from "@emailjs/browser";
import { supabase } from "../../supabaseClient";
import bcrypt from "bcryptjs";

// Manage page steps (1 = Enter backup email, 2 = Enter OTP, 3 = Set new password with web email, 4 = Success)
const step = ref(1);

// Step 1 form data (Backup email for receiving OTP)
const backupEmail = ref("");
const expectedOTP = ref("");

// OTP 6-digit input management (Step 2)
const otpArray = ref(["", "", "", "", "", ""]);
const otpInputs = ref([]);

const handleOtpInput = (index, event) => {
  const val = event.target.value;
  if (val && index < 5) {
    otpInputs.value[index + 1].focus();
  }
};

const handleOtpKeydown = (index, event) => {
  if (event.key === "Backspace" && !otpArray.value[index] && index > 0) {
    otpInputs.value[index - 1].focus();
  }
};

// Step 3 form data (Web account email + new password)
const webEmailInput = ref(""); // Input for web account email to search in DB
const newPassword = ref("");
const confirmPassword = ref("");

const isLoading = ref(false);
const errorMessage = ref("");

// ----------------------------------------------------
// Step 1: Request OTP (Send to backup email)
// ----------------------------------------------------
const handleRequestOTP = async () => {
  errorMessage.value = "";
  if (!backupEmail.value)
    return (errorMessage.value = "กรุณากรอกอีเมลสำรองเพื่อรับรหัส");

  isLoading.value = true;

  // Mock Email section for project testing in step 1
  const mockEmails = ["mock@zank.com", "test@zank.com"];
  if (mockEmails.includes(backupEmail.value)) {
    setTimeout(() => {
      expectedOTP.value = "123456";
      step.value = 2;
      isLoading.value = false;
    }, 1000);
    return;
  }

  try {
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    expectedOTP.value = code;
    const expireTime = new Date(Date.now() + 15 * 60000).toLocaleTimeString(
      "th-TH",
      { hour: "2-digit", minute: "2-digit" },
    );

    // Send OTP to backupEmail (actual existing backup email)
    await emailjs.send(
      "service_tts6co9",
      "template_7106tym",
      {
        to_email: backupEmail.value,
        passcode: code,
        time: expireTime,
      },
      "fLzwQDL8L7UGsN9yw",
    );

    step.value = 2;
    await nextTick();
    if (otpInputs.value[0]) otpInputs.value[0].focus();
  } catch (error) {
    errorMessage.value = "ไม่สามารถส่งอีเมลได้";
  } finally {
    isLoading.value = false;
  }
};

// ----------------------------------------------------
// Step 2: Verify OTP
// ----------------------------------------------------
const handleVerifyOTP = async () => {
  errorMessage.value = "";
  const joinedOTP = otpArray.value.join("");

  if (joinedOTP.length !== 6)
    return (errorMessage.value = "กรุณากรอกรหัส 6 หลักให้ครบ");

  isLoading.value = true;
  try {
    await new Promise((resolve) => setTimeout(resolve, 800));

    if (joinedOTP !== expectedOTP.value) {
      throw new Error("รหัส OTP ไม่ถูกต้อง");
    }

    step.value = 3; // Verification successful, proceed to set new password page
  } catch (error) {
    errorMessage.value = error.message || "รหัส OTP ไม่ถูกต้อง";
  } finally {
    isLoading.value = false;
  }
};

// ----------------------------------------------------
// Step 3: Save new password by searching for web account email
// ----------------------------------------------------
const handleResetPassword = async () => {
  errorMessage.value = "";

  // 1. Check if both password fields match
  if (newPassword.value !== confirmPassword.value) {
    return (errorMessage.value = "รหัสผ่านทั้งสองช่องไม่ตรงกัน");
  }
  if (newPassword.value.length < 6) {
    return (errorMessage.value = "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร");
  }

  isLoading.value = true;
  try {
    // 2. Search for web account email in the profiles table of the Database
    const { data: userProfile, error: fetchError } = await supabase
      .from("profiles")
      .select("email")
      .eq("email", webEmailInput.value) // Search using the web account email entered on this page
      .single();

    // If email is not found in the system
    if (fetchError || !userProfile) {
      throw new Error("ไม่พบอีเมลบัญชีนี้ในระบบเว็บ โปรดตรวจสอบความถูกต้อง");
    }

    // 3. Hash the new password using bcryptjs
    const salt = bcrypt.genSaltSync(10);
    const hashedPassword = bcrypt.hashSync(newPassword.value, salt);

    // 4. Update the password_hash back to the profiles table based on the web email
    const { error: updateError } = await supabase
      .from("profiles")
      .update({ password_hash: hashedPassword })
      .eq("email", webEmailInput.value);

    if (updateError) throw updateError;

    step.value = 4; // Success, proceed to completion page
  } catch (error) {
    errorMessage.value = error.message || "เกิดข้อผิดพลาดในการบันทึกข้อมูล";
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <main class="page-shell min-h-screen px-5 py-8">
    <header class="mx-auto flex max-w-6xl items-center justify-between">
      <AppLogo />
      <span class="text-sm font-bold text-muted">EN / TH</span>
    </header>

    <section
      class="mx-auto mt-16 max-w-md rounded-[2rem] bg-white p-8 shadow-strong"
    >
      <div v-if="step === 1">
        <div class="text-center">
          <div
            class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-pale text-brand"
          >
            <MailCheck :size="30" />
          </div>
          <h1 class="mt-5 text-3xl font-black">Reset Password</h1>
          <p class="mt-2 text-sm leading-relaxed text-muted">
            Enter your <b>backup email</b> to receive a 6-digit verification
            code.
          </p>
        </div>

        <form class="mt-7 space-y-4" @submit.prevent="handleRequestOTP">
          <label class="block text-sm font-bold">
            Backup Email Address (อีเมลสำรอง)
            <input
              v-model="backupEmail"
              class="field mt-2 w-full"
              placeholder="your-backup-email@gmail.com"
              type="email"
              required
            />
          </label>
          <p v-if="errorMessage" class="text-sm font-bold text-red-500">
            {{ errorMessage }}
          </p>
          <button
            type="submit"
            class="primary-btn w-full"
            :disabled="isLoading"
          >
            {{ isLoading ? "Sending..." : "Send OTP" }}
          </button>
        </form>
      </div>

      <div v-else-if="step === 2">
        <div class="text-center">
          <div
            class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-pale text-brand"
          >
            <KeyRound :size="30" />
          </div>
          <h1 class="mt-5 text-3xl font-black">Enter OTP</h1>
          <p class="mt-2 text-sm leading-relaxed text-muted">
            We sent a 6-digit code to
            <span class="font-bold text-brand">{{ backupEmail }}</span>
          </p>
        </div>

        <form class="mt-7 space-y-5" @submit.prevent="handleVerifyOTP">
          <div class="flex justify-between gap-2">
            <input
              v-for="(digit, index) in otpArray"
              :key="index"
              :ref="(el) => (otpInputs[index] = el)"
              v-model="otpArray[index]"
              type="text"
              maxlength="1"
              class="h-14 w-12 rounded-xl border border-gray-300 text-center text-2xl font-black focus:border-brand focus:outline-none focus:ring-2 focus:ring-brand/20 transition-all"
              @input="handleOtpInput(index, $event)"
              @keydown="handleOtpKeydown(index, $event)"
              required
            />
          </div>

          <p
            v-if="errorMessage"
            class="text-sm font-bold text-red-500 text-center"
          >
            {{ errorMessage }}
          </p>

          <button
            type="submit"
            class="primary-btn w-full"
            :disabled="isLoading"
          >
            {{ isLoading ? "Verifying..." : "Verify Code" }}
          </button>
          <button
            type="button"
            class="w-full text-sm font-bold text-muted mt-2"
            @click="step = 1"
          >
            Change Backup Email
          </button>
        </form>
      </div>

      <div v-else-if="step === 3">
        <div class="text-center">
          <div
            class="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-pale text-brand"
          >
            <Lock :size="30" />
          </div>
          <h1 class="mt-5 text-3xl font-black">Account Reset</h1>
          <p class="mt-2 text-sm leading-relaxed text-muted">
            Enter your website account email and set a new password.
          </p>
        </div>

        <form class="mt-7 space-y-4" @submit.prevent="handleResetPassword">
          <label class="block text-sm font-bold">
            Website Account Email (อีเมลในระบบเว็บ)
            <input
              v-model="webEmailInput"
              class="field mt-2 w-full"
              placeholder=""
              type="email"
              required
            />
          </label>

          <hr class="my-4 border-gray-200" />

          <label class="block text-sm font-bold">
            New Password
            <input
              v-model="newPassword"
              class="field mt-2 w-full"
              placeholder="••••••••"
              type="password"
              required
            />
          </label>
          <label class="block text-sm font-bold">
            Confirm New Password
            <input
              v-model="confirmPassword"
              class="field mt-2 w-full"
              placeholder="••••••••"
              type="password"
              required
            />
          </label>

          <p v-if="errorMessage" class="text-sm font-bold text-red-500">
            {{ errorMessage }}
          </p>

          <button
            type="submit"
            class="primary-btn w-full mt-2"
            :disabled="isLoading"
          >
            {{ isLoading ? "Saving..." : "Update Password" }}
          </button>
        </form>
      </div>

      <div v-else-if="step === 4" class="text-center py-6">
        <div
          class="mx-auto grid h-16 w-16 place-items-center rounded-full bg-green-100 text-green-600 mb-4"
        >
          <CheckCircle2 :size="40" />
        </div>
        <h1 class="text-2xl font-black mb-2">Password Updated!</h1>
        <p class="text-sm text-muted mb-8">
          Your website account password has been changed and updated in database
          successfully.
        </p>
        <RouterLink to="/owner/login" class="primary-btn w-full block"
          >Back to Login</RouterLink
        >
      </div>

      <div
        v-if="step !== 4"
        class="mt-6 flex justify-between text-sm font-bold text-brand"
      >
        <RouterLink to="/owner/login">← Back to login</RouterLink>
      </div>
    </section>
  </main>
</template>
