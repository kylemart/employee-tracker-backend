db = require("lapis.db")
import types, create_table from require("lapis.db.schema")

{
	[1]: =>
		create_table("users", {
			{"id", types.serial unique: true}		-- serial id
			{"email", types.varchar unique: true}	-- unique email
			{"first_name", types.varchar}			-- first name
			{"last_name", types.varchar}			-- last name
			
			{"password_hash", types.varchar}		-- md5 digest of password+salt
			{"salt", types.varchar}					-- UUID generated at signup

			{"groups", types.integer array: true}	-- array of group ids user is a member of
			
			{"lat", types.double}					-- longitude
			{"lng", types.double}					-- latitude

			{"updated_at", types.time}				-- timestamp
			{"created_at", types.time}				-- timestamp

			"PRIMARY KEY (id)"
		})

		create_table("groups", {
			{"id", types.serial unique: true}		-- serial id
			{"name", types.varchar unique: true}	-- group name
			{"hidden", types.boolean}				-- hidden to users
			"PRIMARY KEY (id)"
		})

		db.insert("groups", {
			name: "Everyone"
			hidden: true
		})

		db.insert("groups", {
			name: "Administrators"
			hidden: true
		})

		-- misc groups

		db.insert("groups", {
			name: "Moving Squad"
		})

		db.insert("groups", {
			name: "Technicians"
		})

		db.insert("groups", {
			name: "Zookeepers"
		})
}