lapis = require("lapis")
db = require("lapis.db")

import APISuccess, APIFailure from require("utility")
import api, auth, requireAdmin from require("filters")

Users = require("classes/Users")
Groups = require("classes/Groups")

class extends lapis.Application
	@path: "/user"

	[root: ""]: api =>
		APISuccess({result: Users\select("*", {fields: "id, email, first_name, last_name, groups"})})

	[me: "/me"]: api auth =>
		redirect_to: @url_for("user", id: @user.id)

	[user: "/:id"]: api =>
		user = Users\find({id: @params.id})
		APIFailure("No user found by that id!") unless user

		groups = {}
		for groupId in *user.groups
			group = Groups\find({id: groupId})
			if group and not group.hidden
				table.insert(groups, {
					id: groupId
					name: group.name
					size: Users\count("groups @> ARRAY[?]", db.raw(groupId))
				})

		table.sort(groups, (a, b) -> a.id < b.id)

		APISuccess({result: {
			id: user.id
			email: user.email
			first_name: user.first_name
			last_name: user.last_name
			groups: groups
		}})