/**
 * @type {import("phoenix_live_view").Hook}
 */
const ProjectSelect = {
  mounted() {
    // Handle click events to close dropdown and update text optimistically
    // We use a small delay to ensure phx-click event fires first
    this.el.addEventListener("click", (_) => {
      // Get values from phx-value attributes
      const entryId = this.el.getAttribute("phx-value-entry_id");
      const projectName = this.el.getAttribute("phx-value-project_name");

      if (entryId && projectName) {
        // Update UI optimistically immediately
        const dropdown = document.getElementById(`project-dropdown-${entryId}`);
        if (dropdown) {
          const button = dropdown.querySelector('[role="button"]');
          if (button) {
            // Update the badge style to show it's selected
            button.classList.remove("border-base-content/10", "hover:bg-base-content/5");
            button.classList.add("badge-secondary", "border-secondary/50", "bg-secondary/75", "hover:bg-secondary");
          }
        }

        // Optimistically update the project name text
        const nameElement = document.getElementById(`project-name-${entryId}`);
        if (nameElement) {
          nameElement.textContent = projectName;
        }

        // Close the dropdown after a small delay to allow phx-click to fire first
        // This is the recommended approach for DaisyUI Method 3 (CSS Focus)
        // Reference: https://github.com/saadeghi/daisyui/discussions/1870
        setTimeout(() => {
          const element = document.activeElement;
          if (element && element instanceof HTMLElement) {
            element.blur();
          }
        }, 50);
      }
    });
  },
};

export default ProjectSelect;
