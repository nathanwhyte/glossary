import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import { debounce } from "./utils";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let DescriptionEditor = {
  mounted() {
    const hiddenInput = document.getElementById("entry_description");

    const debouncedPush = debounce((description) => {
      this.pushEvent("description_update", { description });
    }, 500);

    this.editor = new Editor({
      element: this.el,
      extensions: [
        StarterKit.extend({
          addKeyboardShortcuts() {
            return {
              Enter: () => true, // prevent line breaks
            };
          },
          addInputRules() {
            return []; // disables heading/list input rules that add new blocks
          },
        }),
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

export default DescriptionEditor;
