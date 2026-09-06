# AHK Key Debouncer

A lightweight keyboard debounce utility for AutoHotkey v2.

It suppresses repeated key inputs that occur within a configurable
time interval, which can help mitigate keyboard switch chattering.

## Requirements

- Windows
- AutoHotkey v2

## Configuration

Edit `debounceConfig` in `KeyDebouncer.ahk`.

```ahk
debounceConfig := Map(
    "r", 35
)
