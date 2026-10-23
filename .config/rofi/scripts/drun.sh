#!/usr/bin/env bash

rofi -show drun \
    -modi drun \
    -show-icons \
    -display-drun "Apps" \
    -theme "$HOME/.config/rofi/drun.rasi"
    -theme-str '
        configuration {
            show-icons: true;
        }
        window {
            width: 30%;
        }
        mainbox {
            children: [ inputbar, listview ];
        }
        inputbar {
            children: [ prompt, entry ];
            spacing: 10px;
            padding: 10px;
        }
        prompt {
            str: "Apps";
        }
        listview {
            columns: 1;
            lines: 8;
            border: 0px;
            spacing: 5px;
            scrollbar: false;
        }
        element {
            padding: 8px;
            spacing: 10px;
            children: [ element-icon, element-text ];
        }
        element-icon {
            size: 24px;
        }
        element-text {
            vertical-align: 0.5;
        }
    '
