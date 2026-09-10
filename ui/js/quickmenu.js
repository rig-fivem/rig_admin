import { send_nui_callback, escape_html } from "./utils.js";

export class QuickMenu {
    constructor({ sections = [], on_action = null, layout = {} }) {
        this.sections = Array.isArray(sections) ? sections : Object.values(sections);
        this.on_action = on_action;
        this.position = layout.position || (layout.side === "left" ? "center-left" : "center-right");

        this._registry = new Map();
        this.sections.forEach(section => {
            section.items = this._normalize_list(section.items);
            section.items.forEach(item => this._register(item, null));
        });

        this.stack = [{ kind: "root", focus_index: -1 }];

        this.current_items = null;
        this.current_index = -1;
        this._pending = new Set();

        this.handle_nav_input = this.handle_nav_input.bind(this);
    }


    _normalize_list(list) {
        if (!list) return [];
        return Array.isArray(list) ? list : Object.values(list);
    }

    _register(item, parent_id) {
        if (!item || !item.id) {
            console.error("[quickmenu] item is missing a required 'id', skipping:", item);
            return;
        }
        if (this._registry.has(item.id)) {
            console.warn(`[quickmenu] duplicate item id "${item.id}" - overwriting previous registration`);
        }
        item.items = this._normalize_list(item.items);
        item._parent_id = parent_id;
        this._registry.set(item.id, item);
        item.items.forEach(child => this._register(child, item.id));
    }

    get_item(id) {
        return this._registry.get(id);
    }

    _unregister(item) {
        if (!item || !item.id) return;
        this._registry.delete(item.id);
        (item.items || []).forEach(child => this._unregister(child));
    }

    resolve_position_style() {
        const EDGE = "2vw";
        const EDGE_H = "2vw";

        const map = {
            "top-left": { top: EDGE, right: "auto", bottom: "auto", left: EDGE_H, transform: "none" },
            "top-center": { top: EDGE, right: "auto", bottom: "auto", left: "50%", transform: "translateX(-50%)" },
            "top-right": { top: EDGE, right: EDGE_H, bottom: "auto", left: "auto", transform: "none" },

            "center-left": { top: "50%", right: "auto", bottom: "auto", left: EDGE_H, transform: "translateY(-50%)" },
            "center": { top: "50%", right: "auto", bottom: "auto", left: "50%", transform: "translate(-50%, -50%)" },
            "center-right": { top: "50%", right: EDGE_H, bottom: "auto", left: "auto", transform: "translateY(-50%)" },

            "bottom-left": { top: "auto", right: "auto", bottom: EDGE, left: EDGE_H, transform: "none" },
            "bottom-center": { top: "auto", right: "auto", bottom: EDGE, left: "50%", transform: "translateX(-50%)" },
            "bottom-right": { top: "auto", right: EDGE_H, bottom: EDGE, left: "auto", transform: "none" },
        };

        const pos = map[this.position] || map["top-right"];

        return `top: ${pos.top}; right: ${pos.right}; bottom: ${pos.bottom}; left: ${pos.left}; transform: ${pos.transform};`;
    }

    _current_frame() {
        return this.stack[this.stack.length - 1];
    }

    _render_current() {
        const frame = this._current_frame();
        return frame.kind === "root" ? this._render_root() : this._render_level(frame);
    }

    _render_root() {
        return this.sections.map(section => `
            <div class="qm_section">
                ${section.label ? `<div class="qm_title">${escape_html(section.label)}</div>` : ""}
                <div class="qm_list">${this._render_item_list(section.items)}</div>
            </div>
        `).join("");
    }

