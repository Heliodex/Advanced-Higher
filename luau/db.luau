local net = require "@lune/net"

-- URL of a proxy to the database server (see db.ts)
local url = "http://localhost:3307"

function query(content: string, ...: string | number)
	local body

	for _ = 1, 2 do
		if body and body.error then
			print "retrying query"
			query "USE main"
		elseif body then
			break
		end

		local res = net.request {
			url = url,
			method = "POST",
			body = net.jsonEncode {
				query = content,
				params = { ... },
			},
		}

		body = net.jsonDecode(res.body)
	end

	return if body.rows then body.rows else body
end

print "running starter queries"
query "CREATE DATABASE IF NOT EXISTS main"
query "USE main"
query [[
	CREATE TABLE IF NOT EXISTS user (
		username VARCHAR(255) NOT NULL PRIMARY KEY,
		password VARCHAR(255) NOT NULL
	)]]
query [[
	CREATE TABLE IF NOT EXISTS session (
		id VARCHAR(255) NOT NULL PRIMARY KEY,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	)]]
query [[
	CREATE TABLE IF NOT EXISTS post (
		id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
		time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
		content TEXT NOT NULL,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	)]]

return query
