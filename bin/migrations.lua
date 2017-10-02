local types, create_table
do
  local _obj_0 = require("lapis.db.schema")
  types, create_table = _obj_0.types, _obj_0.create_table
end
return {
  [1] = function(self)
    return create_table("users", {
      {
        "id",
        types.serial
      },
      {
        "username",
        types.varchar({
          unique = true
        })
      },
      {
        "password_hash",
        types.varchar
      },
      {
        "salt",
        types.varchar
      },
      "PRIMARY KEY (id)"
    })
  end
}
