const SearchInput = {
  mounted() {
    this.handleEvent("search:update_query", ({ value }) => {
      if (this.el.value === value) {
        return;
      }

      this.el.value = value;
      this.el.setSelectionRange(value.length, value.length);
    });
  },
};

export default SearchInput;
