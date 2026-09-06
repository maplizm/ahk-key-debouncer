#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; Key Debouncer
; ============================================
; 指定したキーについて、一定時間内の連続入力を無視します。
;
; 形式:
;   "キー名", デバウンス時間(ms)
; ============================================

debounceConfig := Map(
    "r", 35
)

lastInput := Map()

; 設定されたキーごとにHotkeyを登録
for key, debounceMs in debounceConfig
{
    lastInput[key] := 0
    Hotkey("$*" key, DebounceKey.Bind(key, debounceMs))
}

DebounceKey(key, debounceMs, *)
{
    global lastInput

    now := A_TickCount

    ; 前回受け付けた入力から指定時間が経過していなければ無視
    if (now - lastInput[key] < debounceMs)
        return

    lastInput[key] := now

    ; Shift / Ctrl / Altなどの状態を維持したまま送信
    Send "{Blind}{" key "}"
}