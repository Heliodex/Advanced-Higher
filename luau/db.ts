import Database from "bun:sqlite"

const db = new Database("db.sqlite3", { create: true })

Bun.serve({
	port: 3307,
	async fetch(req) {
		if (req.method != "POST")
			return new Response("Method Not Allowed", { status: 405 })

		try {
			const block = await req.json(),
				params: any[] = block?.params,
				query = db.query(block.query),
				result = query.get(...(params || []))

				console.log(query.toString())

			return new Response(JSON.stringify(result), {
				headers: {
					"Content-Type": "application/json",
				},
			})
		} catch (e: any) {
			return new Response(e.message, { status: 400 })
		}
	},
})

console.log("serving")
