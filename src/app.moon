package.path ..= ";./?/init.lua"

lapis = require("lapis")
db = require("lapis.db")

crypto = require("crypto")
uuid = require("uuid")
socket = require("socket")

uuid.seed!

Users = require("classes/Users")
Groups = require("classes/Groups")

VALID_IMAGE_TYPES = {"png", "jpg"}

import existsIn, insertIfNotExistsIn, APISuccess, APIFailure from require("utility")
import api, auth, admin from require("filters")

isFile = (input) ->
	type(input) == "table"			and
	input.filename					and
	input.filename ~= ""			and
	input.content					and
	input.content ~= ""				and
	input["content-type"]			and
	input["content-type"] ~= ""

assignGroup = (user, groupId) ->
	groupId = tonumber(groupId)
	insertIfNotExistsIn(user.groups, groupId)
	user\update("groups")
	return user

class EmployeeTracker extends lapis.Application
	@include("applications/users")
	@include("applications/groups")

	default_route: =>
		if @req.parsed_url.path\match("./$")
			return {
				redirect_to: @build_url(
					@req.parsed_url.path\match("^(.+)/+$"), {
						query: @req.parsed_url.query
					}
				)
				status: 301
			}
		else
			self.app.handle_404(self)

	handle_404: => {layout: false}, "Failed to find route: #{@req.cmd_url}"

	[index: "/"]: api =>
		APISuccess({
			users: Users\select("*")
			groups: Groups\select("*")
		})

	-- PUBLIC API
	[login: "/login"]: api =>
		APIFailure("Missing email!") unless @params.email
		APIFailure("Missing password!") unless @params.password
		user = Users\find({email: @params.email})
		APIFailure("Invalid email!") unless user
		APIFailure("Invalid password!") unless crypto.digest("md5", @params.password .. user.salt) == user.password_hash
		token = user\generateToken!
		APIFailure("Failed to generate token!") unless token
		APISuccess({
			id: user.id
			token: token
			isAdmin: user\isInGroupById(Groups.ADMIN_ID)
			email: user.email
			first_name: user.first_name
			last_name: user.last_name
		})

	[signup: "/signup"]: api =>
		APIFailure("Missing email!") unless @params.email
		APIFailure("Invalid email!") unless @params.email\match("^[%w.]+@%w+%.%w+$")
		APIFailure("Missing password!") unless @params.password
		APIFailure("Email already in use!") if Users\find({email: @params.email})
		salt = uuid!

		groups = {Groups.EVERYONE_ID}
		for group in *Groups\select("*")
			if math.random(2) == 1
				table.insert(groups, group.id)

		user = Users\create({
			email: @params.email
			password_hash: crypto.digest("md5", @params.password .. salt)
			salt: salt
			first_name: @params.first_name or ""
			last_name: @params.last_name or ""
			groups: db.array(groups)
			lat: 0
			lng: 0
		})
		token = user\generateToken!
		APIFailure("Failed to generate token!") unless token
		APISuccess({
			id: user.id
			token: token
			isAdmin: user\isInGroupById(Groups.ADMIN_ID)
			email: user.email
			first_name: user.first_name
			last_name: user.last_name
		})

	[report: "/report"]: api auth =>
		@user\update({
			lat: @params.lat
			lng: @params.lng
		})
		APISuccess({result: @user})

	-- TEST --

	[createGroup: "/create-group"]: api =>
		APISuccess({result: Groups\create({
			name: @params.name
		})})

	[assignGroup: "/assign-group"]: api => APISuccess({user: assignGroup(Users\find({id: @params.userId}), @params.groupId)})
	
	[clearGroup: "/clear-group"]: api =>
		user = Users\find({id: @params.userId})
		user\update({
			groups: db.array({Groups.EVERYONE_ID})
		})
		return APISuccess({user: user})

	[grantAdmin: "/grant-admin"]: api => APISuccess({user: assignGroup(Users\find({id: @params.id}), Groups.ADMIN_ID)})

	[imageTest: "/image-test"]: api auth =>
		APIFailure("File missing!") unless @params.file
		APIFailure("File invalid!") unless isFile(@params.file)
		contentPrefix, contentSuffix = @params.file["content-type"]\match("^(.+)/(.+)$")
		APIFailure("File must be image!") unless contentPrefix == "image"
		APIFailure("Invalid image type!") unless existsIn(VALID_IMAGE_TYPES, contentSuffix)
		file = io.open("images/#{@params.file.filename}", "w")
		file\write(@params.file.content)
		file\close!
		APISuccess("Uploaded!")