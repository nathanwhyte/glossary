import { Editor } from "@tiptap/core";
import { Typography } from "@tiptap/extension-typography";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import debounce from "debounce";

/**
 * @type {import("phoenix_live_view").Hook}
 */
const SubtitleEditor = {
  mounted() {
    const editorElement = this.el.querySelector("[data-editor]");

    const debouncedPush = debounce((subtitle) => {
      this.pushEvent("subtitle_update", { subtitle });
    }, 1000);

    this.editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit.extend({
          addKeyboardShortcuts() {
            return {
              Enter: () => true,
            };
          },
          addInputRules() {
            return [];
          },
        }),
        Placeholder.configure({
          placeholder: "Subtitle",
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
      content: this.el.dataset.value || "",
      editorProps: {
        attributes: {
          class: "prose outline-none w-full text-xl flex",
        },
      },
      onUpdate: ({ editor }) => {
        debouncedPush(editor.getText());
      },
    });
  },

  destroyed() {
    if (this.editor) {
      this.editor.destroy();
    }
  },
};

export default SubtitleEditor;
