import TitleEditor from "./editors/title_editor";
import DescriptionEditor from "./editors/description_editor";

/**
 * @type {import("phoenix_live_view").HooksOptions}
 */
let customHooks = {};

customHooks.TitleEditor = TitleEditor;
customHooks.DescriptionEditor = DescriptionEditor;

export default customHooks;
