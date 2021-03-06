-- table-utils.lua: tests for small table utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

dofile('lua-nucleo/strict.lua')
dofile('lua-nucleo/import.lua')

local make_suite = select(1, ...)
assert(type(make_suite) == "function")

local ensure,
      ensure_equals,
      ensure_tequals,
      ensure_tdeepequals,
      ensure_fails_with_substring
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_tequals',
        'ensure_tdeepequals',
        'ensure_fails_with_substring'
      }

local assert_is_table
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_table'
      }

local arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments'
      }

local empty_table,
      toverride_many,
      tappend_many,
      tijoin_many,
      tkeys,
      tvalues,
      tkeysvalues,
      tflip,
      tiflip,
      tset,
      tiset,
      tiinsert_args,
      timap_inplace,
      timap,
      timap_sliding,
      tiwalk,
      tiwalker,
      tequals,
      tiunique,
      tgenerate_n,
      taccumulate,
      tnormalize,
      tnormalize_inplace,
      tclone,
      tcount_elements,
      tremap_to_array,
      table_utils_exports
      = import 'lua-nucleo/table-utils.lua'
      {
        'empty_table',
        'toverride_many',
        'tappend_many',
        'tijoin_many',
        'tkeys',
        'tvalues',
        'tkeysvalues',
        'tflip',
        'tiflip',
        'tset',
        'tiset',
        'tiinsert_args',
        'timap_inplace',
        'timap',
        'timap_sliding',
        'tiwalk',
        'tiwalker',
        'tequals',
        'tiunique',
        'tgenerate_n',
        'taccumulate',
        'tnormalize',
        'tnormalize_inplace',
        'tclone',
        'tcount_elements',
        'tremap_to_array'
      }

--------------------------------------------------------------------------------

local test = make_suite("table-utils", table_utils_exports)

--------------------------------------------------------------------------------

test:test_for "empty_table" (function()
  ensure_equals("is table", type(empty_table), "table")
  ensure_equals("is empty", next(empty_table), nil)
  ensure_equals(
      "metatable is protected",
      getmetatable(empty_table),
      "empty_table"
    )
  ensure_equals("allows read access", empty_table[42], nil)

  ensure_fails_with_substring(
      "disallows write access",
      function()
        empty_table[42] = true
      end,
      "attempted to change the empty table"
    )
  ensure_equals("still empty", next(empty_table), nil)
end)

--------------------------------------------------------------------------------

test:group "toverride_many"

--------------------------------------------------------------------------------

test "toverride_many-noargs-empty" (function()
  ensure_tequals("noargs-empty", toverride_many({ }), { })
end)

test "toverride_many-noargs" (function()
  ensure_tequals("noargs", toverride_many({ 42 }), { 42 })
end)

test "toverride_many-single" (function()
  ensure_tequals("single", toverride_many({ 3.14 }, { 42 }), { 42 })
end)

test "toverride_many-empty-append" (function()
  ensure_tequals("single", toverride_many({ }, { 42 }), { 42 })
end)

test "toverride_many-single-append" (function()
  ensure_tequals(
      "single append",
      toverride_many({ 2.71 }, { [2] = 42 }),
      { 2.71, 42 }
    )
end)

test "toverride_many-returns-first-argument" (function()
  local t = { 2.71 }
  local r = toverride_many(t, { [2] = 42 })
  ensure_tequals(
      "single append",
      r,
      { 2.71, 42 }
    )
  ensure_equals("returned first argument", r, t)
end)

test "toverride_many-double-append" (function()
  ensure_tequals(
      "double append",
      toverride_many({ 2.71 }, { [2] = 42 }, { ["a"] = true }),
      { 2.71, 42, ["a"] = true }
    )
end)

test "toverride_many-hole" (function()
  ensure_tequals(
      "hole stops",
      toverride_many({ 2.71 }, { [2] = 42 }, nil, { ["a"] = true }),
      { 2.71, 42 }
    )
end)

test "toverride_many-on-self" (function()
  local v = { }
  local t = { v }
  ensure_tequals(
      "self-override is no-op",
      toverride_many(t, t, t, t, t),
      t
    )
  ensure_equals("exactly the same", t[1], v)
  t[1] = nil
  ensure_equals("no extra data", next(t), nil)
end)

test "toverride_many-recursion" (function()
  local t = { }
  t[t] = t
  ensure_tequals(
      "recursion",
      toverride_many(t, t, { t }),
      t
    )

  ensure_equals("old value is there", t[t], t)
  ensure_equals("and new one appeared", t[1] , t)

  t[t], t[1] = nil, nil
  ensure_equals("no extra data", next(t), nil)
end)

