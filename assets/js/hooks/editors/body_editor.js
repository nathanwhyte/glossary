import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import { debounce } from "./editor_utils";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let BodyEditor = {
  mounted() {
    const hiddenInput = document.getElementById("entry_body");

    const debouncedPush = debounce((body) => {
      this.pushEvent("body_update", { body });
    }, 500);

    this.editor = new Editor({
      element: this.el,
      extensions: [StarterKit, Placeholder],
      content: hiddenInput.value,
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose outline-none size-full px-3 py-2`,
        },
      },
      onUpdate: ({ editor }) => {
        debouncedPush(editor.getHTML());
      },
    });
  },

  destroyed() {
    this.editor?.destroy();
  },
};

export default BodyEditor;
