local net = require "@lune/net"
local redirect = require "../../framework/redirect"
local db = require "../../db"
local page = {}

function page:load() end

page.actions = {
	default = function(request: net.ServeRequest): net.ServeResponse
		local cookie = request.headers.cookie
		cookie = cookie and string.match(cookie, "session=([^;]+)")

		print(db:query("DELETE FROM session WHERE id = ?", { cookie }))

		return redirect(302, "/")
	end,
}

return page
