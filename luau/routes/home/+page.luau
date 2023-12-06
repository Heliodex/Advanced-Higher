local net = require "@lune/net"
local redirect = require "../../framework/redirect"
local db = require "../../db"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if not cookie then
		print "returning to sender"
		return redirect(302, "/login")
	end

	local user = db:query(
		[[
			SELECT user.username FROM user
			JOIN session ON user.username = session.username
			WHERE session.id = ?]],
		{ cookie }
	)[1]

	if not user then
		return redirect(302, "/login")
	end

	return {
		username = user.username,
	}
end

return page