    _render_level(frame) {
        let body;
        if (frame.loading) {
            body = `<div class="qm_loading">Loading...</div>`;
        } else if (frame.error) {
            body = `<div class="qm_empty">Failed to load. Press Backspace to go back.</div>`;
        } else {
            body = this._render_item_list(frame.items);
        }

        return `
            <div class="qm_header" data-back="1">
                <i class="fas fa-chevron-left qm_back_icon"></i>
                <div class="qm_header_title">${escape_html(frame.title || "")}</div>
            </div>
            <div class="qm_section">
                <div class="qm_list">${body}</div>
            </div>
        `;
    }

    _render_item_list(items) {
        if (!items || !items.length) {
            return `<div class="qm_empty">Nothing here</div>`;
        }
        return items.map(item => this._render_item(item)).join("");
    }

    _render_item(item) {
        const has_children = (item.items && item.items.length) || item.dynamic;
        const icon = item.icon
            ? `<i class="${escape_html(item.icon)} qm_icon"></i>`
            : item.image
            ? `<img src="${escape_html(item.image)}" class="qm_icon">`
            : "";

        return `
            <div class="qm_item ${item.class || ""} ${has_children ? "has_children" : ""}" data-id="${escape_html(item.id)}">
                ${icon}
                <div class="qm_text">${escape_html(item.label)}</div>
                ${has_children ? `<i class="fas fa-chevron-right qm_chevron"></i>` : ""}
            </div>
        `;
    }

    get_html() {
        const inline_style = this.resolve_position_style();

        return `<div class="qm" style="${inline_style}">` +
            `<div class="qm_content">${this._render_current()}</div>` +
            `<div class="qm_footer">
                <span class="qm_key">&uarr;</span>
                Up
                <span class="qm_key">&darr;</span>
                Down
                <div>
                <span class="qm_key">Bksp</span>
                Back/Close
                <span class="qm_key">Enter</span>
                Select
                </div>
            </div>` +
        `</div>`.trim();
    }

    append_to(container = "#qm_container") {
        this.$container = $(container);
        this.$container.html(this.get_html());
        this.$content = this.$container.find(".qm_content");
        this.bind_events();
        this.init_navigation();
    }

    destroy() {
        this.destroy_navigation();
        if (this.$container) {
            this.$container.empty();
        }
    }

    bind_events() {
        this.$container.off("click.qm");

        this.$container.on("click.qm", ".qm_item", (e) => {
            const id = e.currentTarget.dataset.id;
            if (id) this._activate(id);
        });

        this.$container.on("click.qm", "[data-back]", () => this._go_back());
    }

    _save_current_focus() {
        const frame = this._current_frame();
        if (frame) frame.focus_index = this.current_index;
    }

    _enter_level(frame) {
        this._save_current_focus();
        this.stack.push(frame);
        this._refresh(true);
    }

    _go_back() {
        if (this.stack.length > 1) {
            this.stack.pop();
            this._refresh(true);
        } else {
            send_nui_callback("close", {}, { should_close: true })
                .then(() => this.destroy())
                .catch(() => this.destroy());
        }
    }

    async _activate(id) {
        const item = this.get_item(id);
        if (!item) return;

        if (item.items && item.items.length) {
            this._enter_level({ kind: "items", title: item.title || item.label, items: item.items, focus_index: -1 });
            return;
        }

        if (item.dynamic) {
            await this._activate_dynamic(item);
            return;
        }

        this._fire(item);
    }

    async _activate_dynamic(item) {
        this._save_current_focus();

        const frame = { kind: "items", title: item.title || item.label, items: [], focus_index: -1, loading: true, source_id: item.id };
        this.stack.push(frame);
        this._refresh(false);

        try {
            const response = await send_nui_callback(item.action, { id: item.id, ...(item.data || {}) });
            const fetched = this._normalize_list(response && response.items);
            fetched.forEach(child => this._register(child, item.id));

            frame.items = fetched;
            if (response && response.title) frame.title = response.title;
        } catch (err) {
            frame.error = true;
        } finally {
            frame.loading = false;
            this._refresh(true);
        }
    }

