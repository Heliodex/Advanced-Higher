local db = require "db"

local fw = require "framework"
local Error = fw.error
local page: fw.Page = {}

function page.load(request): fw.Data
	local username = request.query.user
	if not username then
		return Error(400, "No user specified")
	end

	local posts = db.query(
		[[
			SELECT post.id, post.time, post.content, user.username FROM post
			JOIN user ON post.username = user.username
			WHERE user.username = ?
			ORDER BY post.time DESC
			LIMIT 10]],
		{ username }
	)

	print(posts)

	return {
		username = username,
		posts = posts,
	}
end

return page
