local auth = require "auth"
local query = require "db"

local fw = require "framework"
local layout: fw.Layout = {}

type User = {
	username: string,
}

function layout.load(request): fw.Data
	local parsedCookie = auth.parseCookie(request.headers.cookie)
	if not parsedCookie then
		return {
			username = false,
		}
	end

	local users: { User }? = query(
		[[
			SELECT user.username FROM user
			JOIN session ON user.username = session.username
			WHERE session.id = ?]],
		parsedCookie
	)

	local user = users and users[1]

	return {
		username = if user then user.username else false,
	}
end

return layout
