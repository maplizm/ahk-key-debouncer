#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Key Debouncer
; ============================================================
; キーを離した直後に発生するチャタリングを抑制します。
;
; 前回の keyup から指定時間以内に発生した
; 同じキーの keydown をチャタリングとして無視します。
; ============================================================

debounceConfig := Map(
    "r", 35
)

keyStates := Map()

; ------------------------------------------------------------
; Hotkey登録
; ------------------------------------------------------------

for key, debounceMs in debounceConfig
{
    keyStates[key] := {
        lastUp: A_TickCount - debounceMs,
        down: false,
        suppressed: false
    }

    Hotkey("$*" key, HandleKeyDown.Bind(key, debounceMs))
    Hotkey("$*" key " up", HandleKeyUp.Bind(key))
}

; ------------------------------------------------------------
; keydown
; ------------------------------------------------------------

HandleKeyDown(key, debounceMs, *)
{
    global keyStates

    state := keyStates[key]
    now := A_TickCount

    ; 長押し中のキーリピート
    if state.down
    {
        if state.suppressed
            return

        Send "{Blind}{" key " down}"
        return
    }

    state.down := true

    ; --------------------------------------------------------
    ; keyup直後の再入力をチャタリングとして除外
    ; --------------------------------------------------------

    if (now - state.lastUp < debounceMs)
    {
        state.suppressed := true
        return
    }

    state.suppressed := false

    Send "{Blind}{" key " down}"
}

; ------------------------------------------------------------
; keyup
; ------------------------------------------------------------

HandleKeyUp(key, *)
{
    global keyStates

    state := keyStates[key]

    ; チャタリングとして抑制したkeydownに対応する
    ; keyupも出力しない
    if state.suppressed
    {
        state.suppressed := false
        state.down := false

        ; 抑制したkeyupを基準にデバウンス時間を延長
        state.lastUp := A_TickCount
        return
    }

    state.down := false

    ; 正常なkeyupを先にWindowsへ送る
    Send "{Blind}{" key " up}"

    ; ★ Send後の時刻を記録する
    state.lastUp := A_TickCount
}