test "toverride_many-many" (function()
  local k = { }
  local t = { [1] = 42, ["a"] = k, [k] = false }
  local r = toverride_many(
      t,
      { },
      { 1 },
      t,
      { false, ["z"] = 2.71 },
      { [k] = k, [1] = 2.71 },
      t,
      nil,
      { 0 }
    )

  ensure_equals("returns first argument", r, t)
  ensure_tequals(
      "many",
      r,
      { [1] = 2.71, ["a"] = k, [k] = k, ["z"] = 2.71 }
    )
end)

--------------------------------------------------------------------------------

test:group "tappend_many"

--------------------------------------------------------------------------------

test "tappend_many-noargs-empty" (function()
  ensure_tequals("noargs-empty", tappend_many({ }), { })
end)

test "tappend_many-noargs" (function()
  ensure_tequals("noargs", tappend_many({ 42 }), { 42 })
end)

test "tappend_many-single" (function()
  ensure_fails_with_substring(
      "single override fails",
      function() tappend_many({ 3.14 }, { 42 }) end,
      "attempted to override table key `1'"
    )
end)

test "tappend_many-empty-append" (function()
  ensure_tequals("single", tappend_many({ }, { 42 }), { 42 })
end)

test "tappend_many-single-append" (function()
  ensure_tequals(
      "single append",
      tappend_many({ 2.71 }, { [2] = 42 }),
      { 2.71, 42 }
    )
end)

test "tappend_many-returns-first-argument" (function()
  local t = { 2.71 }
  local r = tappend_many(t, { [2] = 42 })
  ensure_tequals(
      "single append",
      r,
      { 2.71, 42 }
    )
  ensure_equals("returned first argument", r, t)
end)

test "tappend_many-double-append" (function()
  ensure_tequals(
      "double append",
      tappend_many({ 2.71 }, { [2] = 42 }, { ["a"] = true }),
      { 2.71, 42, ["a"] = true }
    )
end)

test "tappend_many-hole" (function()
  ensure_tequals(
      "hole stops",
      tappend_many({ 2.71 }, { [2] = 42 }, nil, { 0 }),
      { 2.71, 42 }
    )
end)

test "tappend_many-on-self" (function()
  local v = { }
  local t = { v }
  ensure_fails_with_substring(
      "self override fails",
      function() tappend_many(t, t) end,
      "attempted to override table key `1'"
    )
end)

test "tappend_many-recursion" (function()
  local t = { }
  t[t] = t
  ensure_tequals(
      "recursion",
      tappend_many(t, { t }),
      t
    )

  ensure_equals("old value is there", t[t], t)
  ensure_equals("and new one appeared", t[1] , t)

  t[t], t[1] = nil, nil
  ensure_equals("no extra data", next(t), nil)
end)

test "tappend_many-many" (function()
  local k = { }
  local t = { [1] = 42, ["a"] = k, [k] = false }
  local r = tappend_many(
      t,
      { },
      { [2] = 1, ["z"] = 2.71 },
      nil,
      t
    )

  ensure_equals("returns first argument", r, t)
  ensure_tequals(
      "many",
      r,
      { [1] = 42, [2] = 1, ["a"] = k, [k] = false, ["z"] = 2.71 }
    )
end)

--------------------------------------------------------------------------------

test:group "tijoin_many"

--------------------------------------------------------------------------------

test "tijoin_many-noargs-empty" (function()
  ensure_tequals("noargs-empty", tijoin_many({ }), { })
end)

test "tijoin_many-noargs" (function()
  ensure_tequals("noargs", tijoin_many({ 42 }), { 42 })
end)

test "tijoin_many-single" (function()
  ensure_tequals("single", tijoin_many({ 3.14 }, { 42 } ), { 3.14, 42 })
end)

test "tijoin_many-empty-append" (function()
  ensure_tequals("single", tijoin_many({ }, { 42 }), { 42 })
end)

test "tijoin_many-ignores-hash-part" (function()
  ensure_tequals(
      "single ignores hash part",
      tijoin_many({ 2.71 }, { a = 42 }),
      { 2.71 }
    )
end)

test "tijoin_many-returns-first-argument" (function()
  local t = { 2.71 }
  local r = tijoin_many(t, { 42 })
  ensure_tequals(
      "single append",
      r,
      { 2.71, 42 }
    )
  ensure_equals("returned first argument", r, t)
end)

test "tijoin_many-double-append" (function()
  ensure_tequals(
      "double append",
      tijoin_many({ 2.71 }, { 42 }, { true }),
      { 2.71, 42, true }
    )
end)

test "tijoin_many-hole" (function()
  ensure_tequals(
      "hole stops",
      tijoin_many({ 2.71 }, { 42 }, nil, { 0 }),
      { 2.71, 42 }
    )
end)

