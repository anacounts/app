// Navigate back in the browser history
document.addEventListener("app:navigate-back", function (event) {
  event.preventDefault();
  window.history.back();
});

// Copy the content of the target element to the clipboard
//
// The field to be copied can be specified by the `field` attribute.
document.addEventListener("app:copy-to-clipboard", async function (event) {
  const { dispatcher, field = "value" } = event.detail;

  const copied = dispatcher[field];
  await navigator.clipboard.writeText(copied);
});

// Open the target dialog
document.addEventListener("app:open-dialog", (event) => event.target.showModal());

// Close the target dialog
document.addEventListener("app:close-dialog", (event) => event.target.close());
