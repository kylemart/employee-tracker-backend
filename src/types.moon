db = require "lapis.db.postgres"

import escape_literal from db

class ColumnType
  default_options: { null: false }

  new: (@base, @default_options) =>

  __call: (opts) =>
    out = @base

    for k,v in pairs @default_options
      -- don't use the types default default since it's not an array
      continue if k == "default" and opts.array
      opts[k] = v unless opts[k] != nil

    if opts.array
      for i=1,type(opts.array) == "number" and opts.array or 1
        out ..= "[]"

    unless opts.null
      out ..= " NOT NULL"

    if opts.default != nil
      out ..= " DEFAULT " .. escape_literal opts.default

    if opts.unique
      out ..= " UNIQUE"

    if opts.primary_key
      out ..= " PRIMARY KEY"

    out

  __tostring: => @__call @default_options

C = ColumnType
types = setmetatable {
  bytea:        C "bytea"
}, __index: (key) =>
  error "Don't know column type `#{key}`"

return types