test "tijoin_many-on-self" (function()
  local t = { 3.14, 2.71 }
  ensure_tequals(
      "self-join duplicates",
      tijoin_many(t, t, t),
      { 3.14, 2.71, 3.14, 2.71, 3.14, 2.71, 3.14, 2.71 }
    )
end)

test "tijoin_many-recursion" (function()
  local t = { }
  t[1] = t
  ensure_tequals(
      "recursion",
      tijoin_many(t, { t }),
      t
    )

  ensure_equals("old value is there", t[1], t)
  ensure_equals("and new one appeared", t[2] , t)

  t[1], t[2] = nil, nil
  ensure_equals("no extra data", next(t), nil)
end)

--------------------------------------------------------------------------------

test:group "tkeys"

--------------------------------------------------------------------------------

test "tkeys-empty" (function()
  ensure_tequals("empty", tkeys({ }), { })
end)

test "tkeys-single" (function()
  ensure_tequals("simple", tkeys({ [1] = 42 }), { 1 })
end)

test "tkeys-hole" (function()
  ensure_tequals("hole", tkeys({ [42] = 1 }), { 42 })
end)

test "tkeys-hash" (function()
  ensure_tequals("hash", tkeys({ ["a"] = 42 }), { "a" })
end)

test "tkeys-table" (function()
  local k = { }
  ensure_tequals("table", tkeys({ [k] = 42 }), { k })
end)

test "tkeys-recursive" (function()
  local t = { }
  t[t] = t
  ensure_tequals("recursive", tkeys(t), { t })
end)

test "tkeys-many" (function()
  -- NOTE: Can't use tequals() directly
  --       due to undetermined table traversal order.

  local k = { }
  local t = { [1] = 42, a = k, [k] = false }
  local keys = tkeys(t)

  -- Check needed in case there would be duplicate entries in the result.
  ensure_equals("three keys", #keys, 3)

  ensure_tequals("check key sets", tiset(keys), tiset { 1, "a", k })
end)

--------------------------------------------------------------------------------

test:group "tvalues"

--------------------------------------------------------------------------------

test "tvalues-empty" (function()
  ensure_tequals("empty", tvalues({ }), { })
end)

test "tvalues-single" (function()
  ensure_tequals("simple", tvalues({ [1] = 42 }), { 42 })
end)

test "tvalues-hole" (function()
  ensure_tequals("hole", tvalues({ [42] = 1 }), { 1 })
end)

test "tvalues-hash" (function()
  ensure_tequals("hash", tvalues({ ["a"] = 42 }), { 42 })
end)

test "tvalues-table" (function()
  local k = { }
  ensure_tequals("table", tvalues({ [42] = k }), { k })
end)

test "tvalues-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tvalues(t), { t })
end)

