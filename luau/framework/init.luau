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
	local colouredStatus = if 200 <= status and status < 300
		then green .. status
		elseif 300 <= status and status < 400 then yellow .. status
		elseif 400 <= status and status < 500 then red .. status
		elseif 500 <= status and status < 600 then purple .. status
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

--[=[
	Sets the public directory, where static files are served from.
]=]
function framework:public(filepath: string?)
	self._public = filepath or "public"
	return self
end

--[=[
	Sets the routes directory, where routes are loaded from.
]=]
function framework:routes(filepath: string?)
	self._routes = filepath or "routes"
	return self
end

local function loadRoute(
	filename: string,
	request: net.ServeRequest,
	status: number
)
	local ok, page = pcall(require, filename)
	if not ok then
		error(page)
	end

	-- let's do this

	local load = page:load(request, status)

	return load
end

local function loadError(
	basePath: string,
	status: number,
	request: net.ServeRequest
): net.ServeResponse
	-- bubble up the directory tree, looking for an error page to show
	while true do
		local errorFilename = `{basePath}/+error.luau`
		local ok2, isErrorFile = pcall(fs.isFile, errorFilename)
		if ok2 and isErrorFile then
			local errok, res = pcall(loadRoute, errorFilename, request, status)

			if not errok then
				warn(res)
				local newPath = string.match(basePath, "^(.*)/[^/]*$")
				if newPath == basePath then
					break
				end
				return loadError(newPath, 500, request)
			end

			logReq(request, status)

			if type(res) == "string" then
				return {
					status = status,
					body = res,
				}
			end

			return res
		end

		if not basePath then
			return {
				status = 500,
				body = "Internal Server Error",
			}
		end

		-- Set newpath to the parent directory
		local newPath = string.match(basePath, "^(.*)/[^/]*$")
		if newPath == basePath then
			break
		end

		basePath = newPath
	end

	return {
		status = status,
		body = "Not Found",
	}
end

--[=[
	Listens on the specified port.
]=]
function framework:listen(port: number)
	self:_log("green", `Listening on http://localhost:{port}/`)

	net.serve(port, function(request)
		local path = request.path
		if string.sub(path, -1) == "/" then
			path = string.sub(path, 1, -2)
		end

		local public: string = self._public

		if public then
			local filename = public .. path
			local ok, readFile = pcall(fs.readFile, filename)
			if ok then
				logReq(request, 200)
				return {
					status = 200,
					body = readFile,
				}
			end
		end

		local routes: string = self._routes

		if routes then
			local basePath = routes .. path
			local pageFilename = `{basePath}/+page.luau`
			local ok, isRouteFile = pcall(fs.isFile, pageFilename)
			if ok and isRouteFile then
				local routeok, res =
					pcall(loadRoute, pageFilename, request, 200)

				if not routeok then
					warn(res)
					return loadError(basePath, 500, request)
				end

				logReq(request, 200)

				if type(res) == "string" then
					return {
						status = 200,
						body = res,
					}
				end

				return res
			end

			return loadError(basePath, 404, request)
		end

		logReq(request, 404)
		return {
			status = 404,
			body = "Not Found",
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
