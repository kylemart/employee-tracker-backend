config = require "lapis.config"

config {"development", "production"},
	port: 80
	num_workers: 4
	secret: require "secret"
	postgres:
		host: "postgres-service"
		user: "postgres"
		password: ""
		database: ""

config "development",
	code_cache: "off"

config "production",
	code_cache: "on"