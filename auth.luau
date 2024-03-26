local query = require "db"

local fw = require "framework"
local Redirect = fw.redirect
local auth = {}

--[=[
	Parses the user's cookie to get the session token.
]=]
function auth.parseCookie(cookie: string): string?
	return cookie and string.match(cookie, "session=([^;]+)")
end

--[=[
	Checks if the user is logged out. If not, redirects to the home page.
	Used to prevent logged in users from accessing pages only available to logged out users (eg. login, register)
]=]
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

--[=[
	Checks if the user is logged in. If not, redirects to the login page.
	Used to prevent logged out users from accessing pages only available to logged in users
]=]
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
