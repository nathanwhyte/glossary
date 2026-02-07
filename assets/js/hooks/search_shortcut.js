const SearchShortcut = {
  mounted() {
    this.handleKeydown = (event) => {
      if (event.defaultPrevented || !event.metaKey || event.key.toLowerCase() !== "k") {
        return;
      }

      event.preventDefault();
      this.el.focus();
      this.el.select();
    };

    window.addEventListener("keydown", this.handleKeydown);
  },

  destroyed() {
    window.removeEventListener("keydown", this.handleKeydown);
  },
};

export default SearchShortcut;
