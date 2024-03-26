local net = require "@lune/net"

-- URL of a proxy to the database server (see db.ts)
local url = "http://localhost:3307"

--[=[
	Runs a database query and returns the rows of the result.
]=]
function query(content: string, ...: string | number): { any }?
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

	return body.rows
end

print "running starter queries"
query [[
	CREATE DATABASE IF NOT EXISTS main;
	USE main;
	CREATE TABLE IF NOT EXISTS user (
		username VARCHAR(255) NOT NULL PRIMARY KEY,
		password VARCHAR(255) NOT NULL
	);
	CREATE TABLE IF NOT EXISTS session (
		id VARCHAR(255) NOT NULL PRIMARY KEY,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	);
	CREATE TABLE IF NOT EXISTS post (
		id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
		time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
		content TEXT NOT NULL,
		username VARCHAR(255) NOT NULL,
		FOREIGN KEY (username) REFERENCES user(username)
	)]]

return query
