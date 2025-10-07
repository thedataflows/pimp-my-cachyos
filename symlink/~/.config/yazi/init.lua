-- https://github.com/yazi-rs/plugins/tree/main/full-border.yazi
require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}

-- https://github.com/yazi-rs/plugins/tree/main/git.yazi
require("git"):setup()
th.git = th.git or {}
th.git.modified_sign = "M"
th.git.modified = ui.Style():fg("blue")
th.git.deleted_sign = "D"
th.git.deleted = ui.Style():fg("red"):bold()
th.git.untracked_sign = "X"
th.git.untracked = ui.Style():fg("yellow")

-- https://yazi-rs.github.io/docs/tips#username-hostname-in-header
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ui.Line {}
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end, 500, Header.LEFT)

-- https://yazi-rs.github.io/docs/tips#user-group-in-status
Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line {}
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		ui.Span(":"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		ui.Span(" "),
	}
end, 500, Status.RIGHT)

require("zoxide"):setup {
	update_db = true,
}

function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%d %b %H:%M", time)
	else
		time = os.date("%d %b %Y", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "", time)
end
