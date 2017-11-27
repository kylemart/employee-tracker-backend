lapis = require("lapis")

import APISuccess, APIFailure from require("utility")
import api, requireAuth, requireAdmin from require("filters")

Users = require("classes/Users")

class extends lapis.Application
	@path: "/user"

	[root: ""]: api =>
		APISuccess({result: Users\select("*", {fields: "id, email, first_name, last_name"})})

	[user: "/:id"]: api =>
		user = Users\find({id: @params.id})
		-- sanitize data
		APISuccess({result: {
			id: user.id
			email: user.email
			first_name: user.first_name
			last_name: user.last_name
		}})