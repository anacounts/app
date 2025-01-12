document.addEventListener("filters:mounted", (event) => {
  init(event.target);
});

export function init($container) {
  const $reset = $container.querySelector(".js-filters-reset");

  $reset.addEventListener("click", () => reset($container));
}

function getFilters($container) {
  return $container.querySelectorAll(".js-filters-filter");
}

export function reset($container) {
  const $filters = getFilters($container);

  for (const $filter of $filters) {
    const defaultOptions = getDefaultOptions($filter);

    const $inputs = $filter.querySelectorAll("input");
    for (const $input of $inputs) {
      $input.checked = defaultOptions.includes($input.value);
    }
  }

  submit($container);
}

function getDefaultOptions($filter) {
  const defaultOptions = JSON.parse($filter.dataset.default);
  return isMultiple($filter) ? defaultOptions : [defaultOptions];
}

function isMultiple($filter) {
  return $filter.hasAttribute("data-multiple");
}

export function submit($container) {
  // filters don't actually get submitted, they update automatically
  // when one of their inputs changes. Simulate that an input changed here.
  $container
    .querySelector("input")
    .dispatchEvent(new Event("input", { bubbles: true }));
}
