import { computePosition, offset } from "@floating-ui/dom";

document.addEventListener("dropdown:mounted", (event) => {
  const $trigger = event.detail.dispatcher;
  const $dropdown = event.target;

  $dropdown.addEventListener("toggle", async (event) => {
    if (event.newState === "closed") {
      return;
    }

    const { x, y } = await computePosition($trigger, $dropdown, {
      placement: "bottom-start",
      middleware: [offset(4)],
    });
    Object.assign($dropdown.style, { top: `${y}px`, left: `${x}px` });
  });
});
