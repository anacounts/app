// Set up the JavaScript dedicated to page components, defined in AppWeb.PageComponents.

// Panel group

const activePanelClass = "panel-group__panel--active";
window.addEventListener("panel_group:show", function panelGroupShow(event) {
  const panelEl = document.querySelector(event.detail);
  const panelGroupEl = panelEl.closest(".panel-group");

  const activePanelEl = panelGroupEl.querySelector(`.${activePanelClass}`);
  activePanelEl?.classList.remove(activePanelClass);

  panelEl.classList.add(activePanelClass);
});
