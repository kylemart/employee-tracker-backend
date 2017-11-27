lapis = require("lapis")

import APISuccess, APIFailure from require("utility")
import api, requireAuth, requireAdmin from require("filters")

Locations = require("classes/Locations")

class extends lapis.Application
	@path: "/location"

	[root: ""]: api => APISuccess({result: Locations\select("*")})

	[report: "/report"]: api requireAuth =>
		loc = Locations\find({id: @user.id})
		if loc
			loc\update({
				x: @params.x
				y: @params.y
			})
		else
			loc = Locations\create({
				id: @params.id
				x: @params.x
				y: @params.y
			})
		APISuccess({result: loc})

	[fetch: "/:id"]: api =>
		loc = Locations\find({id: @params.id})
		if loc
			APISuccess({result: loc})
		APIFailure("No location found for id!")