local query = require "db"

local fw = require "framework"
local layout: fw.Layout = {}

function layout.load(request): fw.Data
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	local user = query(
		[[
			SELECT user.username FROM user
			JOIN session ON user.username = session.username
			WHERE session.id = ?]],
		cookie
	)[1]

	return {
		username = if user then user.username else false,
	}
end

return layout