test "tvalues-many" (function()
  -- NOTE: Can't use tequals() directly
  --       due to undetermined table traversal order.

  local k = { }
  local t = { [1] = 42, a = k, [k] = false }
  local values = tvalues(t)

  -- Check needed in case there would be duplicate entries in the result.
  ensure_equals("three values", #values, 3)

  ensure_tequals("check value sets", tiset(values), tiset { 42, k, false })
end)

--------------------------------------------------------------------------------

test:group "tkeysvalues"

--------------------------------------------------------------------------------

test "tkeysvalues-empty" (function()
  local keys, values = tkeysvalues({ })
  ensure_tequals("keys empty", keys, { })
  ensure_tequals("values empty", values, { })
end)

test "tkeysvalues-single" (function()
  local keys, values = tkeysvalues({ [1] = 42 })
  ensure_tequals("keys simple", keys, { 1 })
  ensure_tequals("values simple", values, { 42 })
end)

test "tkeysvalues-hole" (function()
  local keys, values = tkeysvalues({ [42] = 1 })
  ensure_tequals("keys hole", keys, { 42 })
  ensure_tequals("values hole", values, { 1 })
end)

test "tkeysvalues-hash" (function()
  local keys, values = tkeysvalues({ ["a"] = 42 })
  ensure_tequals("keys hash", keys, { "a" })
  ensure_tequals("values hash", values, { 42 })
end)

test "tkeysvalues-table" (function()
  local k = { }
  local keys, values = tkeysvalues({ [42] = k })
  ensure_tequals("keys table", keys, { 42 })
  ensure_tequals("values table", values, { k })
end)

test "tkeysvalues-recursive" (function()
  local t = { }
  t[1] = t
  local keys, values = tkeysvalues(t)
  ensure_tequals("keys recursive", keys, { 1 })
  ensure_tequals("values recursive", values, { t })
end)

test "tkeysvalues-many" (function()
  -- NOTE: Can't use tequals() directly
  --       due to undetermined table traversal order.

  local k = { }
  local t = { [1] = 42, a = k, [k] = false }

  local keys, values = tkeysvalues(t)

  -- Check needed in case there would be duplicate entries in the result.
  ensure_equals("three keys", #keys, 3)
  ensure_equals("three values", #values, 3)

  ensure_tequals("check key sets", tiset(keys), tiset { 1, "a", k })
  ensure_tequals("check value sets", tiset(values), tiset { 42, k, false })
end)

--------------------------------------------------------------------------------

test:group "tflip"

--------------------------------------------------------------------------------

test "tflip-empty" (function()
  ensure_tequals("empty", tflip({ }), { })
end)

test "tflip-single" (function()
  ensure_tequals("simple", tflip({ [1] = 42 }), { [42] = 1 })
end)

test "tflip-hole" (function()
  ensure_tequals("hole", tflip({ [42] = 1 }), { [1] = 42 })
end)

test "tflip-hash" (function()
  ensure_tequals("hash", tflip({ ["a"] = 42 }), { [42] = "a" })
end)

test "tflip-duplicate" (function()
  local t = tflip({ [1] = 42, [2] = 42 })
  ensure(
      "duplicate",
      tequals(t, { [42] = 1 }) or tequals(t, { [42] = 2 })
    )
end)

test "tflip-duplicate-hash" (function()
  local t = tflip({ [1] = 42, ["a"] = 42 })
  ensure(
      "duplicate hash",
      tequals(t, { [42] = 1 }) or tequals(t, { [42] = "a" })
    )
end)

test "tflip-table" (function()
  local k = { }
  ensure_tequals("table", tflip({ [k] = 42 }), { [42] = k })
end)

test "tflip-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tflip(t), { [t] = 1 })
end)

test "tflip-many" (function()
  local k = { }
  local t = { [1] = 42, a = k, [k] = false }

  ensure_tequals(
      "many",
      tflip(t),
      { [42] = 1, [k] = "a", [false] = k }
    )
end)

--------------------------------------------------------------------------------

test:group "tiflip"

--------------------------------------------------------------------------------

test "tiflip-empty" (function()
  ensure_tequals("empty", tiflip({ }), { })
end)

test "tiflip-single" (function()
  ensure_tequals("simple", tiflip({ [1] = 42 }), { [42] = 1 })
end)

test "tiflip-hole" (function()
  ensure_tequals("hole ignored", tiflip({ [42] = 1 }), { })
end)

test "tiflip-hash" (function()
  ensure_tequals("hash ignored", tiflip({ ["a"] = 42 }), { })
end)

test "tiflip-duplicate" (function()
  ensure_tequals("duplicate", tiflip({ [1] = 42, [2] = 42 }), { [42] = 2 })
end)

test "tiflip-duplicate-hash" (function()
  ensure_tequals(
      "duplicate hash ignored",
      tiflip({ [1] = 42, ["a"] = 42 }),
      { [42] = 1 }
    )
end)

test "tiflip-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tiflip(t), { [t] = 1 })
end)

test "tiflip-many" (function()
  local k = { }
  local t = { [1] = 42, [2] = 42, a = k, [k] = 42 }

   ensure_tequals("many", tiflip(t), { [42] = 2 })
end)

--------------------------------------------------------------------------------

test:group "tset"

--------------------------------------------------------------------------------

test "tset-empty" (function()
  ensure_tequals("empty", tset({ }), { })
end)

test "tset-single" (function()
  ensure_tequals("simple", tset({ [1] = 42 }), { [42] = true })
end)

test "tset-hole" (function()
  ensure_tequals("hole", tset({ [42] = 1 }), { [1] = true })
end)

test "tset-hash" (function()
  ensure_tequals("hash", tset({ ["a"] = 42 }), { [42] = true })
end)

test "tset-duplicate" (function()
  ensure_tequals("duplicate", tset({ [1] = 42, [2] = 42 }), { [42] = true })
end)

test "tset-duplicate-hash" (function()
  ensure_tequals(
      "duplicate hash",
      tset({ [1] = 42, ["a"] = 42 }),
      { [42] = true }
    )
end)

test "tset-table" (function()
  local k = { }
  ensure_tequals("table", tset({ [k] = 42 }), { [42] = true })
end)

test "tset-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tset(t), { [t] = true })
end)

test "tset-many" (function()
  local k = { }
  local t = { [1] = 42, a = k, [k] = false }

  ensure_tequals(
      "many",
      tset(t),
      { [42] = true, [k] = true, [false] = true }
    )
end)

--------------------------------------------------------------------------------

test:group "tiset"

--------------------------------------------------------------------------------

test "tiset-empty" (function()
  ensure_tequals("empty", tiset({ }), { })
end)

test "tiset-single" (function()
  ensure_tequals("simple", tiset({ [1] = 42 }), { [42] = true })
end)

