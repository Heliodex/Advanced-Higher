return function (status: number, path: string)
	return {
		status = status,
		headers = {
			Location = path,
		},
	}
end
