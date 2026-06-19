import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

const SUPABASE_URL = "https://udsdkiriyecbwapzkrin.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVkc2RraXJpeWVjYndhcHprcmluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwODAyNDAsImV4cCI6MjA5MjY1NjI0MH0._SrjkEorqzVy1wHLr-OVx-Kk0_fLC8QI68PwHyTHp8E";

function isValidUrl(value) {
  try {
    new URL(value);
    return true;
  } catch {
    return false;
  }
}

export function isSupabaseConfigured() {
  return (
    SUPABASE_URL &&
    SUPABASE_ANON_KEY &&
    SUPABASE_URL !== "YOUR_SUPABASE_URL" &&
    SUPABASE_ANON_KEY !== "YOUR_SUPABASE_ANON_KEY" &&
    isValidUrl(SUPABASE_URL)
  );
}

export function getSupabaseClient() {
  if (!isSupabaseConfigured()) {
    throw new Error("Supabase is not configured yet. Add your project URL and anon key in supabase/client.js.");
  }

  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}
