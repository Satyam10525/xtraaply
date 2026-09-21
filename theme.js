(function () {
  const STORAGE_KEY = "xtraaplywood-theme";
  const root = document.documentElement;

  function getStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (error) {
      return null;
    }
  }

  function setStoredTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (error) {
      // Theme still changes for the current page if storage is unavailable.
    }
  }

  function getPreferredTheme() {
    const saved = getStoredTheme();
    if (saved === "light" || saved === "dark") return saved;
    return window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  }

  function updateToggle(button, theme) {
    const isLight = theme === "light";
    button.setAttribute("aria-label", `Switch to ${isLight ? "dark" : "light"} theme`);
    button.setAttribute("aria-pressed", String(isLight));
    button.querySelector(".theme-toggle-icon").textContent = isLight ? "D" : "L";
    button.querySelector(".theme-toggle-text").textContent = isLight ? "Dark" : "Light";
  }

  function applyTheme(theme) {
    root.dataset.theme = theme;
    document.querySelectorAll(".theme-toggle").forEach((button) => updateToggle(button, theme));
    syncScrolledNav(theme);
  }

  function syncScrolledNav(theme) {
    const nav = document.getElementById("navbar");
    if (!nav) return;

    const isLight = theme === "light";
    nav.style.background = window.scrollY > 60
      ? (isLight ? "rgba(248,245,236,0.98)" : "rgba(20,20,16,0.98)")
      : (isLight ? "rgba(248,245,236,0.94)" : "rgba(20,20,16,0.88)");
  }

  function createToggle() {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "theme-toggle";
    button.innerHTML = '<span class="theme-toggle-icon" aria-hidden="true"></span><span class="theme-toggle-text"></span>';
    button.addEventListener("click", () => {
      const nextTheme = root.dataset.theme === "light" ? "dark" : "light";
      applyTheme(nextTheme);
      setStoredTheme(nextTheme);
    });
    updateToggle(button, root.dataset.theme || getPreferredTheme());
    return button;
  }

  function mountToggle() {
    const navActions = document.querySelector(".nav-actions");
    const toggle = createToggle();

    if (navActions) {
      navActions.prepend(toggle);
      return;
    }

    const authRight = document.querySelector(".auth-right");
    if (authRight) {
      toggle.classList.add("auth-theme-toggle");
      authRight.prepend(toggle);
    }
  }

  applyTheme(getPreferredTheme());

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mountToggle);
  } else {
    mountToggle();
  }
})();
