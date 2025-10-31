import TitleEditor from "./title_editor";
import DescriptionEditor from "./description_editor";

/**
 * @type {import("phoenix_live_view").HooksOptions}
 */
let customHooks = {};

customHooks.TitleEditor = TitleEditor;
customHooks.DescriptionEditor = DescriptionEditor;

export default customHooks;
