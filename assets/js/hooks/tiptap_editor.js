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
 */
import { Editor } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";

const TiptapEditor = {
  mounted() {
    const editorElement = this.el.querySelector("[data-editor]");
    this.bodyInput = this.el.querySelector("[data-editor-hidden='body']");
    this.bodyTextInput = this.el.querySelector(
      "[data-editor-hidden='body_text']",
    );

    this.editor = new Editor({
      element: editorElement,
      extensions: [StarterKit],
      content: this.el.dataset.value || "",
      editorProps: {
        attributes: {
          class: "tiptap-content",
        },
      },
      onUpdate: ({ editor }) => {
        this.bodyInput.value = editor.getHTML();
        this.bodyTextInput.value = editor.getText();
        // Trigger input event so LiveView picks up changes for phx-change
        this.bodyInput.dispatchEvent(new Event("input", { bubbles: true }));
      },
    });
  },

  destroyed() {
    if (this.editor) {
      this.editor.destroy();
    }
  },
};

export default TiptapEditor;
