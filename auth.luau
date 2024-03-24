local query = require "db"

local fw = require "framework"
local Redirect = fw.redirect
local auth = {}

function auth.parseCookie(cookie: string): string?
	return cookie and string.match(cookie, "session=([^;]+)")
end

function auth.loggedOut(cookie: string): { redirect: fw.Response }?
	local parsedCookie = auth.parseCookie(cookie)

	if parsedCookie then
		local sessions =
			query("SELECT 1 FROM session WHERE id = ?", parsedCookie)

		if sessions and sessions[1] then
			return { redirect = Redirect(302, "/") }
		end
	end
	return
end

function auth.loggedIn(cookie: string): {
	redirect: fw.Response?,
	cookie: string?,
}
	local parsedCookie = auth.parseCookie(cookie)
	if not parsedCookie then
		return { redirect = Redirect(302, "/login") }
	end

	local sessions = query("SELECT 1 FROM session WHERE id = ?", parsedCookie)
	if not (sessions and sessions[1]) then
		return { redirect = Redirect(302, "/login") }
	end
	return { cookie = parsedCookie }
end

return auth
