local algos = require "algos"

--[=[
	Asserts if two tables are equal.
]=]
local function tableEqual<T>(a: { T }, b: { T }): boolean
	for i, v in a do
		if v ~= b[i] then
			return false
		end
	end
	return true
end

--[=[
	Randomises the order of an array.
]=]
local function randomise<T>(t: { T }): { T }
	local new = {}
	for i, v in t do
		table.insert(new, math.random(1, #new + 1), v)
	end
	return new
end

-- Test sorting
local array = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
local unsorted = randomise(array)

local sortingAlgos = {
	algos.bubbleSort,
	algos.insertionSort,
}

for _, sort in sortingAlgos do
	assert(tableEqual(sort(unsorted), array))
	assert(tableEqual(sort {}, {}))
end

-- Test sorting by
local sortedObjects: { { id: number } } = {}
for i = 1, 9 do
	table.insert(sortedObjects, { id = i })
end
local unsortedObjects = randomise(sortedObjects)

local sortingByAlgos = {
	algos.bubbleSortBy,
	algos.insertionSortBy,
}

for _, sort in sortingByAlgos do
	assert(tableEqual(sort(unsortedObjects, "id"), sortedObjects))
end

-- Test searching
for i, v in array do
	assert(algos.binarySearch(array, v) == i)
end

local duplicates = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5 }

for i, v in duplicates do
	assert(algos.binarySearch(duplicates, v) == -1)
end

assert(algos.binarySearch({}, 1) == -1)

print "All tests passed successfully!"
