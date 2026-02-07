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
