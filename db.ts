// This basic proxy only exists because the main application, written in Luau, doesn't have the capability to interact with MySQL.

import { Client } from "https://deno.land/x/mysql@v2.12.1/mod.ts"

const client = await new Client().connect({
	hostname: "localhost",
	username: "root",
	password: "root",
})
const headers = { "content-type": "application/json" }

Deno.serve({ port: 3307 }, async req => {
	try {
		const body = await req.json()
		const result = await client.execute(body.query, body?.params)

		return new Response(JSON.stringify(result), { headers })
	} catch (e) {
		return new Response(JSON.stringify({ error: e.message }), {
			status: 400,
			headers,
		})
	}
})
