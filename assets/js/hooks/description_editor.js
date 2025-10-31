import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let DescriptionEditor = {
  mounted() {
    const hiddenInput = document.getElementById("entry_description");

    this.editor = new Editor({
      element: this.el,
      extensions: [
        StarterKit,
        Placeholder.configure({
          placeholder: "Description",
        }),
      ],
      content: hiddenInput.value,
      autofocus: false,
      editorProps: {
        attributes: {
          class: `prose outline-none w-full text-sm font-medium rounded-md px-3 py-1 transition italic text-base-content/50`,
        },
        handleDOMEvents: {
          blur: (_view, _event) => {
            const description = this.editor.getText().trim();
            this.pushEvent("description_blur", { description });
          },
        },
      },
    });
  },

  destroyed() {
    console.log("Destroying description editor");
    this.editor?.destroy();
  },
};

export default DescriptionEditor;
