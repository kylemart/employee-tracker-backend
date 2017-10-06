package.path ..= ";./?/init.lua"

lapis = require "lapis"
db = require "lapis.db"
config = require"lapis.config".get!

inspect = require "inspect"
crypto = require "crypto"
jwt = require "luajwt"
uuid = require "uuid"
socket = require "socket"

uuid.seed!

import capture_errors, yield_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import Model from require "lapis.db.model"

VALID_IMAGE_TYPES = {"png", "jpg"}

existsIn = (arr, elem) ->
	for v in *arr
		return true if v == elem
	return false

insertIfNotExistsIn = (arr, elem) ->
	unless existsIn arr, elem
		arr[#arr + 1] = elem

tobool = (input) ->
	if input == "true"
		return true
	elseif input == "false"
		return false
	else
		return nil

encodeJWT = (data) -> jwt.encode data, config.secret

class Users extends Model
	-- static methods
	getByEmail: (email) => @find email: email
	getById: (id) => @find id: id

	-- methods
	isInGroupById: (id) => existsIn @groups, id
	generateToken: =>
		encodeJWT
			id: @id
			time: os.time!

class Groups extends Model
	getById: (id) => @find id: id
	getByName: (name) => @find name: name

GROUP_EVERYONE_ID = 1
GROUP_ADMIN_ID = 2

api = (fn) ->
	return capture_errors {
		on_error: => json: @errors[1]
		fn
	}

local APISuccess, APIFailure

APIResult = (data, success) ->
	dataType = type data
	if dataType == "table"
		data.success = success
		yield_error data
	elseif dataType == "string"
		bin =
			success: success
			message: data
		yield_error bin
	else
		APIFailure "Invalid result type of #{type data}"

APISuccess = (data) -> APIResult data, true
APIFailure = (data) -> APIResult data, false

isFile = (input) ->
	type input == "table"			and
	input.filename					and
	input.filename != ""			and
	input.content					and
	input.content != ""				and
	input["content-type"]			and
	input["content-type"] != ""

requireAuth = (fn) -> (...) =>
	if token = @req.headers["Authorization"]
		if decoded = jwt.decode token, config.secret
			if decoded.id
				if user = Users\getById decoded.id
					@user = user
					return fn(self, ...)
	APIFailure "Invalid token!"

requireAdmin = (fn) -> (...) =>
	if @user and @user\isInGroupById GROUP_ADMIN_ID
		return fn(self, ...)
	APIFailure "Invalid permissions!"


class EmployeeTracker extends lapis.Application
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

	[index: "/"]: api => APISuccess "Hello World"

	-- PUBLIC API
	[login: "/login"]: api =>
		APIFailure "Missing email!" unless @params.email
		APIFailure "Missing password!" unless @params.password
		user = Users\getByEmail @params.email
		APIFailure "Invalid email!" unless user
		APIFailure "Invalid password!" unless crypto.digest("md5", @params.password .. user.salt) == user.password_hash
		token = user\generateToken!
		APIFailure "Failed to generate token!" unless token
		APISuccess token: token

	[signup: "/signup"]: api =>
		APIFailure "Missing email!" unless @params.email
		APIFailure "Invalid email!" unless @params.email\match "^[%w.]+@%w+%.%w+$"
		APIFailure "Missing password!" unless @params.password
		user = Users\getByEmail @params.email
		APIFailure "Email already in use!" if user
		salt = uuid!
		user = Users\create
			email: @params.email
			password_hash: crypto.digest "md5", @params.password .. salt
			salt: salt
			first_name: ""
			last_name: ""
			groups: db.array {GROUP_EVERYONE_ID}
		token = user\generateToken!
		APIFailure "Failed to generate token!" unless token
		APISuccess token: token

	[groups: "/groups"]: api requireAuth =>
		result = Groups\select "*"
		for i = #result, 1, -1 do
			if result[i].hidden
				table.remove result, i
		APISuccess result: result

	[groupsCreate: "/groups/create"]: api requireAuth requireAdmin =>
		APIFailure "Missing name!" unless @params.name
		group = Groups\getByName @params.name
		APIFailure "Group already exists!" if group
		group = Groups\create
			name: @params.name
		APISuccess
			result: group

	[groupsAssign: "/groups/assign"]: api requireAuth requireAdmin =>
		APIFailure "Missing userId!" unless @params.userId
		APIFailure "Missing groupId!" unless @params.groupId
		user = Users\getById @params.userId
		APIFailure "Invalid userId!" unless user
		group = Groups\getById @params.groupId
		APIFailure "Invalid groupId!" unless group
		insertIfNotExistsIn user.groups @params.groupId
		user\update "groups"
		APISuccess!

	-- DEBUG API
	[debug: "/debug"]: api requireAuth =>
		APISuccess
			user: @user
			users: Users\select "*"
			groups: Groups\select "*"

	[grantAdmin: "/grant-admin"]: api requireAuth =>
		insertIfNotExistsIn @user.groups, GROUP_ADMIN_ID
		@user\update "groups"
		APISuccess
			user: @user

	[imageTest: "/image-test"]: api requireAuth =>
		APIFailure "File missing!" unless @params.file
		APIFailure "File invalid!" unless isFile @params.file
		contentPrefix, contentSuffix = @params.file["content-type"]\match "^(.+)/(.+)$"
		APIFailure "File must be image!" unless contentPrefix == "image"
		APIFailure "Invalid image type!" unless existsIn VALID_IMAGE_TYPES, contentSuffix
		file = io.open "images/#{@params.file.filename}", "w"
		file\write @params.file.content
		file\close!
		APISuccess "Uploaded!"