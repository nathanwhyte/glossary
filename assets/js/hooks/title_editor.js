import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import { debounce } from "./utils";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let TitleEditor = {
  mounted() {
    const hiddenInput = document.getElementById("entry_title");

    const debouncedPush = debounce((title) => {
      this.pushEvent("title_update", { title });
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
          placeholder: "Entry Title",
        }),
      ],
      content: hiddenInput.value,
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose outline-none w-full text-3xl font-bold rounded-md px-3 py-2 transition`,
        },
      },
      onUpdate: ({ editor }) => {
        debouncedPush(editor.getText().trim());
      },
    });
  },

  destroyed() {
    this.editor?.destroy();
  },
};

export default TitleEditor;
