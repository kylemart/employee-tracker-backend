config = require("lapis.config").get!
jwt = require("luajwt")

import existsIn from require("utility")

class Users extends require("lapis.db.model").Model
	-- methods
	isInGroupById: (id) => existsIn(@groups, id)
	generateToken: => jwt.encode({id: @id, time: os.time!}, config.secret)