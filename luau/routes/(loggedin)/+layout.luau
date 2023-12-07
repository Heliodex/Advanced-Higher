local net = require "@lune/net"
local redirect = require "../../framework/redirect"
local db = require "../../db"
local layout = {}

function layout:load(request: net.ServeRequest): net.ServeResponse
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if
		not cookie
		or not db:query("SELECT * FROM session WHERE id = ?", { cookie })[1]
	then
		return redirect(302, "/login")
	end

	return {}
end

return layout
