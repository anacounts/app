document.addEventListener("app:navigate-back", function (event) {
  event.preventDefault();
  window.history.back();
});

document.addEventListener("app:copy-to-clipboard", async function (event) {
  const {dispatcher, field = "value"} = event.detail;

  const copied = dispatcher[field];
  await navigator.clipboard.writeText(copied);
});
