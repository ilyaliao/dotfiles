return {
	"keaising/im-select.nvim",
	event = "VeryLazy",
	opts = {
		-- plugin 新版預設用 macism,我們直接走既有 im-select
		default_command = "im-select",
		-- 一律切回的英文輸入法 ID
		default_im_select = "com.apple.keylayout.ABC",
		-- 不自動還原前一次用的輸入法 → 永遠英文 (VSCode 風)
		set_previous_events = {},
		-- 進 nvim / 取得焦點 / 離開 insert / 離開 cmdline / 進入 insert 都強制切回英文
		set_default_events = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave", "InsertEnter" },
	},
}
