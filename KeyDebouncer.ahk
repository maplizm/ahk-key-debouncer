#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Key Debouncer
; ============================================================
; キーを離した瞬間に keyup を確定させず、一定時間待ってから
; 「本当に離された」と確定します。
;
; その待機中に同じキーの keydown が来た場合はチャタリングとみなし、
; 1回の押下が継続しているものとして吸収します。
;
; この方式では、チャタリングのたびに「次の入力を禁止する時間」を
; 延長するのではなく、キー状態そのものを安定させてから出力します。
; ============================================================

; キーごとの keyup 確定待ち時間(ms)
; 今回のログでは約41.9msの再入力が残っていたため45msとする。
debounceConfig := Map(
    "r", 45
)

keyStates := Map()

; ------------------------------------------------------------
; Hotkey登録
; ------------------------------------------------------------

for key, debounceMs in debounceConfig
{
    state := {
        logicalDown: false,
        releasePending: false,
        releaseTimer: ""
    }

    ; 同じBoundFuncをキャンセルできるよう、タイマー関数を保持する
    state.releaseTimer := ConfirmKeyUp.Bind(key)
    keyStates[key] := state

    Hotkey("$*" key, HandleKeyDown.Bind(key))
    Hotkey("$*" key " up", HandleKeyUp.Bind(key, debounceMs))
}

OnExit(ReleaseAllKeys)

; ------------------------------------------------------------
; keydown
; ------------------------------------------------------------

HandleKeyDown(key, *)
{
    global keyStates

    state := keyStates[key]

    ; keyup確定待ち中に再度keydownが来た場合は、
    ; 「離した後のチャタリング」とみなしてkeyup確定を取り消す。
    ; 論理上は同じ1回の押下が継続しているため、新しいkeydownは送らない。
    if state.releasePending
    {
        SetTimer(state.releaseTimer, 0)
        state.releasePending := false
        return
    }

    ; すでに押下中ならOSのキーリピート。
    ; 長押し入力を維持するためkeydownをそのまま通す。
    if state.logicalDown
    {
        Send "{Blind}{" key " down}"
        return
    }

    ; 新しい正常な押下
    state.logicalDown := true
    Send "{Blind}{" key " down}"
}

; ------------------------------------------------------------
; keyup
; ------------------------------------------------------------

HandleKeyUp(key, debounceMs, *)
{
    global keyStates

    state := keyStates[key]

    ; 対応するkeydownを論理的に出していないkeyupは無視する。
    if !state.logicalDown
        return

    ; keyupは即座に送らず、debounceMsだけ待ってから確定する。
    ; 既に待機中ならタイマーを張り直す。
    if state.releasePending
        SetTimer(state.releaseTimer, 0)

    state.releasePending := true
    SetTimer(state.releaseTimer, -debounceMs)
}

; ------------------------------------------------------------
; keyup確定
; ------------------------------------------------------------

ConfirmKeyUp(key, *)
{
    global keyStates

    state := keyStates[key]

    if !state.releasePending
        return

    ; タイマー満了時点で物理キーが再び押されている場合は、
    ; keyupを確定しない。次の物理keyupで改めて判定する。
    if GetKeyState(key, "P")
    {
        state.releasePending := false
        return
    }

    state.releasePending := false
    state.logicalDown := false

    Send "{Blind}{" key " up}"
}

; ------------------------------------------------------------
; スクリプト終了時の安全処理
; ------------------------------------------------------------

ReleaseAllKeys(*)
{
    global keyStates

    for key, state in keyStates
    {
        if state.releasePending
            SetTimer(state.releaseTimer, 0)

        if state.logicalDown
            Send "{Blind}{" key " up}"
    }
}
