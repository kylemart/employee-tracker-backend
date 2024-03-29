lapis = require("lapis")
db = require("lapis.db")

import APISuccess, APIFailure from require("utility")
import api, auth, requireAdmin from require("filters")

Users = require("classes/Users")
Groups = require("classes/Groups")

class extends lapis.Application
	@path: "/group"

	[root: ""]: api =>
		APISuccess({result: Groups\select("* where hidden = false")})

	[group: "/:id"]: api =>
		APISuccess({result: Groups\find({id: @params.id})})

	[users: "/:id/users"]: api =>
		APISuccess({
			result: Users\select("* where groups @> ARRAY[?]", db.raw(@params.id), {fields: "id, email, first_name, last_name"})
		})

	[many: "/many"]: api =>
		APISuccess({
			result: Users\select("* where groups && ?", db.array(@params.ids), {fields: "id, email, first_name, last_name, lat, lng, profile_img"})
		})