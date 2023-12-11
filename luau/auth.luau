local db = require "db"
local Redirect = require "framework/redirect"

local auth = {}

function auth:loggedOut(cookie: string)
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if cookie then
		local session =
			db.query("SELECT * FROM session WHERE id = ?", { cookie })

		if session[1] then
			return { redirect = Redirect(302, "/") }
		end
	end
	return false
end

function auth:loggedIn(cookie: string)
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if
		not cookie
		or not db.query("SELECT * FROM session WHERE id = ?", { cookie })[1]
	then
		return { redirect = Redirect(302, "/login") }
	end
	return { cookie = cookie }
end

return auth
