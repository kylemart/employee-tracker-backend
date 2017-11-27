lapis = require("lapis")
db = require("lapis.db")

import APISuccess, APIFailure from require("utility")
import api, requireAuth, requireAdmin from require("filters")

Users = require("classes/Users")
Groups = require("classes/Groups")

class extends lapis.Application
	@path: "/group"

	[root: ""]: api =>
		APISuccess({result: Groups\select("* where hidden = false")})

	[group: "/:id"]: api =>
		APISuccess({result: Groups\find({id: @params.id})})

	[users: "/:id/users"]: api =>
		APISuccess({result: Users\select("* where groups @> ARRAY[?]", db.raw(@params.id))})