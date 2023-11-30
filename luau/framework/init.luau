local fs = require "@lune/fs"
local net = require "@lune/net"
local stdio = require "@lune/stdio"

local template = require "template"

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

local function logReq(request: net.ServeRequest, status: number)
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

type Data = { [string]: any }

local function loadRoute(
	path: string,
	filetype: string, -- "page" | "error" fux up the pcall
	request: net.ServeRequest,
	status: number,
	err: string?
): net.ServeResponse | string
	local filename = `{path}/+page.luau`

	local load: Data

	if filetype == "page" then
		local ok, pageServer: {
			load: (
				self: any,
				request: net.ServeRequest,
				status: number,
				err: string?
			) -> Data,
		} =
			pcall(require, filename)
		if not ok then
			error(pageServer)
		end

		-- let's do this
		load = pageServer:load(request, status, err)
	else
		load = {
			status = status,
			err = err,
		}
	end

	-- compile and add +page.tmpl file
	local pageFilename = `{path}/+{filetype}.tmpl`
	local ok2, isPageFile = pcall(fs.isFile, pageFilename)

	if not ok2 then
		error(isPageFile)
	end

	local compiledPath = `.compiled{path}/__{filetype}.luau`

	-- compile the layout template
	local readok, pageFile = pcall(fs.readFile, pageFilename)
	if not readok then
		if filetype == "error" then
			-- bubble up the directory tree, looking for an error template
			while true do
				local errorFilename = `{path}/+error.tmpl`
				local ok3, isErrorFile = pcall(fs.isFile, errorFilename)
				if ok3 and isErrorFile then
					-- compile the layout template
					local compiledLayoutPath = `.compiled{path}/__error.luau`

					fs.writeFile(
						compiledLayoutPath,
						template.parse(fs.readFile(errorFilename), true)
					)

					local layoutok, layout: (args: Data, SLOT: string) -> string =
						pcall(require, compiledLayoutPath)

					if not layoutok then
						error(layout)
					end

					return layout(load, "body")
				end

				local newPath = string.match(path, "^(.*)/[^/]*$")
				if not newPath then
					print "using default error template"
					pageFile = [[{status} {err}]]
					break
				end

				path = newPath
			end
		end
	end

	-- create each directory in the path if it doesn't exist
	local currentPath = ""
	for dir in string.gmatch(compiledPath, "[^/]+") do
		-- don't create the last part of the path
		if dir == `__{filetype}.luau` then
			break
		end
		currentPath ..= dir .. "/"
		if not fs.isDir(currentPath) then
			fs.writeDir(currentPath)
		end
	end

	fs.writeFile(compiledPath, template.parse(pageFile))

	local pageok, page: (args: { [string]: any }) -> string =
		pcall(require, compiledPath)

	if not pageok then
		if filetype == "error" then
			load = {
				status = status,
				error = err,
			}
		else
			error(page)
		end
	end

	local templated = page(load)

	-- bubble up the directory tree, adding layout files
	while true do
		local layoutFilename = `{path}/+layout.tmpl`
		print("reading", layoutFilename)
		local ok3, isLayoutFile = pcall(fs.isFile, layoutFilename)
		if ok3 and isLayoutFile then
			-- compile the layout template
			local compiledLayoutPath = `.compiled{path}/__layout.luau`

			fs.writeFile(
				compiledLayoutPath,
				template.parse(fs.readFile(layoutFilename), true)
			)

			local layoutok, layout: (args: Data, SLOT: string) -> string =
				pcall(require, compiledLayoutPath)

			if not layoutok then
				error(layout)
			end

			templated = layout({}, templated)
		end

		local newPath = string.match(path, "^(.*)/[^/]*$")
		if not newPath then
			break
		end

		path = newPath
	end

	return templated
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
					pcall(loadRoute, basePath, "page", request, 200)

				if not routeok then
					warn(res)
					return loadRoute(
						basePath,
						"error",
						request,
						500,
						tostring(res)
					)
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

			return loadRoute(basePath, "error", request, 404, "Not Found")
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
