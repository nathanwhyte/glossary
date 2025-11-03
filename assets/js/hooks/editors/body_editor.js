import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import { Typography } from "@tiptap/extension-typography";
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
        StarterKit,
        Placeholder,
        Typography.configure({
          openDoubleQuote: false,
          closeDoubleQuote: false,
          openSingleQuote: false,
          closeSingleQuote: false,
          oneHalf: false,
          oneQuarter: false,
          threeQuarters: false,
        }),
      ],
      content: hiddenInput.value,
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
