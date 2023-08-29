document.addEventListener("app:navigate-back", function (event) {
  event.preventDefault();
  window.history.back();
});

document.addEventListener("app:copy-to-clipboard", async function (event) {
  const {
    dispatcher,
    field = "textContent",
    selector = "#copied-to-clipboard",
  } = event.detail;

  const copied = dispatcher[field];
  await navigator.clipboard.writeText(copied);

  const target = document.querySelector(selector);
  if (target) target.hidden = false;
});
