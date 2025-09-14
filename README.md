# undump.nvim

undump.nvim is a neovim plugin for binary editor and format decoder.

# Features

- View binary file
- Edit binary file
- Format decode specified or infered pattern 

# Installation
## `lazy.nvim` 
```lua
{
    "takeshid/undump.nvim",
    config = function()
        require("undump").setup()
    end
}
```

# Builtin Decoder
| Name     | Status      |
| -------- | --------    |
| Lua51    | ☑ Suppurted |
| Lua52    | Planned     |
| Lua53    | Planned     |
| Lua54    | Planned     |
| LuaJIT   | Planned     |
| zip      | Planned     |
| vhdx     | Planned     |
| pcap     | Planned     |
| elf      | Planned     |

# Custom Decoder
You create custome decoder.


## License
This project is licensed under the MIT License.  
See [LICENSE](./License)  
