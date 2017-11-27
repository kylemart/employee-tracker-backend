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
import api, requireAuth, requireAdmin from require("filters")

isFile = (input) ->
	type input == "table"			and
	input.filename					and
	input.filename ~= ""			and
	input.content					and
	input.content ~= ""				and
	input["content-type"]			and
	input["content-type"] ~= ""


class EmployeeTracker extends lapis.Application
	@include("applications/users")
	@include("applications/groups")
	@include("applications/locations")

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

	[index: "/"]: api => APISuccess("Hello World!")

	-- PUBLIC API
	[login: "/login"]: api =>
		APIFailure("Missing email!") unless @params.email
		APIFailure("Missing password!") unless @params.password
		user = Users\find({email: @params.email})
		APIFailure("Invalid email!") unless user
		APIFailure("Invalid password!") unless crypto.digest("md5", @params.password .. user.salt) == user.password_hash
		token = user\generateToken!
		APIFailure("Failed to generate token!") unless token
		APISuccess token: token

	[signup: "/signup"]: api =>
		APIFailure("Missing email!") unless @params.email
		APIFailure("Invalid email!") unless @params.email\match("^[%w.]+@%w+%.%w+$")
		APIFailure("Missing password!") unless @params.password
		APIFailure("Email already in use!") if Users\find({email: @params.email})
		salt = uuid!
		user = Users\create({
			email: @params.email
			password_hash: crypto.digest("md5", @params.password .. salt)
			salt: salt
			first_name: @params.first_name or ""
			last_name: @params.last_name or ""
			groups: db.array {Groups.EVERYONE_ID}
		})
		token = user\generateToken!
		APIFailure("Failed to generate token!") unless token
		APISuccess({token: token})

	-- DEBUG API
	[debug: "/debug"]: api requireAuth =>
		APISuccess({
			user: @user.id
			users: Users\select("*")
			groups: Groups\select("*")
		})

	[grantAdmin: "/grant-admin"]: api requireAuth =>
		insertIfNotExistsIn(@user.groups, Groups.ADMIN_ID)
		@user\update("groups")
		APISuccess({user: @user})

	[imageTest: "/image-test"]: api requireAuth =>
		APIFailure("File missing!") unless @params.file
		APIFailure("File invalid!") unless isFile(@params.file)
		contentPrefix, contentSuffix = @params.file["content-type"]\match("^(.+)/(.+)$")
		APIFailure("File must be image!") unless contentPrefix == "image"
		APIFailure("Invalid image type!") unless existsIn(VALID_IMAGE_TYPES, contentSuffix)
		file = io.open("images/#{@params.file.filename}", "w")
		file\write(@params.file.content)
		file\close!
		APISuccess("Uploaded!")