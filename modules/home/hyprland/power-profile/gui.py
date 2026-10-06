#!/usr/bin/env python3
import json
import os
import subprocess
import sys

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk

CTL_BIN = os.environ.get("POWER_PROFILE_CTL_BIN")
if not CTL_BIN or not os.path.exists(CTL_BIN):
    candidate = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ctl.py")
    CTL_BIN = candidate if os.path.exists(candidate) else "power-profile-ctl"


PROFILES = {
    "performance": {
        "name": "Performance",
        "glyph": "󰓅",
        "governor": "performance",
        "epp": "performance",
        "turbo": True,
        "max_perf_pct": 100,
    },
    "balanced": {
        "name": "Balanced",
        "glyph": "󰾆",
        "governor": "powersave",
        "epp": "balance_performance",
        "turbo": True,
        "max_perf_pct": 100,
    },
    "powersaver": {
        "name": "Power Saver",
        "glyph": "󰌪",
        "governor": "powersave",
        "epp": "power",
        "turbo": False,
        "max_perf_pct": 70,
    },
}

CSS_TEMPLATE = """
* {
    font-family: "Maple Mono NF", "Noto Sans", sans-serif;
    font-size: 13px;
}

window {
    background-color: alpha(#1e1e2e, 0.96);
    color: #cdd6f4;
}

.card {
    background-color: alpha(#181825, 0.85);
    border: 1px solid alpha(#45475a, 0.45);
    border-radius: 14px;
    padding: 16px;
    margin: 6px 0;
}

.status-card {
    background-color: alpha(#11111b, 0.90);
    border: 1px solid alpha(#89b4fa, 0.35);
    border-radius: 14px;
    padding: 14px;
    margin-bottom: 8px;
}

.status-title {
    font-size: 18px;
    font-weight: bold;
    color: #89b4fa;
}

.status-subtitle {
    font-size: 12px;
    color: #a6adc8;
}

.profile-btn {
    background-color: alpha(#313244, 0.7);
    border: 1px solid alpha(#45475a, 0.5);
    border-radius: 10px;
    padding: 10px 14px;
    font-size: 14px;
    font-weight: 600;
    color: #cdd6f4;
    transition: all 150ms ease;
}

.profile-btn:hover {
    background-color: alpha(#45475a, 0.85);
    border-color: #89b4fa;
}

.profile-btn.active {
    background-color: #89b4fa;
    border-color: #89b4fa;
    color: #11111b;
}

.pill-btn {
    background-color: alpha(#313244, 0.6);
    border: 1px solid alpha(#45475a, 0.4);
    border-radius: 8px;
    padding: 6px 10px;
    font-size: 12px;
    color: #bac2de;
}

.pill-btn:hover {
    background-color: alpha(#45475a, 0.8);
}

.pill-btn.active {
    background-color: #89b4fa;
    color: #11111b;
    border-color: #89b4fa;
    font-weight: bold;
}

.reset-btn {
    background-color: alpha(#313244, 0.7);
    border: 1px solid alpha(#f38ba8, 0.4);
    border-radius: 10px;
    padding: 8px 16px;
    color: #f38ba8;
}

.reset-btn:hover {
    background-color: alpha(#f38ba8, 0.2);
    border-color: #f38ba8;
}

.close-btn {
    background-color: alpha(#313244, 0.7);
    border: 1px solid alpha(#45475a, 0.5);
    border-radius: 10px;
    padding: 8px 16px;
    color: #cdd6f4;
}

.close-btn:hover {
    background-color: alpha(#45475a, 0.9);
}

scale trough {
    background-color: alpha(#313244, 0.8);
    border-radius: 6px;
    min-height: 8px;
}

scale highlight {
    background-color: #89b4fa;
    border-radius: 6px;
}

switch {
    border-radius: 14px;
    background-color: alpha(#313244, 0.8);
}

switch:checked {
    background-color: #89b4fa;
}
"""


