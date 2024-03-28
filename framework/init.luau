-- This file is the entry point for the framework.
-- It contains the main server logic, filesystem-based routing, and serving static files.

local fs = require "@lune/fs"
local luau = require "@lune/luau"
local net = require "@lune/net"
local stdio = require "@lune/stdio"

local compile = require "compile"
local template = require "template"
local utils = require "utils"

local colour = stdio.color
local write = stdio.write

local blue = colour "blue"
local green = colour "green"
local purple = colour "purple"
local red = colour "red"
local reset = colour "reset"
local yellow = colour "yellow"
local cyan = colour "cyan"

type Config = {
	verbose: boolean?,
}

type Framework = {
	-- The configuration for the framework.
	config: Config?,
	-- The public directory, where static files are served from.
	_public: string?,
	-- The routes directory, where routes are loaded from.
	_routes: string?,

	_log: (self: Framework, colourName: stdio.Color, message: string) -> (),
	public: (self: Framework, filepath: string?) -> Framework,
	routes: (self: Framework, filepath: string?) -> Framework,
	listen: (self: Framework, port: number) -> (),

	__index: Framework,
}

local framework = {} :: Framework
framework.__index = framework

function framework:_log(colourName: stdio.Color, message: string)
	if not (self.config and self.config.verbose) then
		return
	end

	write(
		if colourName
			then `{colour(colourName)}{message}{reset}\n`
			else `{message}\n`
	)
end

local function logReq(request: Request, status: number, time: number)
	local timeTaken = math.round((os.clock() - time) * 1000000)
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

	print(
		`[{colouredStatus}{reset}]`,
		colouredMethod,
		reset,
		path,
		cyan,
		if timeTaken > 1000
			then `({math.round(timeTaken / 1000)}ms)`
			else `({timeTaken}µs)`,
		reset
	)
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

export type Data = { [string]: any }
export type Request = net.ServeRequest
export type Response = net.ServeResponse
export type Page = {
	load: ((request: Request, status: number, err: string?) -> Data)?,
	actions: {
		[string]: (request: Request) -> Response | string,
	}?,
}
export type Layout = {
	load: ((request: Request, status: number, err: string?) -> Data)?,
}

local function loadRoute(
	path: string,
	filetype: "page" | "error",
	request: Request,
	status: number,
	err: string?
): Response | string
	local filename = `{path}/page.luau`
	local load: Data
	local method = request.method

	if filetype == "page" then
		local ok, pageServer: {
			load: ((
				request: Request,
				status: number,
				err: string?
			) -> Data)?,
			actions: {
				[string]: (request: Request) -> Response | string,
			}?,
		} = pcall(
			function()
				return luau.load(fs.readFile(filename))()
			end
		)

		if method == "GET" then
			load = if ok and pageServer.load
				then pageServer.load(request, status, err)
				else {}

			if load._raw == true then
				load._raw = nil
				return load
			elseif load._error == true then
				return loadRoute(path, "error", request, load.status, load.err)
			end
		elseif method == "POST" and ok and pageServer.actions then
			local action = request.query[""] or "default" -- Page action is specified in a query parameter
			local actionFunc = pageServer.actions[action]

			if actionFunc then
				return actionFunc(request)
			end
			return {
				status = 405,
				body = "405 Method Not Allowed",
			}
		else
			return {
				status = 405,
				body = "405 Method Not Allowed",
			}
		end
	else
		load = {
			status = status,
			err = err,
		}
	end

	-- compile and add page.ltmp file
	local ok, pageFile = pcall(fs.readFile, `{path}/{filetype}.ltmp`)

	if not ok then
		pageFile = `{status} {err}`
	end

	local layoutPath = path

	-- bubble up the directory tree, adding layout.luau files
	while true do
		local ok2, layoutServer: {
			load: ((
				request: Request,
				status: number,
				err: string?
			) -> Data)?,
		} = pcall(
			function()
				return luau.load(fs.readFile(`{layoutPath}/layout.luau`))()
			end
		)

		if ok2 and layoutServer.load then
			local layoutLoad = layoutServer.load(request, status, err)

			if layoutLoad._raw == true then
				layoutLoad._raw = nil
				return layoutLoad
			elseif layoutLoad._error == true then
				return loadRoute(
					path,
					"error",
					request,
					layoutLoad.status,
					layoutLoad.err
				)
			end

			-- merge the layout's load with the existing load
			-- existing load (further down the tree) takes priority
			load = utils.merge(layoutLoad, load)
		end

		local newLayoutPath = string.match(layoutPath, "^(.*)/[^/]*$")
		if not newLayoutPath then
			break
		end
		layoutPath = newLayoutPath
	end

	-- compile the layout template
	local templated
	local compiled = template(pageFile)

	if not compiled then
		-- bubble up the directory tree, looking for an error template
		while true do
			print("compiling error template", path)
			local layout = compile(path, "error")

			if layout then
				templated = layout(load)
				break
			end

			local newPath = string.match(path, "^(.*)/[^/]*$")
			if not newPath then
				templated = `{status} {err}`
				break
			end

			path = newPath
		end
	end

	if not templated then
		local pageok, page: () -> string = pcall(luau.load, compiled, {
			environment = load,
		})

		if not pageok then
			if filetype == "error" then
				load = {
					status = status,
					error = err,
				}
			else
				templated = `{status} {err}`
			end
		else
			templated = page()
		end
	end

	-- bubble up the directory tree, adding layout files
	while true do
		local layout = compile(path, "layout")

		if layout then
			templated = layout(utils.merge(load, {
				SLOT = templated,
			}))
		end

		local newPath = string.match(path, "^(.*)/[^/]*$")
		if not newPath then
			break
		end

		path = newPath
	end

	return {
		status = status,
		body = templated,
	}
