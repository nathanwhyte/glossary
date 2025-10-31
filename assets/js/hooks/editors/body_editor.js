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
        Placeholder,
      ],
      content: hiddenInput.value,
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose outline-none w-full text-3xl font-semibold rounded-md px-3 py-2 transition`,
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
