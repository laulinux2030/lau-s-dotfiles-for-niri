-- ~/.config/matugen/templates/neovim.lua
-- ~/.config/matugen/templates/neovim.lua
local colors = {
  bg                     = "NONE", -- Transparent für den Hauptcode
  fg                     = "{{colors.on_surface.default.hex}}",
  cursor                 = "{{colors.primary.default.hex}}",
  primary                = "{{colors.primary.default.hex}}",
  secondary              = "{{colors.secondary.default.hex}}",
  tertiary               = "{{colors.tertiary.default.hex}}",
  error                  = "{{colors.error.default.hex}}",
  
  -- Neuer Farbton für Menüs, Popups & Leisten (höherer Kontrast/andere Stufe)
  surface_container_high = "{{colors.surface_container_high.default.hex}}",
  surface_variant        = "{{colors.surface_variant.default.hex}}",
  on_surface_var         = "{{colors.on_surface_variant.default.hex}}",
}

local hl = vim.api.nvim_set_hl

-- 1. Haupteditor (Transparent)
hl(0, "Normal", { fg = colors.fg, bg = colors.bg })
hl(0, "NormalNC", { fg = colors.fg, bg = colors.bg })
hl(0, "SignColumn", { bg = colors.bg })
hl(0, "FoldColumn", { bg = colors.bg })
hl(0, "EndOfBuffer", { fg = colors.surface_variant, bg = colors.bg })

-- 2. Schwebende Fenster / PopUp-Menüs (Mit neuem Farbton)
hl(0, "NormalFloat", { fg = colors.fg, bg = colors.surface_container_high })
hl(0, "FloatBorder", { fg = colors.primary, bg = colors.surface_container_high })
hl(0, "FloatTitle", { fg = colors.primary, bg = colors.surface_container_high, bold = true })

-- Autocomplete / Popup Menu (Pmenu)
hl(0, "Pmenu", { fg = colors.fg, bg = colors.surface_container_high })
hl(0, "PmenuSel", { fg = colors.surface_container_high, bg = colors.primary, bold = true })
hl(0, "PmenuSbar", { bg = colors.surface_variant })
hl(0, "PmenuThumb", { bg = colors.primary })

-- 3. Statusleiste unten (Mit neuem Farbton)
hl(0, "StatusLine", { fg = colors.fg, bg = colors.surface_container_high, bold = true })
hl(0, "StatusLineNC", { fg = colors.on_surface_var, bg = colors.surface_variant })

-- 4. Syntax & Basic UI Highlights
hl(0, "Cursor", { fg = colors.bg, bg = colors.cursor })
hl(0, "LineNr", { fg = colors.secondary, bg = colors.bg })
hl(0, "CursorLineNr", { fg = colors.primary, bg = colors.bg, bold = true })
hl(0, "Comment", { fg = colors.on_surface_var, italic = true })
hl(0, "Keyword", { fg = colors.primary, bold = true })
hl(0, "String", { fg = colors.secondary })
hl(0, "Function", { fg = colors.tertiary })
hl(0, "Error", { fg = colors.error })
