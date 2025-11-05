import TitleEditor from "./editors/title_editor";
import DescriptionEditor from "./editors/description_editor";
import BodyEditor from "./editors/body_editor";
import ProjectSelect from "./project_select";

/**
 * @type {import("phoenix_live_view").HooksOptions}
 */
let customHooks = {};

customHooks.TitleEditor = TitleEditor;
customHooks.DescriptionEditor = DescriptionEditor;
customHooks.BodyEditor = BodyEditor;
customHooks.ProjectSelect = ProjectSelect;

export default customHooks;
