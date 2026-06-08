import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// Log the connection status for debugging purposes
console.log('Successfully connected to URL:', supabaseUrl)

// Implement a Singleton pattern to prevent creating multiple Supabase instances during Hot Module Replacement (HMR)
if (!window.supabaseInstance) {
  window.supabaseInstance = createClient(supabaseUrl, supabaseAnonKey)
}

// Export the single Supabase client instance to be used across the app
export const supabase = window.supabaseInstance