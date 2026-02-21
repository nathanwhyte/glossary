/**
 * TiptapEditor LiveView Hook
 *
 * Integrates the Tiptap rich text editor with Phoenix LiveView forms.
 *
 * Usage in HEEx:
 *   <div id="tiptap-editor" phx-hook="TiptapEditor" data-value={@form[:body].value}>
 *     <div data-editor="body" phx-update="ignore"></div>
 *     <input type="hidden" name="entry[body]" data-editor-hidden="body" />
 *     <input type="hidden" name="entry[body_text]" data-editor-hidden="body_text" />
 *   </div>
 *
 * The hook:
 *   - Mounts Tiptap into the [data-editor] element
 *   - Syncs HTML to [data-editor-hidden="body"] on every update
 *   - Syncs plain text to [data-editor-hidden="body_text"] on every update
 *   - Dispatches input events so LiveView form validation works
 *
 * Keyboard shortcuts (via StarterKit):
 *   - Cmd/Ctrl+B: Bold
 *   - Cmd/Ctrl+I: Italic
 *   - Cmd/Ctrl+Shift+X: Strikethrough
 *   - Cmd/Ctrl+`: Code
 *   - Cmd/Ctrl+Z: Undo
 *   - Cmd/Ctrl+Shift+Z: Redo
 *   - Cmd/Ctrl+Shift+K: Set/unset link on selection
 */

import { Editor } from "@tiptap/core";
import { Placeholder } from "@tiptap/extensions";
import StarterKit from "@tiptap/starter-kit";
import Link from "@tiptap/extension-link";
import debounce from "debounce";

/**
 * @type {import("phoenix_live_view").Hook}
 */
const BodyEditor = {
  mounted() {
    const debouncedPush = debounce((body, body_text) => {
      this.pushEvent("body_update", { body, body_text });
    }, 1000);

    const editorElement = this.el.querySelector("[data-editor]");

    this.editor = new Editor({
      element: editorElement,
      extensions: [
        StarterKit,
        Placeholder.configure({
          placeholder: "Write something ...",
        }),
        Link.extend({
          addKeyboardShortcuts() {
            return {
              "Mod-Shift-k": () => {
                const previousUrl = this.editor.getAttributes("link").href;
                const url = window.prompt("URL", previousUrl);
                if (url === null) return true;
                if (url === "") {
                  this.editor.chain().focus().unsetLink().run();
                } else {
                  this.editor.chain().focus().setLink({ href: url }).run();
                }
                return true;
              },
            };
          },
        }).configure({
          openOnClick: false,
          autolink: true,
          linkOnPaste: true,
          defaultProtocol: "https",
          HTMLAttributes: {
            target: "_blank",
            rel: "noopener noreferrer",
          },
        }),
      ],
      content: this.el.dataset.value || "",
      editorProps: {
        attributes: {
          class: "body-content",
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

export default BodyEditor;
