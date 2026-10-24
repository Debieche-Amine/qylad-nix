#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import threading

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk

GLib.set_prgname("power-profile-gui")
GLib.set_application_name("power-profile-gui")

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
        "min_perf_pct": 23,   # 1.1 GHz
        "max_perf_pct": 100,  # 4.7 GHz
    },
    "balanced": {
        "name": "Balanced",
        "glyph": "󰾆",
        "governor": "powersave",
        "epp": "balance_power",
        "turbo": False,       # Turbo OFF
        "min_perf_pct": 8,    # 400 MHz
        "max_perf_pct": 43,   # 2.0 GHz
    },
    "powersaver": {
        "name": "Power Saver",
        "glyph": "󰌪",
        "governor": "powersave",
        "epp": "power",
        "turbo": False,       # Turbo OFF
        "min_perf_pct": 8,    # 400 MHz
        "max_perf_pct": 17,   # 800 MHz
    },
}

FREQ_TIERS = [
    (8, "400M"),
    (17, "800M"),
    (23, "1.1G"),
    (34, "1.6G"),
    (43, "2.0G"),
    (55, "2.6G"),
    (64, "3.0G"),
    (74, "3.5G"),
    (85, "4.0G"),
    (100, "4.7G"),
]

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
    padding: 14px 16px;
    margin: 4px 0;
}