test "tiset-hole" (function()
  ensure_tequals("hole ignored", tiset({ [42] = 1 }), { })
end)

test "tiset-hash" (function()
  ensure_tequals("hash ignored", tiset({ ["a"] = 42 }), { })
end)

test "tiset-duplicate" (function()
  ensure_tequals("duplicate", tiset({ [1] = 42, [2] = 42 }), { [42] = true })
end)

test "tiset-duplicate-hash" (function()
  ensure_tequals(
      "duplicate hash",
      tiset({ [1] = 42, ["a"] = 42 }),
      { [42] = true }
    )
end)

test "tiset-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tiset(t), { [t] = true })
end)

test "tiset-many" (function()
  local k = { }
  local t = { [1] = 42, [2] = 42, a = k, [k] = 42 }

   ensure_tequals("many", tiset(t), { [42] = true })
end)

--------------------------------------------------------------------------------

test:group "tiinsert_args"

--------------------------------------------------------------------------------

test "tiinsert_args-empty-noargs" (function()
  local t = { }
  local r = tiinsert_args(t)

  ensure_tequals("empty", r, { })
  ensure_equals("returns first argument", r, t)
end)

test "tiinsert_args-empty-append" (function()
  local t = { }
  local r = tiinsert_args(t, 1, 2)

  ensure_tequals("append", r, { 1, 2 })
  ensure_equals("returns first argument", r, t)
end)

test "tiinsert_args-non-empty-append" (function()
  local t = { 1 }
  local r = tiinsert_args(t, 2, 3)

  ensure_tequals("append", r, { 1, 2, 3 })
  ensure_equals("returns first argument", r, t)
end)

test "tiinsert_args-nil-stops" (function()
  local t = { 1 }
  local r = tiinsert_args(t, 2, nil, 3)

  ensure_tequals("append", r, { 1, 2 })
  ensure_equals("returns first argument", r, t)
end)

test "tiinsert_args-complex" (function()
  local t = { }
  t[1] = t
  t[t] = t
  local r = tiinsert_args(t, 1, t, t, nil, t)

  ensure_tequals("complex", r, { t, 1, t, t, [t] = t })
  ensure_equals("returns first argument", r, t)
end)

--------------------------------------------------------------------------------

test:group "timap_inplace"

--------------------------------------------------------------------------------

test "timap_inplace-empty-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = timap_inplace(fn, t)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned table", r, t)
end)

test "timap_inplace-empty-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = timap_inplace(fn, t, 42)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned table", r, t)
end)

test "timap_inplace-counter-noargs" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_inplace(fn, t)
  ensure_equals("function called", c, 3)
  ensure_equals("returned table", r, t)
  ensure_tequals("table changed", r, { 11, 22, 33, ["a"] = 42 })
end)

test "timap_inplace-counter-args" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, k)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_inplace(fn, t, k)
  ensure_equals("function called", c, 3)
  ensure_equals("returned table", r, t)
  ensure_tequals("table changed", r, { 11, 22, 33, ["a"] = 42 })
end)

--------------------------------------------------------------------------------

test:group "timap"

--------------------------------------------------------------------------------

test "timap-empty-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local old_t = tclone(t)
  local r = timap(fn, t)
  ensure_equals("function not called", c, 0)
  ensure_tequals("original table not changed", t, old_t)
  ensure("returned other table", r ~= t)
end)

test "timap-empty-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local old_t = tclone(t)
  local r = timap(fn, t, 42)
  ensure_equals("function not called", c, 0)
  ensure_tequals("original table not changed", t, old_t)
  ensure("returned other table", r ~= t)
end)

test "timap-counter-noargs" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local old_t = tclone(t)
  local r = timap(fn, t)
  ensure_equals("function called", c, 3)
  ensure_tequals("original table not changed", t, old_t)
  ensure("returned other table", r ~= t)
  ensure_tequals("table changed", r, { 11, 22, 33 })
end)

test "timap-counter-args" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, k)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local old_t = tclone(t)
  local r = timap(fn, t, k)
  ensure_equals("function called", c, 3)
  ensure_tequals("original table not changed", t, old_t)
  ensure("returned other table", r ~= t)
  ensure_tequals("table changed", r, { 11, 22, 33 })
end)

--------------------------------------------------------------------------------

test:group "timap_sliding"

--------------------------------------------------------------------------------

