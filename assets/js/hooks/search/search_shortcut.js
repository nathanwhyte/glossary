const SearchShortcut = {
  mounted() {
    this.handleKeydown = (event) => {
      if (
        event.defaultPrevented ||
        !event.metaKey ||
        event.key.toLowerCase() !== "k"
      ) {
        return;
      }

      event.preventDefault();

      const input = document.getElementById("dashboard-search-input");
      if (input) {
        input.select();
        return;
      }

      this.el.click();
    };

    window.addEventListener("keydown", this.handleKeydown);
  },

  destroyed() {
    if (this.handleKeydown) {
      window.removeEventListener("keydown", this.handleKeydown);
    }
  },
};

export default SearchShortcut;
