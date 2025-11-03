import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import { debounce } from "./editor_utils";
import { Typography } from "@tiptap/extension-typography";

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
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose outline-none w-full text-3xl font-semibold px-3 py-2`,
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

export default TitleEditor;
