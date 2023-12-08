local net = require "@lune/net"
local redirect = require "../../../framework/redirect"
local auth = require "../../../auth"
local db = require "../../../db"
local utils = require "../../../framework/utils"
local page = {}

page.actions = {
	default = function(request: net.ServeRequest): net.ServeResponse
		local loggedOut = auth:loggedOut(request.headers.cookie)
		if loggedOut and loggedOut.redirect then
			return loggedOut.redirect
		end

		-- parse request.body for username and password
		-- it's in the formmat of "username=foo&password=bar"
		local body = utils.parseBody(request.body)
		local username = string.lower(body.username or "")
		local password = body.password

		if not username or not password then
			return redirect(302, "/login#incorrect")
		end

		local user = db:query(
			"SELECT * FROM user WHERE username = ? AND password = ?",
			{ username, password }
		)[1]

		if not user then
			return redirect(302, "/login#incorrect")
		end

		local newCookie = utils.randomString(64)

		db:query("INSERT INTO session (id, username) VALUES (?, ?)", {
			newCookie,
			username,
		})

		return redirect(302, "/", {
			["set-cookie"] = `session={newCookie}; Path=/`,
		})
	end,
}

return page
