local query = require "db"

local fw = require "framework"
local page: fw.Page = {}

function page.load(request): fw.Data
	local search = request.query.q
	if not search then
		return {
			search = "",
		}
	end

	local posts = query [[
		SELECT post.id, post.time, post.content, user.username FROM post
		JOIN user ON post.username = user.username]]

	print(posts)

	return {
		search = search,
		posts = posts,
	}
end

return page
