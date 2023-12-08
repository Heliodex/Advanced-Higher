local net = require "@lune/net"
local db = require "../../../db"
local page = {}

function page:load(request: net.ServeRequest): net.ServeResponse
	local username = request.query.user
	if not username then
		return {
			status = 400,
			body = "No user specified",
		}
	end

	local posts = db:query [[
		SELECT post.id, post.time, post.content, user.username FROM post
		JOIN user ON post.username = user.username
		WHERE user.username = ?
		ORDER BY post.time DESC
		LIMIT 10]]

	return {
		posts = posts,
	}
end

return page
