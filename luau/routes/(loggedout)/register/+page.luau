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
		local username =
			string.lower(string.match(request.body, "username=([^&]+)") or "")
		local password = string.match(request.body, "password=([^&]+)")

		if not username or not password then
			return redirect(302, "/register#invalid")
		end

		local user =
			db:query("SELECT * FROM user WHERE username = ?", { username })

		if user[1] then
			return redirect(302, "/register#taken")
		end

		local newCookie = utils.randomString(64)

		-- cant be bothered to hash passwords
		db:query("INSERT INTO user (username, password) VALUES (?, ?)", {
			username,
			password,
		})
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
