local auth = require "auth"
local query = require "db"

local fw = require "framework"
local Redirect = fw.redirect
local utils = fw.utils
local page: fw.Page = {}

page.actions = {
	default = function(request): fw.Response
		local loggedOut = auth.loggedOut(request.headers.cookie)
		if loggedOut and loggedOut.redirect then
			return loggedOut.redirect
		end

		local body = utils.parseBody(request.body)
		local username = string.lower(body.username or "")
		local password = body.password

		if not username or not password then
			return Redirect(302, "/register#invalid")
		end

		local users = query("SELECT 1 FROM user WHERE username = ?", username)

		if users and users[1] then
			return Redirect(302, "/register#taken")
		end

		local newCookie = utils.randomString(64)

		-- cant be bothered to hash passwords
		query(
			"INSERT INTO user (username, password) VALUES (?, ?)",
			username,
			password
		)
		query(
			"INSERT INTO session (id, username) VALUES (?, ?)",
			newCookie,
			username
		)

		return Redirect(302, "/", {
			["set-cookie"] = `session={newCookie}; Path=/`,
		})
	end,
}

return page