test "timap_sliding-empty-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = timap_sliding(fn, t)
  ensure_equals("function not called", c, 0)
  ensure_tequals("result is empty", r, { })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-empty-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = timap_sliding(fn, t, 42)
  ensure_equals("function not called", c, 0)
  ensure_tequals("result is empty", r, { })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-hash-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { ["a"] = 1 }
  local r = timap_sliding(fn, t)
  ensure_equals("function not called", c, 0)
  ensure_tequals("result is empty", r, { })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-hash-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { ["a"] = 1 }
  local r = timap_sliding(fn, t, 42)
  ensure_equals("function not called", c, 0)
  ensure_tequals("result is empty", r, { })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-counter-noargs" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_sliding(fn, t)
  ensure_equals("function called", c, 3)
  ensure_tequals("table changed", r, { 11, 22, 33 })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-counter-args" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, k)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_sliding(fn, t, k)
  ensure_equals("function called", c, 3)
  ensure_tequals("table changed", r, { 11, 22, 33 })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-counter-noargs-many" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c, a + c + 1
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_sliding(fn, t)
  ensure_equals("function called", c, 3)
  ensure_tequals("table changed", r, { 11, 12, 22, 23, 33, 34 })
  ensure("returned new table", r ~= t)
end)

test "timap_sliding-counter-args-many" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, k)
    return a + c, a + c + 1
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = timap_sliding(fn, t, k)
  ensure_equals("function called", c, 3)
  ensure_tequals("table changed", r, { 11, 12, 22, 23, 33, 34 })
  ensure("returned new table", r ~= t)
end)

--------------------------------------------------------------------------------

test:group "tequals"

--------------------------------------------------------------------------------

test "tequals-empty-eq" (function()
  ensure_equals("empty-eq", tequals({ }, { }), true)
end)

test "tequals-empty-neq" (function()
  ensure_equals("empty-neq-1", tequals({ }, { 1 }), false)
  ensure_equals("empty-neq-2", tequals({ 1 }, { }), false)
end)

test "tequals-empty-self" (function()
  local t = { }
  ensure_equals("empty-self", tequals(t, t), true)
end)

test "tequals-non-empty-eq" (function()
  ensure_equals("empty-eq", tequals({ 1 }, { 1 }), true)
end)

test "tequals-non-empty-neq" (function()
  ensure_equals("empty-neq-1", tequals({ 1 }, { 1, 2 }), false)
  ensure_equals("empty-neq-2", tequals({ 1, 2 }, { 1 }), false)
  ensure_equals("empty-neq-3", tequals({ 1, 2 }, { 3, 4 }), false)
end)

test "tequals-non-empty-self" (function()
  local t = { 1 }
  ensure_equals("non-empty-self", tequals(t, t), true)
end)

test "tequals-table-eq" (function()
  local t = { }
  ensure_equals("table-eq", tequals({ [t] = t }, { [t] = t }), true)
end)

test "tequals-table-neq" (function()
  local t1, t2 = { }, { }
  ensure_equals("table-neq", tequals({ [t1] = t1 }, { [t2] = t2 }), false)
end)

test "tequals-hole-eq" (function()
  ensure_equals("hole-eq", tequals({ [42] = 1 }, { [42] = 1 }), true)
end)

test "tequals-hole-neq" (function()
  ensure_equals("hole-neq", tequals({ [42] = 1 }, { [42] = 2 }), false)
end)

test "tequals-recursion-eq" (function()
  local lhs = { }
  lhs[lhs] = lhs

  local rhs = { }
  rhs[lhs] = lhs

  ensure_equals("recursion-eq", tequals(lhs, rhs), true)
end)

test "tequals-recursion-neq" (function()
  local lhs = { }
  lhs[lhs] = lhs

  local rhs = { }
  rhs[rhs] = rhs

  ensure_equals("reqursion-neq", tequals(lhs, rhs), false)
end)

test "tequals-recursion-self" (function()
  local t = { }
  t[t] = t

  ensure_equals("recursion-self", tequals(t, t), true)
end)

--------------------------------------------------------------------------------

test:group "tiwalk"

--------------------------------------------------------------------------------

test "tiwalk-empty-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = tiwalk(fn, t)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalk-empty-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = tiwalk(fn, t, 42)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalk-counter-noargs" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = tiwalk(fn, t)
  ensure_equals("function called", c, 3)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalk-counter-args" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, k)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = tiwalk(fn, t, k)
  ensure_equals("function called", c, 3)
  ensure_equals("returned nil", r, nil)
end)

--------------------------------------------------------------------------------

test:group "tiwalker"

--------------------------------------------------------------------------------

test "tiwalker-empty-noargs" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = tiwalker(fn)(t)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalker-empty-args" (function()
  local c = 0
  local fn = function() c = c + 1 end
  local t = { }
  local r = tiwalker(fn)(t, 42)
  ensure_equals("function not called", c, 0)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalker-counter-noargs" (function()
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil)
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = tiwalker(fn)(t)
  ensure_equals("function called", c, 3)
  ensure_equals("returned nil", r, nil)
end)

