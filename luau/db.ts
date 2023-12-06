import { Client } from "https://deno.land/x/mysql@v2.12.1/mod.ts"

const client = await new Client().connect({
	hostname: "localhost",
	username: "root",
	password: "root",
})

// Because Lune can't access the database over only http

Deno.serve({ port: 3307 }, async req => {
	if (req.method != "POST")
		return new Response("Method not allowed", { status: 405 })

	const body = await req.json(),
		query: string = body.query,
		params: (number | string)[] | undefined = body?.params

	try {
		const result = await client.execute(query, params)

		return new Response(JSON.stringify(result, null, 2), {
			headers: { "content-type": "application/json" },
		})
	} catch (e) {
		return new Response(JSON.stringify({
			error: e.message,
		}), { status: 400 })
	}
})
