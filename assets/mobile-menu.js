document.addEventListener("DOMContentLoaded", () => {
  const menu = document.querySelector(".navbar--menu");
  if (!menu) return;

  const openBtn = document.querySelector(".navbar--hamburger");
  const closeBtn = document.querySelector(".navbar--hide-menu");

  const openMenu = () => {
    menu.classList.add("navbar--menu--open");
    document.body.style.overflow = "hidden";
  };

  const closeMenu = () => {
    menu.classList.remove("navbar--menu--open");
    document.body.style.overflow = "";
  };

  openBtn?.addEventListener("click", openMenu);
  closeBtn?.addEventListener("click", closeMenu);

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeMenu();
  });
});

