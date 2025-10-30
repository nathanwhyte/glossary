import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let TitleEditor = {
  mounted() {
    const hiddenInput = document.getElementById("entry_title");

    this.editor = new Editor({
      element: this.el,
      extensions: [
        StarterKit,
        Placeholder.configure({
          placeholder: "Entry Title",
        }),
      ],
      content: hiddenInput.value,
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose max-w-none outline-none w-full text-3xl font-bold rounded-md px-3 py-2 transition focus:bg-base-content/5`,
        },
        handleDOMEvents: {
          blur: (_view, _event) => {
            const title = this.editor.getText().trim();
            this.pushEvent("title_blur", { title });
          },
        },
      },
    });
  },

  destroyed() {
    this.editor?.destroy();
  },
};

export default TitleEditor;
