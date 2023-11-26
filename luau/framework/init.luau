local fs = require "@lune/fs"
local net = require "@lune/net"
local stdio = require "@lune/stdio"

local colour = stdio.color
local write = stdio.write

local blue = colour "blue"
local green = colour "green"
local purple = colour "purple"
local red = colour "red"
local reset = colour "reset"
local yellow = colour "yellow"

--[=[
	Framework description
]=]
local framework = {}
framework.__index = framework

type Config = {
	verbose: boolean?,
}

function framework:_log(colourName: stdio.Color?, message: string)
	if not (self.config and self.config.verbose) then
		return
	end

	write(
		if colourName
			then `{colour(colourName)}{message}{reset}\n`
			else `{message}\n`
	)
end

function logReq(request: net.ServeRequest, status: number)
	local method = request.method
	local path = request.path

	-- Colour the status number
	local colouredStatus = if 200 < status and status < 300
		then green .. status
		elseif 300 < status and status < 400 then yellow .. status
		elseif 400 < status and status < 500 then red .. status
		elseif 500 < status and status < 600 then purple .. status
		else status

	-- Colour the method name
	local colouredMethod = if method == "GET"
		then green .. method
		elseif method == "POST" then blue .. method
		elseif method == "PUT" then yellow .. method
		elseif method == "DELETE" then red .. method
		else method

	print(`[{colouredStatus}{reset}]`, colouredMethod, reset, path)
end

function framework:_requester(
	method: string,
	path: string,
	callback: (
		request: net.ServeRequest
	) -> net.ServeResponse
)
	self._routes = self._routes or {}
	self._routes[path] = self._routes[path] or {}
	table.insert(self._routes[path], {
		method = method,
		path = path,
		callback = callback,
	})

	return self
end

local function readRecursive(path: string)
	local dir = fs.readDir(path)
	local files = {}

	for _, file in ipairs(dir) do
		local filePath = path .. "/" .. file
		local isDir = fs.isDir(filePath)

		if isDir then
			local subFiles = readRecursive(filePath)
			for _, subFile in ipairs(subFiles) do
				table.insert(files, file .. "/" .. subFile)
			end
		else
			table.insert(files, file)
		end
	end

	return files
end

function framework:mount(filepath: string, path: string)
	-- local dir = readRecursive(path)
	self._fileroutes = self._fileroutes or {}
	table.insert(self._fileroutes, {
		filepath = filepath,
		path = path,
	})

	return self
end

type Headers = {
	[string]: string,
	set: (self: Headers, header: string, value: string) -> nil,
}

type Callback = (
	body: string,
	headers: Headers,
	query: {
		[string]: string,
	}
) -> net.ServeResponse

--[=[
	Registers a GET route.
]=]
function framework:get(path: string, callback: Callback)
	return self:_requester("GET", path, callback)
end

--[=[
	Registers a HEAD route.
]=]
function framework:head(path: string, callback: Callback)
	return self:_requester("HEAD", path, callback)
end

--[=[
	Registers a POST route.
]=]
function framework:post(path: string, callback: Callback)
	return self:_requester("POST", path, callback)
end

--[=[
	Registers a PUT route.
]=]
function framework:put(path: string, callback: Callback)
	return self:_requester("PUT", path, callback)
end

--[=[
	Registers a DELETE route.
]=]
function framework:delete(path: string, callback: Callback)
	return self:_requester("DELETE", path, callback)
end

--[=[
	Registers a PATCH route.
]=]
function framework:patch(path: string, callback: Callback)
	return self:_requester("PATCH", path, callback)
end

--[=[
	Listens on the specified port.
]=]
function framework:listen(port: number)
	self:_log("green", `Listening on http://localhost:{port}/`)

	net.serve(port, function(request)
		local path = request.path

		local fileroutes = self._fileroutes

		if fileroutes then
			for _, route in ipairs(fileroutes) do
				-- if path starts with route.path
				if string.sub(path, 1, #route.path) == route.path then
					local file = fs.readFile(route.filepath .. path)
					logReq(request, 200)
					return {
						status = 200,
						body = file,
						headers = request.headers,
					}
				end
			end
		end

		local routes = self._routes[path]

		if not routes then
			-- Remove trailing slash
			if string.sub(path, -1) == "/" then
				path = string.sub(path, 1, -2)
			end
			if not self._routes[path] then
				logReq(request, 404)
				return {
					status = 404,
					body = "Not Found",
				}
			end
		end

		for _, route in ipairs(routes) do
			if route.method == request.method then
				logReq(request, 200)

				local result =
					route.callback(request.body, request.headers, request.query)

				if type(result) == "string" then
					return {
						status = 200,
						body = result,
						headers = request.headers,
					}
				end

				-- result is a net.ServeResponse table
				return result
			end
		end

		logReq(request, 405)
		return {
			status = 405,
			body = "Method Not Allowed",
		}
	end)
end

local createFramework = {}

--[=[
	Creates a new framework instance.
]=]
function createFramework:new(config: Config?)
	local this = setmetatable({}, framework)
	this.config = config
	this:_log("blue", "Verbose mode enabled")
	return this
end

return createFramework
