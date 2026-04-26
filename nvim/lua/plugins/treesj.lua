return {
	"Wansmer/treesj",
	keys = { "<space>jj" },
	vscode = true,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("treesj").setup({
			use_default_keymaps = false,
		})
	end,
}
