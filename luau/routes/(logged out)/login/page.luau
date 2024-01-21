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
			return Redirect(302, "/login#missing")
		end

		local user = query(
			"SELECT * FROM user WHERE username = ? AND password = ?",
			username,
			password
		)[1]

		if not user then
			return Redirect(302, "/login#incorrect")
		end

		local newCookie = utils.randomString(64)

		query(
			"INSERT INTO session (id, username) VALUES (?, ?)",
			newCookie,
			username
		)

		print "Logged in"

		return Redirect(302, "/", {
			["set-cookie"] = `session={newCookie}; Path=/`,
		})
	end,
}

return page
