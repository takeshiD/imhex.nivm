# imhex.nvim

このリポジトリには、バイナリをHex/ASCII/フォーマットの3ペインで閲覧する `imhex` モジュールが含まれます。
`require('imhex').setup()` 実行時にLua 5.1向けのビルトインデコーダが自動登録されます。

## インストール（lazy.nvim）

明示的に `setup()` を呼ぶ構成を推奨します。

```lua
-- lazy.nvim spec 例（リポジトリ名は実際に置き換えてください）
{
  'owner/repo',
  -- 遅延読み込みトリガ（コマンド）
  cmd = { 'ImHexOpen', 'ImHexClose' },
  config = function()
    require('imhex').setup({
      -- 省略可（既定値は下記「設定」を参照）
      -- ui = {
      --   top_ratio = 0.7,
      --   column_ratio = 0.55,
      --   bytes_per_row = 16,
      --   show_ascii = true,
      --   show_hex = true,
      --   show_format = true,
      -- },
      -- decode = {
      --   prefer = { 'lua51' },
      -- },
    })
  end,
}
```

ローカル開発中のパスを指定する例:

```lua
{
  dir = '/path/to/imhexnvim',
  name = 'imhex',
  cmd = { 'ImHexOpen', 'ImHexClose' },
  config = function()
    require('imhex').setup()
  end,
}
```

lazy.nvimの `opts`/`config=true` による自動呼び出しではなく、
`config=function() require('imhex').setup(opts) end` の明示呼び出しを推奨します。

## 使い方

- コマンド
  - `:ImHexOpen [path]` 現在のバッファ（未指定時）または指定パスのバイナリを開きます（ファイル補完対応）。
  - `:ImHexClose` Hexビューを閉じます。

- Lua API
  - `require('imhex').setup(opts)` 初期化（Lua 5.1デコーダを登録）
  - `require('imhex.ui').open(path)` 指定ファイルを開く
  - `require('imhex.ui').close()` 閉じる

例（現在編集中のファイルを開くマッピング）:

```lua
vim.keymap.set('n', '<leader>hx', function()
  require('imhex.ui').open(vim.api.nvim_buf_get_name(0))
end, { desc = 'Open current file in imhex viewer' })
```

## 設定（既定値）

```lua
{
  ui = {
    top_ratio = 0.7,      -- 上段（hex+ascii）エリアの高さ比
    column_ratio = 0.55,  -- hex:ascii の幅比（hex広め）
    bytes_per_row = 16,
    show_ascii = true,
    show_hex = true,
    show_format = true,
  },
  decode = {
    -- 先勝ち。最初にマッチしたデコーダを使用
    prefer = { 'lua51' },
  },
}
```

備考:
- `setup()` 時に `imhex.formatdecode.builtin.lua51` が自動登録されます。
- 追加のデコーダを使う場合は、`prefer` の順序で優先度を調整してください。

## トラブルシュート

- `:ImHexOpen` が見つからない: lazy.nvimで遅延読み込みの場合、`cmd = { 'ImHexOpen', 'ImHexClose' }` をspecに加えるか、起動時に `require('imhex').setup()` を実行してください。
- 何も起きない: `require('imhex').setup()` が呼ばれていない可能性があります。`config=function() ... end` 内で必ず呼んでください。

## License

Choose a license and add it to the repository (e.g. MIT). This starter ships without a license file by default.
