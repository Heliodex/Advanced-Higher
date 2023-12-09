local net = require "@lune/net"
local Error = require "../../framework/error"
local Redirect = require "../../framework/redirect"
local db = require "../../db"
local page = {}

function page:load() 	
	return Error(404, "Not Found")
end

page.actions = {
	default = function(request: net.ServeRequest): net.ServeResponse
		local cookie = request.headers.cookie
		cookie = cookie and string.match(cookie, "session=([^;]+)")

		print(db:query("DELETE FROM session WHERE id = ?", { cookie }))

		return Redirect(302, "/")
	end,
}

return page
