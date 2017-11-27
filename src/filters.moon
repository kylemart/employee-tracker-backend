config = require("lapis.config").get!
jwt = require("luajwt")

import capture_errors from require("lapis.application")
import APIFailure from require("utility")

Users = require("classes/Users")

filters = {}

filters.api = (fn) -> capture_errors {
		on_error: => json: @errors[1]
		fn
	}

filters.requireAuth = (fn) -> (...) =>
	if token = @req.headers["Authorization"]
		if decoded = jwt.decode(token, config.secret)
			if decoded.id
				if user = Users\find({id: decoded.id})
					@user = user
					return fn(self, ...)
	APIFailure("Invalid token!")

filters.requireAdmin = (fn) -> (...) =>
	if @user and @user\isInGroupById(GROUP_ADMIN_ID)
		return fn(self, ...)
	APIFailure("Invalid permissions!")

return filters