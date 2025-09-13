# Project Overview

- Purpose: Neovim plugin providing a minimal hex/ascii/format viewer for arbitrary files, with a simple decoder registry (includes a Lua 5.1 bytecode header decoder). Entry point exposes `require('imhex').setup()` and UI helpers under `require('imhex.ui')`.
- Tech stack: Lua (Neovim runtime API). Tested using Neovim in headless mode with a custom Lua test harness.
- Structure:
  - `lua/imhex/`: core modules
    - `init.lua`: setup, user commands registration
    - `config.lua`: defaults/state + merge
    - `formatdecode/`: decoder registry and builtin decoders (`builtin/lua51.lua`)
    - `ui/`: layout and views (`layout.lua`, `view_hex.lua`, `view_ascii.lua`, `view_format.lua`, `ui/init.lua`)
  - `plugin/`: plugin bootstrap/example user command
  - `health/`: basic `:checkhealth` integration
  - `tests/`: headless tests + harness/runner
- Notable patterns: Modules return a table `M`. UI layout splits windows for hex/ascii/format; config controls sizing/visibility.