    update_dynamic_level(source_id, { items, title } = {}) {
        const frame = this.stack.find(f => f.source_id === source_id);
        if (!frame) return;

        (frame.items || []).forEach(child => this._unregister(child));

        const fresh = this._normalize_list(items);
        fresh.forEach(child => this._register(child, source_id));

        frame.items = fresh;
        frame.loading = false;
        frame.error = false;
        if (title) frame.title = title;

        if (this._current_frame() !== frame) return;

        const focused_id = this.current_items && this.current_index >= 0
            ? this.current_items.eq(this.current_index).data("id")
            : null;

        this.$content.html(this._render_current());
        this.current_items = this.$content.find(".qm_item");
        this._reapply_pending();

        const ids = this.current_items.toArray().map(el => el.dataset.id);
        const restore_index = focused_id ? ids.indexOf(focused_id) : -1;
        const fallback = Math.min(frame.focus_index >= 0 ? frame.focus_index : 0, Math.max(ids.length - 1, 0));

        this._focus(restore_index >= 0 ? restore_index : fallback);
    }

    async _fire(item) {
        if (this._pending.has(item.id)) return;
        this._pending.add(item.id);
        this._mark_pending(item.id, true);

        try {
            await send_nui_callback(item.action, { id: item.id, ...(item.data || {}) }, { should_close: !!item.should_close });
            if (this.on_action) this.on_action(item.action, item);
            if (item.should_close) this.destroy();
        } catch (err) {
            console.error(`[quickmenu] action "${item.action}" failed:`, err);
        } finally {
            this._pending.delete(item.id);
            this._mark_pending(item.id, false);
        }
    }

    _mark_pending(id, pending) {
        if (!this.$content) return;
        this.$content.find(".qm_item").filter((_, el) => el.dataset.id === id).toggleClass("qm_pending", pending);
    }

    _reapply_pending() {
        if (!this._pending.size || !this.current_items) return;
        this.current_items.each((_, el) => {
            if (this._pending.has(el.dataset.id)) el.classList.add("qm_pending");
        });
    }

    _refresh(auto_focus) {
        this.$content.html(this._render_current());
        this.current_items = this.$content.find(".qm_item");
        this._reapply_pending();

        if (!auto_focus) {
            this.current_index = -1;
            return;
        }

        const frame = this._current_frame();
        const idx = frame && frame.focus_index >= 0 ? frame.focus_index : 0;
        this._focus(idx);
    }

    init_navigation() {
        this.current_items = this.$content.find(".qm_item");
        this.current_index = -1;
        this._focus(0);

        $(document).off("keydown.qm").on("keydown.qm", (e) => {
            const map = { ArrowUp: "up", ArrowDown: "down", Enter: "select", Backspace: "back" };
            const input = map[e.key];
            if (input) this.handle_nav_input(input);
        });
    }

    destroy_navigation() {
        $(document).off("keydown.qm");
    }

    handle_nav_input(input) {
        switch (input) {
            case "up":
                this._move_focus(-1);
                break;
            case "down":
                this._move_focus(1);
                break;
            case "select": {
                if (!this.current_items || this.current_index < 0) return;
                const id = this.current_items.eq(this.current_index).data("id");
                if (id) this._activate(id);
                break;
            }
            case "back":
                this._go_back();
                break;
        }
    }

    _focus(index) {
        if (!this.current_items || !this.current_items.length) {
            this.current_index = -1;
            return;
        }

        this.current_items.removeClass("kb_focus");

        const count = this.current_items.length;
        this.current_index = ((index % count) + count) % count;

        const $el = this.current_items.eq(this.current_index);
        $el.addClass("kb_focus");

        const el = $el.get(0);
        if (el && el.scrollIntoView) {
            el.scrollIntoView({ block: "nearest" });
        }
    }

    _move_focus(step) {
        if (this.current_index < 0) {
            this._focus(0);
            return;
        }
        this._focus(this.current_index + step);
    }
}