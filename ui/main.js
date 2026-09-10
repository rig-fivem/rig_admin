import { QuickMenu } from "./js/quickmenu.js";

let quickmenu = null;

const HANDLERS = {}

HANDLERS.build_quickmenu = (data) => {
    if (!data || !data.payload) {
        console.warn("[quickmenu] Missing payload.");
        return;
    }

    if (quickmenu) {
        quickmenu.destroy();
        quickmenu = null;
    }

    quickmenu = new QuickMenu(data.payload);
    quickmenu.append_to("#ui_focus");
};

HANDLERS.close_quickmenu = () => {
    if (quickmenu) {
        quickmenu.destroy();
        quickmenu = null;
    }
};

HANDLERS.copy_to_clipboard = (data) => {
    const el = document.createElement('textarea');
    el.value = data.string;
    document.body.appendChild(el);
    el.select();
    document.execCommand('copy');
    document.body.removeChild(el);
};

window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data) return;

    if (data.type === "qm_nav" && quickmenu) {
        quickmenu.handle_nav_input(data.input);
        return;
    }

    if (data.type === "qm_update" && quickmenu) {
        quickmenu.update_dynamic_level(data.id, { items: data.items, title: data.title });
        return;
    }

    const { func } = data;
    if (!func) return;

    const handler = HANDLERS[func];

    if (typeof handler !== "function") {
        console.warn(`Handler missing: ${func}`);
        return;
    }

    handler(data);
});