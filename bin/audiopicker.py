#!/usr/bin/env python

import pulsectl
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib, Gdk


WIDGET_REFRESH = 0.25


class Widget:
    def __init__(self, pulse):
        self.pulse = pulse
        self.name = "Unknown"

        self.widget = Gtk.Box.new(Gtk.Orientation.VERTICAL, 10)
        set_margin(self.widget, 15)

        self.records = {}
        self.comboBoxes = {}

        self.refresh()

    def refresh(self):
        records = self.getRecords()

        if records != self.records:
            self.records = records
            self.comboBoxes = {}

            for widget in self.widget.get_children():
                widget.destroy()

            for parent, parentInfo in records.items():
                label = Gtk.Label.new(parentInfo["description"])
                label.set_xalign(0)
                self.widget.add(label)

                comboBox = Gtk.ComboBoxText.new()
                [comboBox.append(childName, childDescription) for childName,
                 childDescription in parentInfo["children"].items()]
                self.comboBoxes[parent] = comboBox
                self.widget.add(comboBox)

                # update backend if frontend changed
                def update(comboBox, parent):
                    # if self.getActiveChild(parent) != comboBox.get_active_id():
                    self.updateParent(comboBox, parent)
                comboBox.connect("changed", update, parent)

            self.widget.show_all()

        # update frontend if backend changed
        for parent in self.records:
            comboBox = self.comboBoxes[parent]
            child = self.getActiveChild(parent)
            if comboBox.get_active_id() != child:
                comboBox.set_active_id(child)

    def getRecords(self):
        return {}

    def getActiveChild(self, parent):
        return ""

    def updateParent(self, comboBox, parent):
        return


class DefaultsWidget(Widget):
    def __init__(self, pulse):
        super().__init__(pulse)
        self.name = "Default Devices"

    def getRecords(self):
        return {
            "speakers": {
                "description": "Speaker",
                "children": self.getRecordsWithPort(self.pulse.sink_list()),
            },
            "mics": {
                "description": "Mic",
                "children": self.getRecordsWithPort(self.pulse.source_list()),
            },
        }

    def getActiveChild(self, parent):
        if parent == "speakers":
            return self.getActiveWithPort(self.pulse.get_sink_by_name(self.pulse.server_info().default_sink_name))
        elif parent == "mics":
            return self.getActiveWithPort(self.pulse.get_source_by_name(self.pulse.server_info().default_source_name))

    def updateParent(self, comboBox, parent):
        name, port = self.decodePort(comboBox.get_active_id())

        if parent == "speakers":
            self.pulse.sink_default_set(name)
            index = self.pulse.get_sink_by_name(name).index
            if port:
                self.pulse.sink_port_set(index, port)

            for sinkInput in self.pulse.sink_input_list():
                try:
                    self.pulse.sink_input_move(sinkInput.index, index)
                except Exception:
                    pass
        elif parent == "mics":
            self.pulse.source_default_set(name)
            index = self.pulse.get_source_by_name(name).index
            if port:
                self.pulse.source_port_set(index, port)

            for sourceOutput in self.pulse.source_output_list():
                try:
                    self.pulse.source_output_move(
                        sourceOutput.index, index)
                except Exception:
                    pass

    def getRecordsWithPort(self, items):
        records = {}
        for item in items:
            availablePorts = [
                port for port in item.port_list if port.available != "no"]
            if len(availablePorts) > 1:
                for port in availablePorts:
                    records[item.name + "," + port.name] = item.description + \
                        ", " + port.description
            else:
                records[item.name] = item.description
        return records

    def getActiveWithPort(self, item):
        availablePorts = [
            port for port in item.port_list if port.available != "no"]
        if len(availablePorts) > 1:
            return item.name + "," + item.port_active.name
        else:
            return item.name

    def decodePort(self, encoded):
        items = encoded.split(",")
        if len(items) == 1:
            return items[0], None
        return items


class ConfigurationWidget(Widget):
    def __init__(self, pulse):
        super().__init__(pulse)
        self.name = "Device Configuration"

    def getRecords(self):
        return {
            card.name: {
                "description": card.proplist["device.description"],
                "children": {
                    profile.name: profile.description for profile in card.profile_list if profile.available == 1
                }} for card in self.pulse.card_list()
        }

    def getActiveChild(self, parent):
        return self.pulse.get_card_by_name(parent).profile_active.name

    def updateParent(self, comboBox, parent):
        self.pulse.card_profile_set(self.pulse.get_card_by_name(
            parent), comboBox.get_active_id())


def set_margin(box, margin):
    box.set_margin_start(margin)
    box.set_margin_end(margin)
    box.set_margin_top(margin)
    box.set_margin_bottom(margin)


def main():
    with pulsectl.Pulse('audio-picker') as pulse:
        # create the window
        window = Gtk.Dialog.new()
        window.set_title("Audio Picker")
        window.connect("destroy", Gtk.main_quit)
        window.connect("key_press_event", lambda _,
                       event: exit() if (event.keyval == Gdk.KEY_Escape) else None)

        box = window.get_content_area()

        # create the widgets
        widgets = [
            DefaultsWidget(pulse),
            ConfigurationWidget(pulse),
        ]
        for widget in widgets:
            frame = Gtk.Frame.new(widget.name)
            frame.add(widget.widget)
            set_margin(frame, 15)
            box.add(frame)

        # constantly refresh the widgets

        def refreshWidgets():
            [widget.refresh() for widget in widgets]
            return True
        GLib.timeout_add(WIDGET_REFRESH * 1000, refreshWidgets)

        # show the window
        window.show_all()

        Gtk.main()


if __name__ == '__main__':
    main()
