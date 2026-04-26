vim.g.mapleader = " "

-- 個人偏好
vim.opt.scrolloff = 10
vim.opt.wrap = true
vim.opt.conceallevel = 0
vim.opt.splitkeep = "cursor"
vim.opt.mouse = ""
vim.opt.cmdheight = 0
vim.opt.completeopt = { "menu", "menuone", "noselect", "noinsert", "popup" }

-- LazyVim 開關
vim.g.lazyvim_prettier_needs_config = true
vim.g.lazyvim_picker = "telescope"
vim.g.lazyvim_cmp = "blink.cmp"
vim.g.snacks_animate = false
vim.g.root_spec = { "cwd" }
