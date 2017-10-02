local lapis = require("lapis")
local config = require("lapis.config").get()
local inspect = require("inspect")
local crypto = require("crypto")
local jwt = require("luajwt")
local uuid = require("uuid")
local socket = require("socket")
uuid.seed()
local Model
Model = require("lapis.db.model").Model
local VALID_IMAGE_TYPES = {
  "png",
  "jpg"
}
local Users
do
  local _class_0
  local _parent_0 = Model
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Users",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Users = _class_0
end
local APISuccess, APIFailure
local APIResult
APIResult = function(data, success)
  local dataType = type(data)
  if dataType == "table" then
    data.success = success
    return {
      json = data
    }
  elseif dataType == "string" then
    return {
      json = {
        success = success,
        message = data
      }
    }
  else
    return APIFailure("Invalid result type of " .. tostring(type(data)))
  end
end
APISuccess = function(data)
  return APIResult(data, true)
end
APIFailure = function(data)
  return APIResult(data, false)
end
local generateToken
generateToken = function(user)
  return jwt.encode({
    id = user.id,
    time = os.time()
  }, config.secret)
end
local isFile
isFile = function(input)
  return type(input == "table") and input.filename and input.filename ~= "" and input.content and input.content ~= "" and input["content-type"] and input["content-type"] ~= ""
end
local requiresAuth
requiresAuth = function(fn)
  return function(self)
    do
      local token = self.req.headers["Authorization"]
      if token then
        do
          local decoded = jwt.decode(token, config.secret)
          if decoded then
            if decoded.id then
              do
                local user = Users:find({
                  id = decoded.id
                })
                if user then
                  return fn(self, user)
                end
              end
            end
          end
        end
      end
    end
    return APIFailure("Invalid token!")
  end
end
local existsIn
existsIn = function(arr, elem)
  for _index_0 = 1, #arr do
    local v = arr[_index_0]
    if v == elem then
      return true
    end
  end
  return false
end
local EmployeeTracker
do
  local _class_0
  local _parent_0 = lapis.Application
  local _base_0 = {
    [{
      index = ""
    }] = function(self)
      return "root"
    end,
    [{
      debug = "/debug"
    }] = function(self)
      return {
        json = Users:select()
      }
    end,
    [{
      test = "/test"
    }] = requiresAuth(function(self, user)
      if not (self.params.file) then
        return APIFailure("File missing!")
      end
      if not (isFile(self.params.file)) then
        return APIFailure("File invalid!")
      end
      local contentPrefix, contentSuffix = self.params.file["content-type"]:match("^(.+)/(.+)$")
      if not (contentPrefix == "image") then
        return APIFailure("File must be image!")
      end
      if not (existsIn(VALID_IMAGE_TYPES, contentSuffix)) then
        return APIFailure("Invalid image type!")
      end
      local file = io.open("images/" .. tostring(self.params.file.filename), "w")
      file:write(self.params.file.content)
      file:close()
      return APISuccess("Uploaded!")
    end),
    [{
      images = "/images/:name"
    }] = function(self)
      local file = io.open("images/" .. tostring(self.params.name), "rb")
      local content = file:read("*all")
      file:close()
      return {
        content_type = "image/png"
      }, content
    end,
    [{
      login = "/login"
    }] = function(self)
      if not (self.params.username) then
        return APIFailure("Missing username!")
      end
      if not (self.params.password) then
        return APIFailure("Missing password!")
      end
      local user = Users:find({
        username = self.params.username
      })
      if not (user) then
        return APIFailure("Invalid username!")
      end
      if not (crypto.digest("md5", self.params.password .. user.salt) == user.password_hash) then
        return APIFailure("Invalid password!")
      end
      local token = generateToken(user)
      if not (token) then
        return APIFailure("Failed to generate token!")
      end
      return APISuccess({
        token = token
      })
    end,
    [{
      signup = "/signup"
    }] = function(self)
      if not (self.params.username) then
        return APIFailure("Missing username!")
      end
      if not (self.params.password) then
        return APIFailure("Missing password!")
      end
      local user = Users:find({
        username = self.params.username
      })
      if user then
        return APIFailure("Username already exists!")
      end
      local salt = uuid()
      user = Users:create({
        username = self.params.username,
        password_hash = crypto.digest("md5", self.params.password .. salt),
        salt = salt
      })
      local token = generateToken(user)
      if not (token) then
        return APIFailure("Failed to generate token!")
      end
      return APISuccess({
        token = token
      })
    end,
    [{
      report = "/report"
    }] = requiresAuth(function(self, user) end),
    [{
      fetch = "/fetch"
    }] = requiresAuth(function(self, user) end)
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "EmployeeTracker",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.path = "/EmployeeTracker"
  self.name = "EmployeeTracker_"
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  EmployeeTracker = _class_0
  return _class_0
end
