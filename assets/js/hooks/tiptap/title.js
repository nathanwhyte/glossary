import { Editor } from "@tiptap/core";
import { Typography } from "@tiptap/extension-typography";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import debounce from "debounce";

/**
 * @type {import("phoenix_live_view").Hook}
 */
const TitleEditor = {
  mounted() {
    const editorElement = this.el.querySelector("[data-editor]");

    const debouncedPush = debounce((title, title_text) => {
      this.pushEvent("title_update", { title, title_text });
    }, 1000);

    this.editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit.extend({
          addKeyboardShortcuts() {
            return {
              // prevent line breaks
              Enter: () => true,
            };
          },
          addInputRules() {
            // disables heading/list input rules that add new blocks
            return [];
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
      content: this.el.dataset.value || "",
      autofocus: true,
      editorProps: {
        attributes: {
          class: `prose outline-none w-full text-3xl font-semibold flex`,
        },
      },
      onUpdate: ({ editor }) => {
        debouncedPush(editor.getHTML(), editor.getText());
      },
    });
  },

  destroyed() {
    if (this.editor) {
      this.editor.destroy();
    }
  },
};

export default TitleEditor;