.status-card {
    background-color: alpha(#11111b, 0.90);
    border: 1px solid alpha(#89b4fa, 0.35);
    border-radius: 14px;
    padding: 12px 14px;
    margin-bottom: 6px;
}

.status-title {
    font-size: 17px;
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
    padding: 9px 12px;
    font-size: 13px;
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
    padding: 5px 8px;
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

.step-btn {
    background-color: alpha(#313244, 0.7);
    border: 1px solid alpha(#45475a, 0.5);
    border-radius: 7px;
    padding: 2px 10px;
    font-size: 14px;
    font-weight: bold;
    color: #cdd6f4;
}

.step-btn:hover {
    background-color: alpha(#45475a, 0.9);
    border-color: #89b4fa;
}

.tier-btn {
    background-color: alpha(#313244, 0.45);
    border: 1px solid alpha(#45475a, 0.3);
    border-radius: 6px;
    padding: 3px 2px;
    font-size: 10px;
    color: #a6adc8;
}

.tier-btn:hover {
    background-color: alpha(#45475a, 0.8);
    color: #cdd6f4;
}

.tier-btn.active {
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
    border-radius: 5px;
    min-height: 7px;
}

scale highlight {
    background-color: #89b4fa;
    border-radius: 5px;
}

switch {
    border-radius: 14px;
    background-color: alpha(#313244, 0.8);
}

switch:checked {
    background-color: #89b4fa;
}
"""


def pct_to_freq_str(pct):
    if pct <= 8:
        return "400 MHz (8%)"
    for t_pct, t_label in FREQ_TIERS:
        if pct == t_pct:
            if "M" in t_label:
                return f"{t_label[:-1]} MHz ({pct}%)"
            else:
                return f"{t_label[:-1]} GHz ({pct}%)"
    mhz = int(round((pct / 100.0) * 4700))
    if mhz < 1000:
        return f"{mhz} MHz ({pct}%)"
    else:
        ghz = mhz / 1000.0
        return f"{ghz:.2f} GHz ({pct}%)"


def run_ctl(cmd_args):
    try:
        res = subprocess.run([CTL_BIN] + cmd_args, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except Exception:
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
        "turbo": False,
        "min_perf_pct": 8,
        "max_perf_pct": 43,
        "avg_freq_ghz": 2.0,
        "temp_c": 50,
    }


class PowerProfileWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="Power & Performance")
        self.set_wmclass("power-profile-gui", "power-profile-gui")
        self.set_default_size(620, 740)
        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(16)

        self.suppress_events = False
        self.min_debounce_id = None
        self.max_debounce_id = None

        self.profile_buttons = {}
        self.gov_buttons = {}
        self.epp_buttons = {}
        self.gpu_buttons = {}
        self.min_tier_buttons = {}
        self.max_tier_buttons = {}

        self.apply_css()
        self.build_ui()
        self.refresh_ui()

        # Close on Escape key
        self.connect("key-press-event", self.on_key_press)

        # Poll every 2 seconds for live clock/temp
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
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        self.add(main_box)

        # 1. Status Banner
        self.status_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
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
        main_box.pack_start(tuning_label, False, False, 2)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=11)
        card.get_style_context().add_class("card")
        main_box.pack_start(card, True, True, 0)

        # 3a. Governor
        gov_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        gov_lbl = Gtk.Label(label="󰓅  Governor:")
        gov_lbl.set_xalign(0.0)
        gov_lbl.set_size_request(150, -1)
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
        epp_lbl.set_size_request(150, -1)
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

        # 3c. NVIDIA dGPU
        gpu_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        gpu_lbl = Gtk.Label(label="󰢮  NVIDIA dGPU:")
        gpu_lbl.set_xalign(0.0)
        gpu_lbl.set_size_request(150, -1)
        gpu_box.pack_start(gpu_lbl, False, False, 0)

        gpu_options = [
            ("off", "󰐥 Off (0W)"),
            ("auto", "󰁪 Auto"),
            ("on", "󰓅 On"),
        ]
        for val, label in gpu_options:
            btn = Gtk.Button(label=label)
            btn.get_style_context().add_class("pill-btn")
            btn.connect("clicked", self.on_gpu_clicked, val)
            self.gpu_buttons[val] = btn
            gpu_box.pack_start(btn, True, True, 0)
        card.pack_start(gpu_box, False, False, 0)

        # 3d. Turbo Boost
        turbo_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        turbo_lbl = Gtk.Label(label="󰚥  Intel Turbo Boost:")
        turbo_lbl.set_xalign(0.0)
        turbo_box.pack_start(turbo_lbl, True, True, 0)

        self.turbo_switch = Gtk.Switch()
        self.turbo_switch.set_valign(Gtk.Align.CENTER)
        self.turbo_switch.connect("state-set", self.on_turbo_switched)
        turbo_box.pack_start(self.turbo_switch, False, False, 0)
        card.pack_start(turbo_box, False, False, 0)

        # 3d. MIN Clock Floor
        min_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

        min_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        min_lbl = Gtk.Label(label="󰾅  Min Clock (Floor):")
        min_lbl.set_xalign(0.0)
        min_header.pack_start(min_lbl, True, True, 0)

        self.min_scale_val_lbl = Gtk.Label(label="400 MHz (8%)")
        self.min_scale_val_lbl.set_xalign(1.0)
        self.min_scale_val_lbl.get_style_context().add_class("status-subtitle")
        min_header.pack_end(self.min_scale_val_lbl, False, False, 0)
        min_card.pack_start(min_header, False, False, 0)

        min_scale_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        min_btn_minus = Gtk.Button(label="−")
        min_btn_minus.get_style_context().add_class("step-btn")
        min_btn_minus.connect("clicked", lambda b: self.step_min_scale(-1))
        min_scale_box.pack_start(min_btn_minus, False, False, 0)

        self.min_scale_adj = Gtk.Adjustment(value=8, lower=1, upper=100, step_increment=1, page_increment=5)
        self.min_scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.min_scale_adj)
        self.min_scale.set_digits(0)
        self.min_scale.set_draw_value(False)
        self.min_scale.connect("value-changed", self.on_min_scale_changed)
        min_scale_box.pack_start(self.min_scale, True, True, 0)

        min_btn_plus = Gtk.Button(label="+")
        min_btn_plus.get_style_context().add_class("step-btn")
        min_btn_plus.connect("clicked", lambda b: self.step_min_scale(1))
        min_scale_box.pack_start(min_btn_plus, False, False, 0)
        min_card.pack_start(min_scale_box, False, False, 0)

        min_tier_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=3)
        min_tier_box.set_homogeneous(True)
        for pct, label in FREQ_TIERS:
            t_btn = Gtk.Button(label=label)
            t_btn.get_style_context().add_class("tier-btn")
            t_btn.connect("clicked", self.on_min_tier_clicked, pct)
            self.min_tier_buttons[pct] = t_btn
            min_tier_box.pack_start(t_btn, True, True, 0)
        min_card.pack_start(min_tier_box, False, False, 0)

        card.pack_start(min_card, False, False, 0)

        # 3e. MAX Clock Ceiling
        max_card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)

        max_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        max_lbl = Gtk.Label(label="󰾅  Max Clock (Ceiling):")
        max_lbl.set_xalign(0.0)
        max_header.pack_start(max_lbl, True, True, 0)

        self.max_scale_val_lbl = Gtk.Label(label="2.00 GHz (43%)")
        self.max_scale_val_lbl.set_xalign(1.0)
        self.max_scale_val_lbl.get_style_context().add_class("status-subtitle")
        max_header.pack_end(self.max_scale_val_lbl, False, False, 0)
        max_card.pack_start(max_header, False, False, 0)

        max_scale_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        max_btn_minus = Gtk.Button(label="−")
        max_btn_minus.get_style_context().add_class("step-btn")
        max_btn_minus.connect("clicked", lambda b: self.step_max_scale(-1))
        max_scale_box.pack_start(max_btn_minus, False, False, 0)

        self.max_scale_adj = Gtk.Adjustment(value=43, lower=1, upper=100, step_increment=1, page_increment=5)
        self.max_scale = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=self.max_scale_adj)
        self.max_scale.set_digits(0)
        self.max_scale.set_draw_value(False)
        self.max_scale.connect("value-changed", self.on_max_scale_changed)
        max_scale_box.pack_start(self.max_scale, True, True, 0)

        max_btn_plus = Gtk.Button(label="+")
        max_btn_plus.get_style_context().add_class("step-btn")
        max_btn_plus.connect("clicked", lambda b: self.step_max_scale(1))
        max_scale_box.pack_start(max_btn_plus, False, False, 0)
        max_card.pack_start(max_scale_box, False, False, 0)

        max_tier_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=3)
        max_tier_box.set_homogeneous(True)
        for pct, label in FREQ_TIERS:
            t_btn = Gtk.Button(label=label)
            t_btn.get_style_context().add_class("tier-btn")
            t_btn.connect("clicked", self.on_max_tier_clicked, pct)
            self.max_tier_buttons[pct] = t_btn
            max_tier_box.pack_start(t_btn, True, True, 0)
        max_card.pack_start(max_tier_box, False, False, 0)

        card.pack_start(max_card, False, False, 0)

        # 4. Action Buttons (Reset & Close)
        actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        actions_box.set_margin_top(4)

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
        gpu_mode_str = st.get("gpu", {}).get("mode", "auto").title()
        self.status_title.set_text(f"{glyph}  {disp_name}")
        self.status_sub.set_text(f"󰍛  {st.get('avg_freq_ghz', 0):.2f} GHz   •   󰔏  {st.get('temp_c', 0)}°C   •   󰢮  {gpu_mode_str}")

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

        # GPU buttons
        curr_gpu_mode = st.get("gpu", {}).get("mode", "auto")
        for mode, btn in self.gpu_buttons.items():
            if mode == curr_gpu_mode:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # Turbo switch
        self.turbo_switch.set_active(st.get("turbo", False))

        # Min scale & tiers
        min_pct = st.get("min_perf_pct", 8)
        self.min_scale.set_value(min_pct)
        self.min_scale_val_lbl.set_text(pct_to_freq_str(min_pct))
        for pct, btn in self.min_tier_buttons.items():
            if pct == min_pct:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # Max scale & tiers
        max_pct = st.get("max_perf_pct", 43)
        self.max_scale.set_value(max_pct)
        self.max_scale_val_lbl.set_text(pct_to_freq_str(max_pct))
        for pct, btn in self.max_tier_buttons.items():
            if pct == max_pct:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        self.suppress_events = False

    def refresh_status_only(self):
        st = get_status()
        glyph = st.get("glyph", "󰾆")
        disp_name = st.get("display_name", "Balanced")
        gpu_mode_str = st.get("gpu", {}).get("mode", "auto").title()
        self.status_title.set_text(f"{glyph}  {disp_name}")
        self.status_sub.set_text(f"󰍛  {st.get('avg_freq_ghz', 0):.2f} GHz   •   󰔏  {st.get('temp_c', 0)}°C   •   󰢮  {gpu_mode_str}")

        active_prof = st.get("active_profile", "")
        for key, btn in self.profile_buttons.items():
            if key == active_prof:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        # GPU buttons
        curr_gpu_mode = st.get("gpu", {}).get("mode", "auto")
        for mode, btn in self.gpu_buttons.items():
            if mode == curr_gpu_mode:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        min_pct = int(self.min_scale.get_value())
        for pct, btn in self.min_tier_buttons.items():
            if pct == min_pct:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        max_pct = int(self.max_scale.get_value())
        for pct, btn in self.max_tier_buttons.items():
            if pct == max_pct:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

    def on_poll_timer(self):
        st = get_status()
        gpu_mode_str = st.get("gpu", {}).get("mode", "auto").title()
        self.status_sub.set_text(f"󰍛  {st.get('avg_freq_ghz', 0):.2f} GHz   •   󰔏  {st.get('temp_c', 0)}°C   •   󰢮  {gpu_mode_str}")
        return True

    def on_gpu_clicked(self, widget, mode):
        run_ctl(["set-gpu", mode])
        self.refresh_ui()

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

    def step_min_scale(self, delta):
        curr = int(self.min_scale.get_value())
        new_val = max(1, min(100, curr + delta))
        self.min_scale.set_value(new_val)

    def on_min_tier_clicked(self, widget, pct):
        self.min_scale.set_value(pct)

    def on_min_scale_changed(self, scale):
        if self.suppress_events:
            return
        val = int(scale.get_value())
        self.min_scale_val_lbl.set_text(pct_to_freq_str(val))

        # Clamp max if min > max
        max_val = int(self.max_scale.get_value())
        if val > max_val:
            self.suppress_events = True
            self.max_scale.set_value(val)
            self.max_scale_val_lbl.set_text(pct_to_freq_str(val))
            self.suppress_events = False

        for pct, btn in self.min_tier_buttons.items():
            if pct == val:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        if self.min_debounce_id is not None:
            GLib.source_remove(self.min_debounce_id)
            self.min_debounce_id = None

        self.min_debounce_id = GLib.timeout_add(250, self.apply_limits_debounced)

    def step_max_scale(self, delta):
        curr = int(self.max_scale.get_value())
        new_val = max(1, min(100, curr + delta))
        self.max_scale.set_value(new_val)

    def on_max_tier_clicked(self, widget, pct):
        self.max_scale.set_value(pct)

    def on_max_scale_changed(self, scale):
        if self.suppress_events:
            return
        val = int(scale.get_value())
        self.max_scale_val_lbl.set_text(pct_to_freq_str(val))

        # Clamp min if max < min
        min_val = int(self.min_scale.get_value())
        if val < min_val:
            self.suppress_events = True
            self.min_scale.set_value(val)
            self.min_scale_val_lbl.set_text(pct_to_freq_str(val))
            self.suppress_events = False

        for pct, btn in self.max_tier_buttons.items():
            if pct == val:
                btn.get_style_context().add_class("active")
            else:
                btn.get_style_context().remove_class("active")

        if self.max_debounce_id is not None:
            GLib.source_remove(self.max_debounce_id)
            self.max_debounce_id = None

        self.max_debounce_id = GLib.timeout_add(250, self.apply_limits_debounced)

    def apply_limits_debounced(self):
        self.min_debounce_id = None
        self.max_debounce_id = None
        min_v = int(self.min_scale.get_value())
        max_v = int(self.max_scale.get_value())
        threading.Thread(target=self._async_set_limits, args=(min_v, max_v), daemon=True).start()
        return False

    def _async_set_limits(self, min_v, max_v):
        run_ctl(["set-param", "--min-perf-pct", str(min_v), "--max-perf-pct", str(max_v)])
        GLib.idle_add(self.refresh_status_only)

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
