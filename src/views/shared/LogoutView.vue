<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAppState } from '../../services/appState'

const router = useRouter()
const { signOut } = useAppState()

onMounted(() => {
  signOut()
  router.replace('/')
})
</script>

<template>
  <main class="page-shell grid min-h-screen place-items-center">
    <p class="rounded-3xl bg-white px-6 py-4 font-bold text-brand shadow-soft">Logging out...</p>
  </main>
</template>