test "tiwalker-counter-args" (function()
  local k = { }
  local c = 0
  local fn = function(a, b)
    c = c + 1
    ensure_equals("check a", a, c * 10)
    ensure_equals("check b", b, nil) -- Arguments not passed through
    return a + c
  end
  local t = { 10, 20, 30, ["a"] = 42 }
  local r = tiwalker(fn)(t, k)
  ensure_equals("function called", c, 3)
  ensure_equals("returned nil", r, nil)
end)

--------------------------------------------------------------------------------

test:group "tiunique"

--------------------------------------------------------------------------------

test "tiunique-empty" (function()
  ensure_tequals("empty", tiunique({ }), { })
end)

test "tiunique-single" (function()
  ensure_tequals("simple", tiunique({ [1] = 42 }), { [1] = 42 })
end)

test "tiunique-hole" (function()
  ensure_tequals("hole ignored", tiunique({ [42] = 1 }), { })
end)

test "tiunique-hash" (function()
  ensure_tequals("hash ignored", tiunique({ ["a"] = 42 }), { })
end)

test "tiunique-duplicate" (function()
  ensure_tequals("duplicate", tiunique({ [1] = 42, [2] = 42 }), { [1] = 42 })
end)

test "tiunique-duplicate-hash" (function()
  ensure_tequals(
      "duplicate hash ignored",
      tiunique({ [1] = 42, ["a"] = 42 }),
      { [1] = 42 }
    )
end)

test "tiunique-recursive" (function()
  local t = { }
  t[1] = t
  ensure_tequals("recursive", tiunique(t), t)
end)

test "tiunique-many" (function()
  local k = { }
  local t = { [1] = 42, [2] = 42, a = k, [k] = 42 }

   ensure_tequals("many", tiunique(t), { [1] = 42 })
end)

--------------------------------------------------------------------------------

test:group "tgenerate_n"

--------------------------------------------------------------------------------

test "tgenerate_n_0" (function()
  ensure_tequals("zero", tgenerate_n(0, function() return 42 end), { })
end)

test "tgenerate_n_1" (function()
  ensure_tequals("one", tgenerate_n(1, function() return 42 end), { 42 })
end)

test "tgenerate_n_multret" (function()
  ensure_tequals("one", tgenerate_n(1, function() return 42, 1 end), { 42 })
end)

test "tgenerate_n_args" (function()
  ensure_tequals("args", tgenerate_n(1, function(a) return a end, 42), { 42 })
end)

test "tgenerate_n_5" (function()
  ensure_tequals(
      "five",
      tgenerate_n(5, function() return 42 end),
      { 42, 42, 42, 42, 42 }
    )
end)

test "tgenerate_n_nil" (function()
  ensure_tequals(
      "nil",
      tgenerate_n(5, function() return nil end),
      { nil, nil, nil, nil, nil }
    )
end)

--------------------------------------------------------------------------------

test:group "taccumulate"

--------------------------------------------------------------------------------

test "taccumulate-empty" (function()
  ensure_equals("empty default", taccumulate({ }), 0)
  ensure_equals("empty 0", taccumulate({ }, 0), 0)
  ensure_equals("empty 1", taccumulate({ }, 1), 1)
end)

test "taccumulate-array" (function()
  ensure_equals("array", taccumulate({ 1, 2, 3 }), 6)
end)

test "taccumulate-array-hole" (function()
  ensure_equals("array", taccumulate({ 1, 2, nil, nil, nil, 3 }), 6)
end)

test "taccumulate-hash" (function()
  ensure_equals("hash", taccumulate({ a = 1, b = 2, c = 3 }), 6)
end)

test "taccumulate-mixed" (function()
  ensure_equals("mixed", taccumulate({ 3, -1, a = -1, b = 2, c = 3 }), 6)
end)

--------------------------------------------------------------------------------

test:group "tnormalize"

--------------------------------------------------------------------------------