end

local function getRoutePath(path: string): string?
	-- check if "routes/testing/something/page.ltmp" exists,
	-- but also check if "routes/(layout)/testing/something" exists
	-- (layouts are enclosed in parentheses)

	-- split the path into parts
	local parts = {}
	for part in string.gmatch(path, "[^/]+") do
		table.insert(parts, part)
	end

	for i = #parts, 1, -1 do
		-- get the first x parts of the path, and check if it exists
		local newPath = table.concat(parts, "/", 1, i)
		local ok, pathExists = pcall(fs.isDir, newPath)

		if ok and pathExists then
			continue
		end

		-- the path doesn't exist, let's do some sleuthing

		newPath = table.concat(parts, "/", 1, i - 1)

		local possibleLayouts = {}
		for _, entry in fs.readDir(newPath) do
			if string.match(entry, "^%(.+%)$") then
				table.insert(possibleLayouts, entry)
			end
		end

		if #possibleLayouts == 0 then
			-- no layouts found, path isn't there
			return
		end

		-- for each possible layout, check if the next part of the path exists
		for _, layout in possibleLayouts do
			local layoutPath = getRoutePath(
				table.concat({ newPath, layout, table.unpack(parts, i) }, "/")
			)
			if layoutPath then
				return layoutPath
			end
		end

		return
	end

	return table.concat(parts, "/")
end

-- Serve content from the specified public directory
local function servePublic(
	request: Request,
	public: string,
	path: string,
	startTime: number
): (Response | string)?
	local filename = public .. path
	local ok, readFile = pcall(fs.readFile, filename)
	if ok then
		logReq(request, 200, startTime)
		return {
			status = 200,
			body = readFile,
			headers = {
				["Cache-Control"] = "max-age=31536000",
			},
		}
	end
	return
end

-- Serve pages from the specified routes directory
local function serveRoutes(
	request: Request,
	routes: string,
	path: string,
	startTime: number
): (Response | string)?
	if routes then
		local basePath = routes .. path
		local gotPath = getRoutePath(basePath) or basePath

		local routePageFilename = `{gotPath}/page.ltmp`
		local routeServerFilename = `{gotPath}/page.luau`

		local pageOk, isRoutePage = pcall(fs.isFile, routePageFilename)
		local serverOk, isRouteServer = pcall(fs.isFile, routeServerFilename)
		if (pageOk and isRoutePage) or (serverOk and isRouteServer) then
			local routeok, res =
				pcall(loadRoute, gotPath, "page" :: "page", request, 200)

			if not routeok then
				stdio.ewrite(`{res}\n`)
				return loadRoute(gotPath, "error", request, 500, tostring(res))
			end

			logReq(request, 200, startTime)
			if type(res) == "string" then
				-- otherwise headers are ignored or something idk
				return {
					status = 200,
					body = res,
				}
			end
			return res
		end

		logReq(request, 404, startTime)
		return loadRoute(gotPath, "error", request, 404, "Not Found")
	end
	return
end

--[=[
	Listens on the specified port.
]=]
function framework:listen(port: number)
	net.serve(port, function(request)
		local startTime = os.clock()
		local path = request.path
		-- Trim trailing slash
		if string.sub(path, -1) == "/" then
			path = string.sub(path, 1, -2)
		end

		if self._public then
			local res = servePublic(request, self._public, path, startTime)
			if res then
				return res
			end
		end

		if self._routes then
			local res = serveRoutes(request, self._routes, path, startTime)
			if res then
				return res
			end
		end

		logReq(request, 404, startTime)
		return {
			status = 404,
			body = "404 Not Found",
		}
	end)

	self:_log("green", `Listening on http://localhost:{port}/`)
end

local createFramework = {
	component = require "component",
	redirect = require "redirect",
	error = require "error",
	utils = require "utils",
}

--[=[
	Creates a new framework instance.
]=]
function createFramework:new(config: Config?)
	local this = framework
	this.config = config
	this:_log("blue", "Verbose mode enabled")
	return this
end

return createFramework
