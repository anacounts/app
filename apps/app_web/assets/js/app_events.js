document.addEventListener("app:navigate-back", function (event) {
  event.preventDefault();
  window.history.back();
});
