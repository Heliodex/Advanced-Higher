local net = require "@lune/net"
local redirect = require "../../../framework/redirect"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if not cookie then
		print "returning to sender"
		return redirect(302, "/login")
	end

	return {}
end

return page
