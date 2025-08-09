/*
 * Copyright (c) 2023 - 2025 Xuesong Peng <pengxuesong.cn@gmail.com>
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

#Include <RabbitUIStyle>

global LVM_GETCOLUMNWIDTH := 0x101D
; https://learn.microsoft.com/windows/win32/winmsg/extended-window-styles
global WS_EX_NOACTIVATE := "+E0x8000000"
global WS_EX_COMPOSITED := "+E0x02000000"
global WS_EX_LAYERED    := "+E0x00080000"

class CandidateBox {
    static dbg := false
    static gui := 0
    static back_color := 0xeeeeec
    static text_color := 0x000000
    static font_face  := "Microsoft YaHei UI"
    static font_point := 12
    static comment_text_color := 0x222222
    static hilited_back_color := 0x000000
    static hilited_text_color := 0xffffff
    static hilited_candidate_text_color := 0xffffff
    static hilited_candidate_back_color := 0x000000
    static hilited_comment_text_color   := 0x222222
    static margin_x   := 5
    static margin_y   := 5
    static min_width  := 150
    static border     := CandidateBox.dbg ? "+border" : 0

    __New() {
        this.UpdateUIStyle()
    }

    UpdateUIStyle() {
        ; alpha not supported
        del_opaque(color) {
            return color & 0xffffff
        }
        CandidateBox.back_color := del_opaque(UIStyle.back_color)
        CandidateBox.text_color := del_opaque(UIStyle.text_color)
        if UIStyle.font_face
            CandidateBox.font_face := UIStyle.font_face
        CandidateBox.font_point := UIStyle.font_point
        CandidateBox.comment_text_color := del_opaque(UIStyle.comment_text_color)
        CandidateBox.hilited_back_color := del_opaque(UIStyle.hilited_back_color)
        CandidateBox.hilited_text_color := del_opaque(UIStyle.hilited_text_color)
        CandidateBox.hilited_candidate_back_color := del_opaque(UIStyle.hilited_candidate_back_color)
        CandidateBox.hilited_candidate_text_color := del_opaque(UIStyle.hilited_candidate_text_color)
        CandidateBox.hilited_comment_text_color := del_opaque(UIStyle.hilited_comment_text_color)
        CandidateBox.margin_x := UIStyle.margin_x
        CandidateBox.margin_y := UIStyle.margin_y

        if CandidateBox.gui {
            CandidateBox.gui.BackColor := CandidateBox.back_color
            CandidateBox.gui.SetFont(Format("s{} c{:x}", CandidateBox.font_point, CandidateBox.text_color), CandidateBox.font_face)
            CandidateBox.gui.MarginX := CandidateBox.margin_x
            CandidateBox.gui.MarginY := CandidateBox.margin_y

            if HasProp(CandidateBox.gui, "pre") && CandidateBox.gui.pre
                CandidateBox.gui.pre.Opt(Format("c{:x}", CandidateBox.text_color))
            if HasProp(CandidateBox.gui, "sel") && CandidateBox.gui.sel
                CandidateBox.gui.sel.Opt(Format("c{:x} Background{:x}", CandidateBox.hilited_text_color, CandidateBox.hilited_back_color))
            if HasProp(CandidateBox.gui, "post") && CandidateBox.gui.post
                CandidateBox.gui.post.Opt(Format("c{:x}", CandidateBox.text_color))
        }
    }

    Build(context, &width, &height) {
        local cands := context.menu.candidates
        GetCompositionText(context.composition, &pre_selected, &selected, &post_selected)
        if !CandidateBox.gui || !CandidateBox.gui.built {
            CandidateBox.gui := CandidateBox.BoxGui(
                pre_selected,
                selected,
                post_selected,
                cands,
                context.menu.num_candidates,
                context.menu.highlighted_candidate_index + 1
            )
        } else {
            CandidateBox.gui.Update(
                pre_selected,
                selected,
                post_selected,
                cands,
                context.menu.num_candidates,
                context.menu.highlighted_candidate_index + 1
            )
        }
        CandidateBox.gui.GetPos(, , &width, &height)
    }

    Show(x, y) {
        CandidateBox.gui.Show(Format("AutoSize NA x{} y{}", x, y))
    }

    Hide() {
        if CandidateBox.gui && HasMethod(CandidateBox.gui, "Show")
            CandidateBox.gui.Show("Hide")
    }

    class BoxGui extends Gui {
        built := false
        __New(pre, sel, post, cands, num_candidates, hilited_index) {
            super.__New(, , this)
            this.Opt(Format("-DPIScale -Caption +Owner +AlwaysOnTop {} {} {}", WS_EX_NOACTIVATE, WS_EX_COMPOSITED, WS_EX_LAYERED))
            this.BackColor := CandidateBox.back_color
            this.SetFont(Format("s{} c{:x}", CandidateBox.font_point, CandidateBox.text_color), CandidateBox.font_face)
            this.MarginX := CandidateBox.margin_x
            this.MarginY := CandidateBox.margin_y
            this.num_candidates := num_candidates
            this.has_comment := false

            local hilited_opt := Format("c{:x} Background{:x}", CandidateBox.hilited_text_color, CandidateBox.hilited_back_color)

            ; build preedit
            this.max_width := 0
            this.preedit_height := 0
            local head_position := Format("x{} y{} section {}", this.MarginX, this.MarginY, CandidateBox.border)
            local position := head_position
            if pre {
                this.pre := this.AddText(position, pre)
                position := Format("x+{} ys {}", this.MarginX, CandidateBox.border)
                this.pre.GetPos(, , &w, &h)
                this.preedit_height := max(this.preedit_height, h)
                this.pre_width := w
                this.max_width += (w + this.MarginX)
            }
            if sel {
                this.sel := this.AddText(position, sel)
                this.sel.Opt(hilited_opt)
                position := Format("x+{} ys {}", this.MarginX, CandidateBox.border)
                this.sel.GetPos(, , &w, &h)
                this.preedit_height := max(this.preedit_height, h)
                this.sel_width := w
                this.max_width += (w + this.MarginX)
            }
            if post {
                this.post := this.AddText(position, post)
                this.post.GetPos(, , &w, &h)
                this.preedit_height := max(this.preedit_height, h)
                this.post_width := w
                this.max_width += w
            }

            ; build candidates
            this.max_label_width := 0
            this.max_candidate_width := 0
            this.max_comment_width := 0
            this.candidate_height := 0
            hilited_opt := Format("c{:x} Background{:x}", CandidateBox.hilited_candidate_text_color, CandidateBox.hilited_candidate_back_color)
            loop num_candidates {
                position := Format("xs y+{} section {}", this.MarginY, CandidateBox.border)
                local label := this.AddText(Format("Right {} vL{}", position, A_Index), A_Index . ". ")
                label.GetPos(, , &w, &h1)
                this.max_label_width := max(this.max_label_width, w + this.MarginX)

                position := Format("x+{} ys {}", this.MarginX, CandidateBox.border)
                local candidate := this.AddText(Format("{} vC{}", position, A_Index), cands[A_Index].text)
                candidate.GetPos(, , &w, &h2)
                this.max_candidate_width := max(this.max_candidate_width, w + this.MarginX)

                if comment_text := cands[A_Index].comment
                    this.has_comment := true
                local comment := this.AddText(Format("{} vM{}", position, A_Index), comment_text)
                comment.GetPos(, , &w, &h3)
                comment.Opt(Format("c{:x}", CandidateBox.comment_text_color))
                this.max_comment_width := max(this.max_comment_width, w)
                this.candidate_height := max(this.candidate_height, h1, h2, h3)

                if A_Index == hilited_index {
                    label.Opt(hilited_opt)
                    candidate.Opt(hilited_opt)
                    comment.Opt(Format("c{:x} Background{:x}", CandidateBox.hilited_comment_text_color, CandidateBox.hilited_candidate_back_color))
                }
            }

            ; adjust width height
            local list_width := this.max_label_width + this.max_candidate_width + this.has_comment * this.max_comment_width
            local box_width := max(CandidateBox.min_width, list_width)
            if box_width > this.max_width && HasProp(this, "post") && this.post
                this.post.Move(, , this.post_width + box_width - this.max_width)
            if box_width > list_width {
                this.max_candidate_width += box_width - list_width
                loop num_candidates
                    this["C" . A_Index].Move(, , this.max_candidate_width)
            }
            local y := 2 * this.MarginY + this.preedit_height
            loop num_candidates {
                local x := this.MarginX
                this["L" . A_Index].Move(x, y, this.max_label_width)
                this["L" . A_Index].GetPos(, , , &h)
                local max_h := h
                x += this.max_label_width
                this["C" . A_Index].Move(x, y, this.max_candidate_width)
                this["C" . A_Index].GetPos(, , , &h)
                max_h := max(max_h, h)
                x += this.max_candidate_width
                this["M" . A_Index].Move(x, y, this.max_comment_width)
                this["M" . A_Index].GetPos(, , , &h)
                max_h := max(max_h, h)
                y += (max_h + this.MarginY)
            }

            this.built := true
        }

        Update(pre, sel, post, cands, num_candidates, hilited_index) {
            local fake_gui := CandidateBox.BoxGui(pre, sel, post, cands, num_candidates, hilited_index)

            ; reset preedit
            if pre {
                if !HasProp(this, "pre") || !this.pre
                    this.pre := this.AddText(, pre)
                this.pre.Value := fake_gui.pre.Value
                fake_gui.pre.GetPos(&x, &y, &w, &h)
                this.pre.Move(x, y, w, h)
            }
            if HasProp(this, "pre") && this.pre
                this.pre.Visible := !!pre
            if sel {
                if !HasProp(this, "sel") || !this.sel
                    this.sel := this.AddText(, sel)
                this.sel.Value := fake_gui.sel.Value
                fake_gui.sel.GetPos(&x, &y, &w, &h)
                this.sel.Move(x, y, w, h)
            }
            if HasProp(this, "sel") && this.sel
                this.sel.Visible := !!sel
            if post {
                if !HasProp(this, "post") || !this.post
                    this.post := this.AddText(, post)
                this.post.Value := fake_gui.post.Value
                fake_gui.post.GetPos(&x, &y, &w, &h)
                this.post.Move(x, y, w, h)
            }
            if HasProp(this, "post") && this.post
                this.post.Visible := !!post

            ; reset candidates
            hilited_opt := Format("c{:x} Background{:x}", CandidateBox.hilited_candidate_text_color, CandidateBox.hilited_candidate_back_color)
            normal_opt := Format("c{:x} Background{:x}", CandidateBox.text_color, CandidateBox.back_color)
            this.num_candidates := max(this.num_candidates, num_candidates)
            loop this.num_candidates {
                if A_Index > num_candidates {
                    this["L" . A_Index].Visible := false
                    this["C" . A_Index].Visible := false
                    this["M" . A_Index].Visible := false
                    continue
                }
                local fake_label := fake_gui["L" . A_Index]
                local fake_candidate := fake_gui["C" . A_Index]
                local fake_comment := fake_gui["M" . A_Index]
                try
                    local label := this["L" . A_Index]
                catch
                    local label := this.AddText(Format("vL{}", A_Index), fake_label.Value)
                try
                    local candidate := this["C" . A_Index]
                catch
                    local candidate := this.AddText(Format("vC{}", A_Index), fake_candidate.Value)
                try
                    local comment := this["M" . A_Index]
                catch
                    local comment := this.AddText(Format("vM{}", A_Index), fake_comment.Value)
                label.Value := fake_label.Value
                fake_label.GetPos(&x, &y, &w, &h)
                label.Move(x, y, w, h)
                candidate.Value := fake_candidate.Value
                fake_candidate.GetPos(&x, &y, &w, &h)
                candidate.Move(x, y, w, h)
                comment.Value := fake_comment.Value
                fake_comment.GetPos(&x, &y, &w, &h)
                comment.Move(x, y, w, h)

                if A_Index == hilited_index {
                    label.Opt(hilited_opt)
                    candidate.Opt(hilited_opt)
                    comment.Opt(Format("c{:x} Background{:x}", CandidateBox.hilited_comment_text_color, CandidateBox.hilited_candidate_back_color))
                } else {
                    label.Opt(normal_opt)
                    candidate.Opt(normal_opt)
                    comment.Opt(Format("c{:x} Background{:x}", CandidateBox.comment_text_color, CandidateBox.back_color))
                }
                local visible := (A_Index <= num_candidates)
                label.Visible := visible
                candidate.Visible := visible
                comment.Visible := visible
            }

            fake_gui.GetPos(, , &width, &height)
            this.Move(, , width, height)
        }
    }
}

GetCompositionText(composition, &pre_selected, &selected, &post_selected) {
    pre_selected := ""
    selected := ""
    post_selected := ""
    if not preedit := composition.preedit
        return false

    static cursor_text := "‸" ; or 𝙸
    static cursor_size := StrPut(cursor_text, "UTF-8") - 1 ; do not count tailing null

    local preedit_length := StrPut(preedit, "UTF-8")
    local selected_start := composition.sel_start
    local selected_end := composition.sel_end

    local preedit_buffer ; insert caret text into preedit text if applicable
    if 0 <= composition.cursor_pos and composition.cursor_pos <= preedit_length {
        preedit_buffer := Buffer(preedit_length + cursor_size, 0)
        local temp_preedit := Buffer(preedit_length, 0)
        StrPut(preedit, temp_preedit, "UTF-8")
        local src := temp_preedit.Ptr
        local tgt := preedit_buffer.Ptr
        Loop composition.cursor_pos {
            byte := NumGet(src, A_Index - 1, "Char")
            NumPut("Char", byte, tgt, A_Index - 1)
        }
        src := src + composition.cursor_pos
        tgt := tgt + composition.cursor_pos
        StrPut(cursor_text, tgt, "UTF-8")
        tgt := tgt + cursor_size
        Loop preedit_length - composition.cursor_pos {
            byte := NumGet(src, A_Index - 1, "Char")
            NumPut("Char", byte, tgt, A_Index - 1)
        }
        preedit_length := preedit_length + cursor_size
        if selected_start >= composition.cursor_pos
            selected_start := selected_start + cursor_size
        if selected_end > composition.cursor_pos
            selected_end := selected_end + cursor_size
    } else {
        preedit_buffer := Buffer(preedit_length, 0)
        StrPut(preedit, preedit_buffer, "UTF-8")
    }

    if 0 <= selected_start and selected_start < selected_end and selected_end <= preedit_length {
        pre_selected := StrGet(preedit_buffer, selected_start, "UTF-8")
        selected := StrGet(preedit_buffer.Ptr + selected_start, selected_end - selected_start, "UTF-8")
        post_selected := StrGet(preedit_buffer.Ptr + selected_end, "UTF-8")
        return true
    } else {
        pre_selected := StrGet(preedit_buffer, "UTF-8")
        return false
    }
}
