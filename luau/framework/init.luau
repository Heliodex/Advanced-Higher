local fs = require "@lune/fs"
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

local function logReq(request: net.ServeRequest, status: number, time: number)
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

local function createFile(path, contents)
	-- create each directory in the path if it doesn't exist
	local currentPath = ""
	for dir in string.gmatch(path, "[^/]+") do
		-- don't create the last part of the path
		if dir == string.match(path, "^.*/([^/]*)$") then
			break
		end
		currentPath ..= `{dir}/`
		if not fs.isDir(currentPath) then
			fs.writeDir(currentPath)
		end
	end

	fs.writeFile(`{path}.luau`, contents)
end

export type Data = { [string]: any }

local function loadRoute(
	path: string,
	filetype: string, -- "page" | "error" fux up the pcall
	request: net.ServeRequest,
	status: number,
	err: string?
): net.ServeResponse | string
	local filename = `{path}/+page`
	local load: Data
	local method = request.method

	if filetype == "+page" then
		local ok, pageServer: {
			load: ((
				self: any,
				request: net.ServeRequest,
				status: number,
				err: string?
			) -> Data)?,
			actions: {
				[string]: (
					request: net.ServeRequest
				) -> net.ServeResponse | string,
			}?,
		} =
			pcall(require, filename)

		if method == "GET" then
			load = if ok and pageServer.load
				-- method call (:) fux up
				then pageServer.load(pageServer, request, status, err)
				else {}

			if load._raw == true then
				load._raw = nil
				return load
			end
		elseif method == "POST" and ok and pageServer.actions then
			local action = request.query[""] or "default"
			local actionFunc = pageServer.actions[action]

			print("calling action", action)

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

	-- compile and add +page.ltmp file
	local pageFilename = `{path}/{filetype}.ltmp`
	local ok, isPageFile = pcall(fs.isFile, pageFilename)

	if not ok then
		error(isPageFile)
	end

	local compiledPath = `.compiled{path}/{filetype}`
	local layoutPath = path

	-- bubble up the directory tree, adding +layout.luau files
	while true do
		local ok2, layoutServer: {
			load: ((
				self: any,
				request: net.ServeRequest,
				status: number,
				err: string?
			) -> Data)?,
		} =
			pcall(require, `{layoutPath}/+layout`)

		if ok2 and layoutServer.load then
			local layoutLoad =
				layoutServer.load(layoutServer, request, status, err)

			if layoutLoad._raw == true then
				layoutLoad._raw = nil
				return layoutLoad
			end

			-- merge the layout's load with the existing load
			-- existing load (further down the tree) takes priority
			load = utils.merge(layoutLoad, load)
		end

		layoutPath = string.match(layoutPath, "^(.*)/[^/]*$")
		if not layoutPath then
			break
		end
	end

	-- compile the layout template
	local templated
	local readok, pageFile = pcall(fs.readFile, pageFilename)

	if not readok then
		-- bubble up the directory tree, looking for an error template
		while true do
			print("compiling error template", path)
			local compiledErrorPath = compile(path, "+error")

			if compiledErrorPath then
				local ok2, layout: (args: Data, SLOT: string) -> string =
					pcall(require, compiledErrorPath)

				if not ok2 then
					error(layout) -- yes, this is needed
				end

				templated = layout(load, "body")
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
		local pageok, page: (args: Data) -> string
		local templateok, compiled = pcall(template, pageFile)

		if templateok then
			createFile(compiledPath, compiled)

			pageok, page = pcall(require, compiledPath)
		end

		if not pageok then
			if filetype == "+error" then
				load = {
					status = status,
					error = err,
				}
			else
				templated = `{status} {err}`
			end
		else
			templated = page(load)
		end
	end

	-- bubble up the directory tree, adding layout files
	while true do
		local compiledLayoutPath = compile(path, "+layout")

		if compiledLayoutPath then
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

	return {
		status = status,
		body = templated,
	}
end

local function getRoutePath(path: string)
	-- check if "routes/testing/beu/+page.ltmp" exists,
	-- but also check if "routes/(layout)/testing/beu" exists
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
			-- no layouts found, path aint there
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

--[=[
	Listens on the specified port.
]=]
function framework:listen(port: number)
	self:_log("green", `Listening on http://localhost:{port}/`)

	net.serve(port, function(request)
		local startTime = os.clock()
		local path = request.path
		-- Trim trailing slash
		if string.sub(path, -1) == "/" then
			path = string.sub(path, 1, -2)
		end

		if self._public then
			local filename = self._public .. path
			local ok, readFile = pcall(fs.readFile, filename)
			if ok then
				logReq(request, 200, startTime)
				return {
					status = 200,
					body = readFile,
				}
			end
		end

		if self._routes then
			local basePath = self._routes .. path
			local gotPath = getRoutePath(basePath)
			gotPath = gotPath or basePath

			local routePageFilename = `{gotPath}/+page.ltmp`
			local routeServerFilename = `{gotPath}/+page.luau`

			local pageOk, isRoutePage = pcall(fs.isFile, routePageFilename)
			local serverOk, isRouteServer =
				pcall(fs.isFile, routeServerFilename)
			if (pageOk and isRoutePage) or (serverOk and isRouteServer) then
				local routeok, res =
					pcall(loadRoute, gotPath, "+page", request, 200)

				if not routeok then
					warn(res)
					return loadRoute(
						gotPath,
						"+error",
						request,
						500,
						tostring(res)
					)
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

		logReq(request, 404, startTime)
		return {
			status = 404,
			body = "404 Not Found",
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
