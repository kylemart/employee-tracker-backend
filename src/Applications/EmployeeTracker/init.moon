lapis = require "lapis"
config = require("lapis.config").get!

inspect = require "inspect"
crypto = require "crypto"
jwt = require "luajwt"
uuid = require "uuid"
socket = require "socket"

uuid.seed!

import Model from require "lapis.db.model"

VALID_IMAGE_TYPES = {"png", "jpg"}

class Users extends Model

local APISuccess, APIFailure

APIResult = (data, success) ->
	dataType = type data
	if dataType == "table"
		data.success = success
		return json: data
	elseif dataType == "string"
		return json:
			success: success
			message: data
	else
		APIFailure "Invalid result type of #{type data}"

APISuccess = (data) -> APIResult data, true
APIFailure = (data) -> APIResult data, false

encodeJWT = (data) -> jwt.encode data, config.secret

generateToken = (user) ->
	encodeJWT
		id: user.id
		time: os.time!

isFile = (input) ->
	type input == "table" and
	input.filename and
	input.filename != "" and
	input.content and
	input.content != "" and
	input["content-type"] and
	input["content-type"] != ""

requiresAuth = (fn) -> =>
	if token = @req.headers["Authorization"]
		if decoded = jwt.decode token, config.secret
			if decoded.id
				if user = Users\find id: decoded.id
					return fn self, user
	return APIFailure "Invalid token!"

existsIn = (arr, elem) ->
	for v in *arr
		return true if v == elem
	return false

class EmployeeTracker extends lapis.Application
	@path: "/EmployeeTracker"
	@name: "EmployeeTracker_"

	[index: ""]: => "root"
	[debug: "/debug"]: => json: Users\select!

	[test: "/test"]: requiresAuth (user) =>
		return APIFailure "File missing!" unless @params.file
		return APIFailure "File invalid!" unless isFile @params.file

		contentPrefix, contentSuffix = @params.file["content-type"]\match "^(.+)/(.+)$"
		return APIFailure "File must be image!" unless contentPrefix == "image"
		return APIFailure "Invalid image type!" unless existsIn VALID_IMAGE_TYPES, contentSuffix

		file = io.open "images/#{@params.file.filename}", "w"
		file\write @params.file.content
		file\close!

		APISuccess "Uploaded!"

	[images: "/images/:name"]: =>
		file = io.open "images/#{@params.name}", "rb"
		content = file\read "*all"
		file\close!
		return {content_type: "image/png"}, content


	[login: "/login"]: =>
		return APIFailure "Missing username!" unless @params.username
		return APIFailure "Missing password!" unless @params.password
		user = Users\find username: @params.username
		return APIFailure "Invalid username!" unless user
		return APIFailure "Invalid password!" unless crypto.digest("md5", @params.password .. user.salt) == user.password_hash
		token = generateToken user
		return APIFailure "Failed to generate token!" unless token
		APISuccess token: token

	[signup: "/signup"]: =>
		return APIFailure "Missing username!" unless @params.username
		return APIFailure "Missing password!" unless @params.password
		user = Users\find username: @params.username
		return APIFailure "Username already exists!" if user

		salt = uuid!
		user = Users\create
			username: @params.username
			password_hash: crypto.digest "md5", @params.password .. salt
			salt: salt

		token = generateToken user
		return APIFailure "Failed to generate token!" unless token
		APISuccess token: token

	[report: "/report"]: requiresAuth (user) =>

	[fetch: "/fetch"]: requiresAuth (user) =>