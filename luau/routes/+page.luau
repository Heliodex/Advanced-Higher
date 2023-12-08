local net = require "@lune/net"
local redirect = require "../framework/redirect"
local utils = require "../framework/utils"
local auth = require "../auth"
local db = require "../db"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse
	local loggedIn = auth:loggedIn(request.headers.cookie)
	if loggedIn.redirect then
		return loggedIn.redirect
	end

	local posts = db:query [[
		SELECT post.id, post.time, post.content, user.username FROM post
		JOIN user ON post.username = user.username
		ORDER BY post.time DESC
		LIMIT 10]]

	return {
		posts = posts,
	}
end

page.actions = {
	default = function(request: net.ServeRequest)
		local loggedIn = auth:loggedIn(request.headers.cookie)
		if loggedIn.redirect then
			return loggedIn.redirect
		end

		local content = utils.parseBody(request.body).content

		if not content then
			return redirect(302, "/#invalid")
		end

		print(db:query(
			[[
				INSERT INTO post (content, username)
				SELECT ?, user.username
				FROM user
				JOIN session ON user.username = session.username
				WHERE session.id = ?]],
			{ content, loggedIn.cookie }
		))

		return redirect(302, "/")
	end,
}

return page
