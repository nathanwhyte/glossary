const SearchInput = {
  mounted() {
    this.handleKeydown = (event) => {
      const isBackspace = event.key === "Backspace";
      const hasNoModifiers =
        !event.metaKey && !event.ctrlKey && !event.altKey && !event.shiftKey;
      const isEmpty = this.el.value === "";
      const atStart = this.el.selectionStart === 0 && this.el.selectionEnd === 0;

      if (!isBackspace || !hasNoModifiers || !isEmpty || !atStart) {
        return;
      }

      event.preventDefault();
      this.pushEventTo("#dashboard-search-form", "search:clear_prefix", {});
    };

    this.el.addEventListener("keydown", this.handleKeydown);

    this.handleEvent("search:update_query", ({ value }) => {
      if (this.el.value === value) {
        return;
      }

      this.el.value = value;
      this.el.setSelectionRange(value.length, value.length);
    });
  },

  destroyed() {
    if (this.handleKeydown) {
      this.el.removeEventListener("keydown", this.handleKeydown);
    }
  },
};

export default SearchInput;
