local config = require("lapis.config")
return config("production", {
  port = 80,
  num_workers = 4,
  code_cache = "off",
  secret = require("secret"),
  postgres = {
    host = "postgres-service",
    user = "postgres",
    password = "",
    database = ""
  }
})
