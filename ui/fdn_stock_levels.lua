-- Card X4-18b. Lua helper for FDN stock levels (real Logical Overview storage levels).
-- Replaces the X4-18a one-shot proof helper (same proven bridge and vanilla globals):
--   HasContainerStockLimitOverride / GetWareProductionLimit / SetContainerStockLimitOverride /
--   ClearContainerStockLimitOverride / GetWareCapacity (ego_detailmonitorhelper/helper.lua)
-- Bridge (sn_mod_support_apis): MD appends flat command tables to the player.entity blackboard
-- list $fdn_stock_levels_args and raises FDN_StockLevels.Command; Lua drains the whole list and
-- answers each command with AddUITriggeredEvent("FDN_StockLevels", "item", {...}) and each token
-- with a final "done". Commands:
--   read    {token, seq, station, wareid}                -> ok, had, amount, capacity (changes nothing)
--   set     {token, seq, station, wareid, amount}        -> ok, had_after, after
--   restore {token, seq, station, wareid, had, amount}   -> had=1: Set(amount); had=0: Clear; ok, had_after, after
-- Lua keeps no state between calls: MD saves the originals before any set.
-- Does NOT change buy/sell limits, prices or trade rules.

local ffi = require("ffi")
local C = ffi.C

local L = { player_id = nil }

local function dbg(msg)
  if DebugError then
    DebugError("FDN_StockLevels: " .. tostring(msg))
  end
end

local function ensure_player()
  if L.player_id == nil then
    L.player_id = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  end
  return L.player_id
end

local function missing_apis()
  if not HasContainerStockLimitOverride then return "HasContainerStockLimitOverride" end
  if not GetWareProductionLimit then return "GetWareProductionLimit" end
  if not SetContainerStockLimitOverride then return "SetContainerStockLimitOverride" end
  if not ClearContainerStockLimitOverride then return "ClearContainerStockLimitOverride" end
  if not GetWareCapacity then return "GetWareCapacity" end
  if not GetNPCBlackboard then return "GetNPCBlackboard" end
  if not SetNPCBlackboard then return "SetNPCBlackboard" end
  if not AddUITriggeredEvent then return "AddUITriggeredEvent" end
  return nil
end

local function read_state(station, wareid)
  local had = HasContainerStockLimitOverride(station, wareid) and 1 or 0
  local amount = tonumber(GetWareProductionLimit(station, wareid) or 0) or 0
  return had, amount
end

local function handle(args)
  local cmd = args.cmd
  local station = args.station
  local wareid = args.wareid
  if station == nil or wareid == nil or wareid == "" then
    return { ok = 0, error = "bad_args" }
  end
  if cmd == "read" then
    local had, amount = read_state(station, wareid)
    local capacity = tonumber(GetWareCapacity(station, wareid) or 0) or 0
    return { ok = 1, error = "", had = had, amount = amount, capacity = capacity }
  elseif cmd == "set" then
    local amount = tonumber(args.amount)
    if amount == nil or amount < 1 then
      return { ok = 0, error = "bad_amount" }
    end
    SetContainerStockLimitOverride(station, wareid, amount)
    local had_after, after = read_state(station, wareid)
    return { ok = 1, error = "", had_after = had_after, after = after }
  elseif cmd == "restore" then
    local had = tonumber(args.had) or 0
    if had == 1 then
      local amount = tonumber(args.amount)
      if amount == nil or amount < 1 then
        return { ok = 0, error = "bad_amount" }
      end
      SetContainerStockLimitOverride(station, wareid, amount)
    else
      ClearContainerStockLimitOverride(station, wareid)
    end
    local had_after, after = read_state(station, wareid)
    return { ok = 1, error = "", had_after = had_after, after = after }
  end
  return { ok = 0, error = "unknown_cmd:" .. tostring(cmd) }
end

local function on_command(_, _param)
  local miss = missing_apis()
  local pid = ensure_player()
  local list = GetNPCBlackboard and GetNPCBlackboard(pid, "$fdn_stock_levels_args") or nil
  if SetNPCBlackboard then
    SetNPCBlackboard(pid, "$fdn_stock_levels_args", nil)
  end
  if list == nil then
    return
  end
  local tokens, order = {}, {}
  for _, args in ipairs(list) do
    local token = args.token or 0
    local res
    if miss then
      res = { ok = 0, error = "missing_api:" .. miss }
    else
      local okcall, r = pcall(handle, args)
      if okcall then
        res = r
      else
        res = { ok = 0, error = "lua_error:" .. tostring(r) }
        dbg("error in " .. tostring(args.cmd) .. ": " .. tostring(r))
      end
    end
    res.token = token
    res.seq = args.seq or 0
    res.cmd = args.cmd or ""
    AddUITriggeredEvent("FDN_StockLevels", "item", res)
    if not tokens[token] then
      tokens[token] = true
      table.insert(order, token)
    end
  end
  for _, token in ipairs(order) do
    AddUITriggeredEvent("FDN_StockLevels", "done", { token = token })
  end
end

local function Init()
  ensure_player()
  RegisterEvent("FDN_StockLevels.Command", on_command)
  dbg("init ok")
end

if Register_OnLoad_Init then
  Register_OnLoad_Init(Init, "extensions.fdn_x4.ui.fdn_stock_levels")
else
  dbg("Register_OnLoad_Init missing; sn_mod_support_apis required")
end
