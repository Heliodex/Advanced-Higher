local net = require "@lune/net"
local redirect = require "../../../framework/redirect"
local db = require "../../../db"
local utils = require "../../../framework/utils"
local page = {}

page.actions = {
	default = function(request: net.ServeRequest): net.ServeResponse
		local cookie = request.headers.cookie
		cookie = cookie and string.match(cookie, "session=([^;]+)")

		if cookie then
			local session =
				db:query("SELECT * FROM session WHERE id = ?", { cookie })

			if session[1] then
				return redirect(302, "/home")
			end
		end

		-- parse request.body for username and password
		-- it's in the formmat of "username=foo&password=bar"
		local username =
			string.lower(string.match(request.body, "username=([^&]+)") or "")
		local password = string.match(request.body, "password=([^&]+)")

		if not username or not password then
			return redirect(302, "/login#incorrect")
		end

		local user = db:query(
			"SELECT * FROM user WHERE username = ? AND password = ?",
			{ username, password }
		)[1]

		print("user", user)

		if not user then
			return redirect(302, "/login#incorrect")
		end

		local newCookie = utils.randomString(64)

		db:query("INSERT INTO session (id, username) VALUES (?, ?)", {
			newCookie,
			username,
		})

		return redirect(302, "/home", {
			["set-cookie"] = `session={newCookie}; Path=/`,
		})
	end,
}

return page
