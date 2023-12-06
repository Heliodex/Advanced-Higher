local net = require "@lune/net"
local redirect = require "../../framework/redirect"
local db = require "../../db"
local utils = require "../../utils"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse
	local cookie = request.headers.cookie
	cookie = cookie and string.match(cookie, "session=([^;]+)")

	if cookie then
		local session =
			db:query("SELECT * FROM session WHERE id = ?", { cookie })

		if session[1] then
			return redirect(302, "/home")
		end
	end

	return {}
end

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
		local username = string.match(request.body, "username=([^&]+)")
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

		return redirect(302, "/home", {
			["set-cookie"] = `session={newCookie}`,
		})
	end,
}

return page
