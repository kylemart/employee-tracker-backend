db = require "lapis.db"
import types, create_table from require "lapis.db.schema"

{
	[1]: =>
		create_table "users", {
			{"id", types.serial unique: true} -- serial id
			{"email", types.varchar unique: true} -- unique username
			{"password_hash", types.varchar} -- md5 digest of password+salt
			{"salt", types.varchar} -- UUID generated at signup
			{"first_name", types.varchar}
			{"last_name", types.varchar}
			{"groups", types.integer array: true}
			"PRIMARY KEY (id)"
		}

		create_table "groups", {
			{"id", types.serial unique: true}
			{"name", types.varchar unique: true}
			{"hidden", types.boolean}
		}

		db.insert "groups", {
			-- id: 1
			name: "Everyone"
			hidden: true
		}

		db.insert "groups", {
			-- id: 2
			name: "Administrators"
			hidden: true
		}
}