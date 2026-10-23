-- ~/.config/nvim/init.lua
local matugen_theme = vim.fn.stdpath("config") .. "/lua/plugins/matugen-theme.lua"

if vim.loop.fs_stat(matugen_theme) then
  require("plugins.matugen-theme")
end
