import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import { Typography } from "@tiptap/extension-typography";

/**
 * @type {import("phoenix_live_view").Hook}
 */
let TitleEditor = {
  mounted() {
    const editorElement = this.el.querySelector("[data-editor]");
    this.titleInput = this.el.querySelector("[data-editor-hidden='title']");
    this.titleTextInput = this.el.querySelector(
      "[data-editor-hidden='title_text']",
    );

    // const debouncedPush = debounce((title) => {
    //   this.pushEvent("title_update", { title });
    // }, 500);

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
        this.titleTextInput.value = editor.getText();
        this.titleInput.value = editor.getHTML();
        // Trigger input event so LiveView picks up changes for phx-change
        this.titleInput.dispatchEvent(new Event("input", { bubbles: true }));
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