def run_ctl(cmd_args):
    try:
        res = subprocess.run([CTL_BIN] + cmd_args, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception as e:
        return ""


def get_status():
    raw = run_ctl(["get-json"])
    if raw:
        try:
            return json.loads(raw)
        except Exception:
            pass
    return {
        "base_profile": "balanced",
        "active_profile": "balanced",
        "display_name": "Balanced",
        "glyph": "󰾆",
        "governor": "powersave",
        "epp": "balance_performance",
        "turbo": True,
        "max_perf_pct": 100,
        "avg_freq_ghz": 2.4,
        "temp_c": 50,
    }


class PowerProfileWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Power & Performance")
        self.set_wmclass("power-profile-gui", "power-profile-gui")
        self.set_default_size(520, 600)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(16)

        self.suppress_events = False
        self.profile_buttons = {}
        self.gov_buttons = {}
        self.epp_buttons = {}

        self.apply_css()
        self.build_ui()
        self.refresh_ui()

        # Close on Escape key
        self.connect("key-press-event", self.on_key_press)

        # Poll every 2 seconds for live clock/temp and sync
        GLib.timeout_add_seconds(2, self.on_poll_timer)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

    def apply_css(self):
        css_provider = Gtk.CssProvider()
        css_file = os.environ.get("POWER_PROFILE_CSS")
        if css_file and os.path.exists(css_file):
            try:
                css_provider.load_from_path(css_file)
            except Exception:
                css_provider.load_from_data(CSS_TEMPLATE.encode("utf-8"))
        else:
            css_provider.load_from_data(CSS_TEMPLATE.encode("utf-8"))
        screen = Gdk.Screen.get_default()
        Gtk.StyleContext.add_provider_for_screen(
            screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def build_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.add(main_box)

        # 1. Status Banner
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.status_box.get_style_context().add_class("status-card")

        self.status_title = Gtk.Label(label="󰾆  Balanced")
        self.status_title.set_xalign(0.0)
        self.status_title.get_style_context().add_class("status-title")

        self.status_sub = Gtk.Label(label="󰍛  -- GHz   •   󰔏  --°C")
        self.status_sub.set_xalign(0.0)
        self.status_sub.get_style_context().add_class("status-subtitle")

        self.status_box.pack_start(self.status_title, False, False, 0)
        self.status_box.pack_start(self.status_sub, False, False, 0)
        main_box.pack_start(self.status_box, False, False, 0)

        # 2. Preset Profiles Row
        presets_label = Gtk.Label(label="<b>Baseline Profiles</b>")
        presets_label.set_use_markup(True)
        presets_label.set_xalign(0.0)
        main_box.pack_start(presets_label, False, False, 0)

        presets_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        presets_box.set_homogeneous(True)

        for key, p in PROFILES.items():
            btn = Gtk.Button(label=f"{p['glyph']}  {p['name']}")
            btn.get_style_context().add_class("profile-btn")
            btn.connect("clicked", self.on_profile_clicked, key)
            self.profile_buttons[key] = btn
            presets_box.pack_start(btn, True, True, 0)

        main_box.pack_start(presets_box, False, False, 0)

        # 3. Fine-Tuning Card
        tuning_label = Gtk.Label(label="<b>Fine-Tuning Controls</b>")
        tuning_label.set_use_markup(True)
        tuning_label.set_xalign(0.0)
        main_box.pack_start(tuning_label, False, False, 4)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        card.get_style_context().add_class("card")
        main_box.pack_start(card, True, True, 0)

        # 3a. Governor
        gov_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        gov_lbl = Gtk.Label(label="󰓅  Governor:")
        gov_lbl.set_xalign(0.0)
        gov_lbl.set_size_request(140, -1)
        gov_box.pack_start(gov_lbl, False, False, 0)

        for gov in ["performance", "powersave"]:
            btn = Gtk.Button(label=gov)
            btn.get_style_context().add_class("pill-btn")
            btn.connect("clicked", self.on_gov_clicked, gov)
            self.gov_buttons[gov] = btn
            gov_box.pack_start(btn, True, True, 0)
        card.pack_start(gov_box, False, False, 0)

        # 3b. EPP
        epp_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        epp_lbl = Gtk.Label(label="󱐋  Energy Bias (EPP):")
        epp_lbl.set_xalign(0.0)
        epp_lbl.set_size_request(140, -1)
        epp_box.pack_start(epp_lbl, False, False, 0)

        epp_options = [
            ("performance", "Perf"),
            ("balance_performance", "Bal Perf"),
            ("balance_power", "Bal Pwr"),
            ("power", "Power"),
        ]
        for val, label in epp_options:
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("pill-btn")
            btn.connect("clicked", self.on_epp_clicked, val)
            self.epp_buttons[val] = btn
            epp_box.pack_start(btn, True, True, 0)
        card.pack_start(epp_box, False, False, 0)

        # 3c. Turbo Boost
        turbo_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        turbo_lbl = Gtk.Label(label="󰚥  Intel Turbo Boost:")
        turbo_lbl.set_xalign(0.0)
        turbo_box.pack_start(turbo_lbl, True, True, 0)

        self.turbo_switch = Gtk.Switch()
        self.turbo_switch.set_valign(Gtk.Align.CENTER)
        self.turbo_switch.connect("state-set", self.on_turbo_switched)
        turbo_box.pack_start(self.turbo_switch, False, False, 0)
        card.pack_start(turbo_box, False, False, 0)

        # 3d. Max Perf Pct
        perf_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        perf_lbl = Gtk.Label(label="󰾅  Max Perf Limit:")
        perf_lbl.set_xalign(0.0)
        perf_lbl.set_size_request(140, -1)
        perf_box.pack_start(perf_lbl, False, False, 0)

        self.scale_adjustment = Gtk.Adjustment(value=100, lower=1, upper=100, step_increment=1, page_increment=5)
        self.scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.scale_adjustment)
        self.scale.set_digits(0)
        self.scale.set_draw_value(False)
        self.scale.connect("value-changed", self.on_scale_changed)
        perf_box.pack_start(self.scale, True, True, 0)

        self.scale_val_lbl = Gtk.Label(label="100%")
        self.scale_val_lbl.set_size_request(45, -1)
        perf_box.pack_start(self.scale_val_lbl, False, False, 0)
        card.pack_start(perf_box, False, False, 0)

        # 4. Action Buttons (Reset & Close)
        actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        actions_box.set_margin_top(6)

        reset_btn = Gtk.Button(label="󰦛  Reset to Baseline")
        reset_btn.get_style_context().add_class("reset-btn")
        reset_btn.connect("clicked", self.on_reset_clicked)
        actions_box.pack_start(reset_btn, False, False, 0)

        close_btn = Gtk.Button(label="󰄬  Close")
        close_btn.get_style_context().add_class("close-btn")
        close_btn.connect("clicked", lambda b: self.destroy())
        actions_box.pack_end(close_btn, False, False, 0)

        main_box.pack_start(actions_box, False, False, 0)

    def refresh_ui(self):
        st = get_status()
        self.suppress_events = True

        # Header status
        glyph = st.get("glyph", "󰾆")
        disp_name = st.get("display_name", "Balanced")
        self.status_title.set_text(f"{glyph}  {disp_name}")
        self.status_sub.set_text(f"󰍛  {st.get('avg_freq_ghz', 0):.2f} GHz   •   󰔏  {st.get('temp_c', 0)}°C")

        # Preset profile buttons
        active_prof = st.get("active_profile", "")
        for key, btn in self.profile_buttons.items():
            if key == active_prof:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # Governor buttons
        curr_gov = st.get("governor", "powersave")
        for gov, btn in self.gov_buttons.items():
            if gov == curr_gov:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # EPP buttons
        curr_epp = st.get("epp", "balance_performance")
        for epp, btn in self.epp_buttons.items():
            if epp == curr_epp:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # Turbo switch
        self.turbo_switch.set_active(st.get("turbo", True))

        # Max perf scale
        max_pct = st.get("max_perf_pct", 100)
        self.scale.set_value(max_pct)
        self.scale_val_lbl.set_text(f"{max_pct}%")

        self.suppress_events = False

    def on_poll_timer(self):
        st = get_status()
        self.status_sub.set_text(f"󰍛  {st.get('avg_freq_ghz', 0):.2f} GHz   •   󰔏  {st.get('temp_c', 0)}°C")
        return True

    def on_profile_clicked(self, widget, prof_key):
        run_ctl(["set-profile", prof_key])
        self.refresh_ui()

    def on_gov_clicked(self, widget, gov):
        if self.suppress_events:
            return
        run_ctl(["set-param", "--governor", gov])
        self.refresh_ui()

    def on_epp_clicked(self, widget, epp):
        if self.suppress_events:
            return
        run_ctl(["set-param", "--epp", epp])
        self.refresh_ui()

    def on_turbo_switched(self, switch, state):
        if self.suppress_events:
            return False
        run_ctl(["set-param", "--turbo", "1" if state else "0"])
        self.refresh_ui()
        return False

    def on_scale_changed(self, scale):
        if self.suppress_events:
            return
        val = int(scale.get_value())
        self.scale_val_lbl.set_text(f"{val}%")
        run_ctl(["set-param", "--max-perf-pct", str(val)])
        self.refresh_ui()

    def on_reset_clicked(self, widget):
        run_ctl(["reset"])
        self.refresh_ui()


def main():
    win = PowerProfileWindow()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
