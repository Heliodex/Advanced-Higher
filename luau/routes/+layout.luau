local net = require "@lune/net"
local db = require "../db"
local layout = {}

function layout:load(request: net.ServeRequest): { [string]: any }
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	local user = db:query(
		[[
			SELECT user.username FROM user
			JOIN session ON user.username = session.username
			WHERE session.id = ?]],
		{ cookie }
	)[1]

	return {
		username = if user then user.username else false,
	}
end

return layout
