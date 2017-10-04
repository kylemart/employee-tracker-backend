import types, create_table from require "lapis.db.schema"

{
	[1]: =>
		create_table("users", {
			{"id", types.serial} -- serial id
			{"username", types.varchar unique: true} -- unique username
			{"password_hash", types.varchar} -- md5 digest of password+salt
			{"salt", types.varchar} -- UUID generated at signup

			-- first name
			-- last name
			-- multiple groups

			"PRIMARY KEY (id)"
		})
}