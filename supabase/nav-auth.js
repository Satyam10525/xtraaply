import { getSupabaseClient, isSupabaseConfigured } from "./client.js";

const supabase = isSupabaseConfigured() ? getSupabaseClient() : null;

function getDisplayName(user) {
  const fullName = user?.user_metadata?.full_name?.trim();
  if (fullName) {
    return fullName.split(/\s+/)[0];
  }

  const email = user?.email || "";
  if (email.includes("@")) {
    return email.split("@")[0];
  }

  return "My Account";
}

function buildNavActions(user) {
  const name = getDisplayName(user);
  return `
    <a href="rewards.html" class="btn-nav btn-amber">${name}</a>
    <button type="button" class="btn-nav btn-outline" id="logoutBtn">Logout</button>
  `;
}

function buildMobileActions(user) {
  const name = getDisplayName(user);
  return `
    <a href="rewards.html" data-auth-mobile="account">${name}</a>
    <a href="#" data-auth-mobile="logout">Logout</a>
  `;
}

function renderLoggedOut() {
  const navActions = document.querySelector(".nav-actions");
  if (navActions) {
    navActions.innerHTML = `
      <a href="login.html#login" class="btn-nav btn-outline">Login</a>
      <a href="login.html#signup" class="btn-nav btn-amber">Sign Up</a>
    `;
  }

  const mobileMenu = document.getElementById("mobileMenu");
  if (mobileMenu) {
    mobileMenu.querySelectorAll("[data-auth-mobile]").forEach((el) => el.remove());
    const loginLink = mobileMenu.querySelector('a[href="login.html"], a[href="login.html#login"]');
    if (!loginLink) {
      mobileMenu.insertAdjacentHTML("beforeend", `
        <a href="login.html#login" data-auth-mobile="login" onclick="closeMobile()">Login</a>
        <a href="login.html#signup" data-auth-mobile="signup" onclick="closeMobile()">Sign Up</a>
      `);
    } else {
      loginLink.setAttribute("href", "login.html#login");
      loginLink.textContent = "Login";
      if (!mobileMenu.querySelector('[data-auth-mobile="signup"]')) {
        loginLink.insertAdjacentHTML("afterend", `<a href="login.html#signup" data-auth-mobile="signup" onclick="closeMobile()">Sign Up</a>`);
      }
    }
  }
}

function attachLogoutHandlers() {
  const logoutBtn = document.getElementById("logoutBtn");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", handleLogout);
  }

  document.querySelectorAll('[data-auth-mobile="logout"]').forEach((link) => {
    link.addEventListener("click", async (event) => {
      event.preventDefault();
      await handleLogout();
      if (typeof window.closeMobile === "function") {
        window.closeMobile();
      }
    });
  });
}

function renderLoggedIn(user) {
  const navActions = document.querySelector(".nav-actions");
  if (navActions) {
    navActions.innerHTML = buildNavActions(user);
  }

  const mobileMenu = document.getElementById("mobileMenu");
  if (mobileMenu) {
    mobileMenu.querySelectorAll('[data-auth-mobile="login"], [data-auth-mobile="signup"]').forEach((el) => el.remove());
    mobileMenu.querySelectorAll('[href="login.html"], [href="login.html#login"], [href="login.html#signup"]').forEach((el) => {
      if (!el.hasAttribute("data-auth-mobile")) {
        el.remove();
      }
    });
    mobileMenu.querySelectorAll("[data-auth-mobile]").forEach((el) => el.remove());
    mobileMenu.insertAdjacentHTML("beforeend", buildMobileActions(user));
  }

  attachLogoutHandlers();
}

async function handleLogout() {
  if (!supabase) return;
  await supabase.auth.signOut();
  window.location.href = "index.html";
}

async function syncAuthNav() {
  if (!supabase) {
    renderLoggedOut();
    return;
  }

  const { data, error } = await supabase.auth.getSession();
  if (error || !data.session?.user) {
    renderLoggedOut();
    return;
  }

  renderLoggedIn(data.session.user);
}

syncAuthNav();

if (supabase) {
  supabase.auth.onAuthStateChange((_event, session) => {
    if (session?.user) {
      renderLoggedIn(session.user);
    } else {
      renderLoggedOut();
    }
  });
}
