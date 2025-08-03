/*
 * Copyright (c) 2025 Xuesong Peng <pengxuesong.cn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#Include <RabbitCommon>

class UIStyle {
    static text_color := 0xff000000
    static back_color := 0xffeceeee

    static Update(config, initialize) {
        global rime
        if initialize and color := rime.config_get_string(config, "style/color_scheme")
            UIStyle.UpdateColor(config, color)
    }

    static UpdateColor(config, color) {
        global rime
        if color or (buffer := rime.config_get_string(config, "style/color_scheme")) {
            local prefix := "preset_color_schemes/" . (color ? color : buffer)
            local fmt := "argb" ; different from Weasel
            if cfmt := rime.config_get_string(config, prefix . "/color_format") {
                if cfmt = "argb" or cfmt = "rgba" or cfmt = "abgr"
                    fmt := cfmt
            }

            UIStyle.text_color := UIStyle.GetColor(config, prefix . "/text_color", fmt, 0xff000000)
            UIStyle.back_color := UIStyle.GetColor(config, prefix . "/back_color", fmt, 0xffeceeee)

            return true
        }
        return false
    }

    static GetColor(config, key, fmt, fallback) {
        global rime
        if not color := rime.config_get_string(config, key)
            return fallback

        local val := fallback
        make_opaque() {
            val := (fmt != "rgba") ? (val | 0xff000000) : ((val << 8) | 0x000000ff)
        }
        convert_color_to_argb(clr, format) {
            if format = "argb"
                return clr & 0xffffffff
            else if format = "abgr"
                return ((clr & 0x00ff0000) >> 16) | (clr & 0x0000ff00) | ((clr & 0x000000ff) << 16) | (clr & 0xff000000)
            else if format = "rgba"
                return ((clr & 0x00ff00) << 8) | (clr & 0xff0000) | ((clr & 0x0000ff) >> 8) | (clr & 0xff000000)
            else
                return clr & 0xffffffff
        }

        if RegExMatch(color, "i)^0x[0-9a-f]+$") {
            tmp := SubStr(RegExReplace(color, "i)0x"), 1, 8)
            switch StrLen(tmp) {
                case 6:
                    val := Integer("0x" . tmp)
                    make_opaque()
                case 3:
                    tmp := Format(
                        "{1}{1}{2}{2}{3}{3}",
                        SubStr(tmp, 1, 1),
                        SubStr(tmp, 2, 1),
                        SubStr(tmp, 3, 1)
                    )
                    val := Integer("0x" . tmp)
                    make_opaque()
                case 4:
                    tmp := Format(
                        "{1}{1}{2}{2}{3}{3}{4}{4}",
                        SubStr(tmp, 1, 1),
                        SubStr(tmp, 2, 1),
                        SubStr(tmp, 3, 1),
                        SubStr(tmp, 4, 1)
                    )
                    val := Integer("0x" . tmp)
                case 8:
                    val := Integer("0x" . tmp)
                default:
                    return fallback
            }
        } else {
            tmp := 0
            if not rime.config_test_get_int(config, key, &tmp)
                return fallback
            val := tmp
            make_opaque()
        }
        return convert_color_to_argb(val, fmt)
    }
}

RabbitIsUserDarkMode() {
    try {
        local data := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
    }
    if IsSet(data) && IsInteger(data) {
        return !data
    }
    return false
}

OnColorChange(wParam, lParam, msg, hWnd) {
    global rime, IS_DARK_MODE, box
    local old_dark := IS_DARK_MODE
    IS_DARK_MODE := RabbitIsUserDarkMode()
    if old_dark != IS_DARK_MODE {
        if config := rime.config_open("rabbit") {
            UIStyle.Update(config, true)
            if IS_DARK_MODE {
                if color_name := rime.config_get_string(config, "style/color_scheme_dark")
                    UIStyle.UpdateColor(config, color_name)
            }

            rime.config_close(config)
            box.UpdateUIStyle()
        }
    }
}
