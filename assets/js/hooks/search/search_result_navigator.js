const FOCUSABLE_SELECTOR = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])",
].join(",");

const SearchResultNavigator = {
  mounted() {
    this.handleKeydown = (event) => {
      if (!event.ctrlKey || event.metaKey || event.altKey) {
        return;
      }

      const key = event.key.toLowerCase();
      if (key !== "n" && key !== "p") {
        return;
      }

      const active = document.activeElement;
      if (!active || !this.el.contains(active)) {
        return;
      }

      const focusables = this.focusableElements();
      if (focusables.length === 0) {
        return;
      }

      event.preventDefault();

      const currentIndex = focusables.indexOf(active);
      const direction = key === "n" ? 1 : -1;
      const startIndex = currentIndex === -1 ? (direction === 1 ? -1 : 0) : currentIndex;
      const nextIndex = (startIndex + direction + focusables.length) % focusables.length;
      focusables[nextIndex].focus();
    };

    window.addEventListener("keydown", this.handleKeydown);
  },

  focusableElements() {
    return [...this.el.querySelectorAll(FOCUSABLE_SELECTOR)].filter((el) => {
      if (el.hasAttribute("disabled") || el.getAttribute("aria-hidden") === "true") {
        return false;
      }

      return el.offsetParent !== null;
    });
  },

  destroyed() {
    if (this.handleKeydown) {
      window.removeEventListener("keydown", this.handleKeydown);
    }
  },
};

export default SearchResultNavigator;