test "tnormalize-empty" (function()
  local data = { }
  local expected_default, expected_sum = { }, { }
  local result_default = tnormalize(data)
  local result_sum = tnormalize(data, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("not inplace default", data ~= result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("not inplace sum", data ~= result_sum)
end)

test "tnormalize-simple" (function()
  local data = { 3 }
  local expected_default, expected_sum = { 3 / 3 }, { 3 / 30 }
  local result_default = tnormalize(data)
  local result_sum = tnormalize(data, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("not inplace default", data ~= result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("not inplace sum", data ~= result_sum)
end)

test "tnormalize-mixed" (function()
  local data = { a = 2, 3 }
  local expected_default, expected_sum = { a = 2 / 5, 3 / 5 }, { a = 2 / 30, 3 / 30 }
  local result_default = tnormalize(data)
  local result_sum = tnormalize(data, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("not inplace default", data ~= result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("not inplace sum", data ~= result_sum)
end)

--------------------------------------------------------------------------------

test:group "tnormalize_inplace"

--------------------------------------------------------------------------------

test "tnormalize_inplace-empty" (function()
  local data_default, data_sum = { }, { }
  local expected_default, expected_sum = { }, { }
  local result_default = tnormalize_inplace(data_default)
  local result_sum = tnormalize_inplace(data_sum, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("inplace default", data_default == result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("inplace sum", data_sum == result_sum)
end)

test "tnormalize_inplace-simple" (function()
  local data_default, data_sum = { 3 }, { 3 }
  local expected_default, expected_sum = { 3 / 3 }, { 3 / 30 }
  local result_default = tnormalize_inplace(data_default)
  local result_sum = tnormalize_inplace(data_sum, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("inplace default", data_default == result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("inplace sum", data_sum == result_sum)
end)

test "tnormalize_inplace-mixed" (function()
  local data_default, data_sum = { a = 2, 3 }, { a = 2, 3 }
  local expected_default, expected_sum = { a = 2 / 5, 3 / 5 }, { a = 2 / 30, 3 / 30 }
  local result_default = tnormalize_inplace(data_default)
  local result_sum = tnormalize_inplace(data_sum, 30)

  ensure_tequals("empty default", result_default, expected_default)
  ensure("inplace default", data_default == result_default)

  ensure_tequals("empty sum", result_sum, expected_sum)
  ensure("inplace sum", data_sum == result_sum)
end)

--------------------------------------------------------------------------------

test:group "tclone"

--------------------------------------------------------------------------------

test "tclone-nontable" (function()
  ensure_equals("noarg", tclone(), nil) -- Arbitrary limitation. This allowed to fail if is implemented in C.
  ensure_equals("nil", tclone(nil), nil)
  ensure_equals("boolean-false", tclone(false), false)
  ensure_equals("boolean-true", tclone(true), true)
  ensure_equals("number", tclone(42), 42)
  ensure_equals("string", tclone("a"), "a")

  local f = function() end
  ensure_equals("function", tclone(f), f)

  local c = coroutine.create(function() end)
  ensure_equals("function", tclone(c), c)

  local u = newproxy()
  ensure_equals("function", tclone(u), u)
end)

do
  local check_tclone = function(name, value, expected)
    expected = expected or value

    arguments(
        "string", name,
        "table", value,
        "table", expected
      )

    local actual = tclone(value)

    ensure("actual is a copy", actual ~= value)
    ensure_tdeepequals("actual contents match original", actual, expected)

    return actual
  end

  test "tclone-simple" (function()
    check_tclone("empty table", {})
    check_tclone("simple table", { 42, a = 1 })
    check_tclone("subtables", { [{ 1 }] = { 2 } })
  end)

  test "tclone-links-broken" (function()
    local t = { }

    local actual = check_tclone("subtables", { t, t }, { { }, { } })

    ensure("subtable copied", actual[1] ~= t and actual[2] ~= t)
    ensure("subtable links broken", actual[1] ~= actual[2]) -- Equality is checked above
  end)
end

test "tclone-nesting-fails" (function()
  local t = { }
  t[t] = t
  t[1] = t

  ensure_fails_with_substring(
      "recursion fails",
      function() tclone(t) end,
      "recursion detected"
    )
end)

--------------------------------------------------------------------------------

test:group "tcount_elements"

--------------------------------------------------------------------------------

test "tcount_elements-empty" (function()
  ensure_equals("empty", tcount_elements({}), 0)
end)

test "tcount_elements-array-single" (function()
  ensure_equals("array-single", tcount_elements({ 42 }), 1)
end)

test "tcount_elements-array-hole" (function()
  ensure_equals("array-hole", tcount_elements({ 1, 2, nil, nil, 3, nil }), 3)
end)

test "tcount_elements-hash" (function()
  ensure_equals(
      "hash",
      tcount_elements({ 42, a = 2, b = nil }),
      2
    )
end)

--------------------------------------------------------------------------------

test:group "tremap_to_array"

--------------------------------------------------------------------------------

test "tremap_to_array-empty" (function()
  local fn = function(k, v)
    return { k, v }
  end

  ensure_tequals("empty", tremap_to_array(fn, { }), { })
end)

test "tremap_to_array-mixed" (function()
  local fn = function(k, v)
    return { k, v }
  end

  -- NOTE: Have to use tset here due to undefined hash-part traversal order.
  ensure_tdeepequals(
      "mixed",
      tset(tremap_to_array(fn, { 3, -1, a = -1, b = 2, c = 3 })),
      tset
      {
        { 1, 3 };
        { 2, -1 };
        { "a", -1 };
        { "b", 2 };
        { "c", 3 };
      }
    )
end)

--------------------------------------------------------------------------------

assert(test:run())
