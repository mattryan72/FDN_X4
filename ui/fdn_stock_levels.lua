-- Card X4-18b (buy limits added by card X4-22e). Lua helper for FDN stock levels (real Logical Overview storage levels).
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
--   bset     {token, seq, station, wareid, amount}      -> card X4-22e: buy limit override = amount and buying on
--                                                          (same two calls as vanilla Helper.setBuyLimit); ok, bhad_after, bafter, buyable_after
--   brestore {token, seq, station, wareid, had, amount, buy} -> had=1: SetContainerBuyLimitOverride(amount); had=0: Clear;
--                                                          then SetContainerWareIsBuyable(buy == 1); ok, bhad_after, bafter, buyable_after
-- Card X4-22e: 'read' also returns the buy side: bhad (HasContainerBuyLimitOverride 0/1), bamount (GetContainerBuyLimit),
-- buyable (GetContainerWareIsBuyable 0/1). Buy calls are vanilla ffi.C functions declared by helper.lua
-- (ego_detailmonitorhelper), the same ones the Logical Overview buy offer uses. Missing ones fail only the buy fields/commands.
-- Lua keeps no state between calls: MD saves the originals before any set.
-- Does NOT change sell limits, prices or trade rules.

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

-- Card X4-22e: buy side. The ffi functions take a 64-bit container id (vanilla menus use ConvertIDTo64Bit).
-- The station arrives from the MD blackboard like the containerid vanilla menus get from MD; try ConvertIDTo64Bit first,
-- then the ConvertStringTo64Bit(tostring(...)) form vanilla also uses for components.
local function to64(station)
  local t = type(station)
  if t == "cdata" or t == "number" then
    return station
  end
  if ConvertIDTo64Bit then
    local ok, v = pcall(ConvertIDTo64Bit, station)
    if ok and v ~= nil and v ~= 0 then
      return v
    end
  end
  local v = ConvertStringTo64Bit(tostring(station))
  if v == nil or v == 0 then
    error("bad_station")
  end
  return v
end

local function read_buy(c64, wareid)
  local bhad = C.HasContainerBuyLimitOverride(c64, wareid) and 1 or 0
  local bamount = tonumber(C.GetContainerBuyLimit(c64, wareid)) or 0
  local buyable = C.GetContainerWareIsBuyable(c64, wareid) and 1 or 0
  return bhad, bamount, buyable
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
    local res = { ok = 1, error = "", had = had, amount = amount, capacity = capacity, bok = 0 }
    local okb, bhad, bamount, buyable = pcall(function () return read_buy(to64(station), wareid) end)
    if okb then
      res.bok = 1
      res.bhad = bhad
      res.bamount = bamount
      res.buyable = buyable
    else
      res.berror = "lua_error:" .. tostring(bhad)
      dbg("buy read failed: " .. tostring(bhad))
    end
    return res
  elseif cmd == "bset" then
    local amount = tonumber(args.amount)
    if amount == nil or amount < 1 then
      return { ok = 0, error = "bad_amount" }
    end
    local c64 = to64(station)
    C.SetContainerBuyLimitOverride(c64, wareid, amount)
    C.SetContainerWareIsBuyable(c64, wareid, true)
    local bhad, bamount, buyable = read_buy(c64, wareid)
    return { ok = 1, error = "", bhad_after = bhad, bafter = bamount, buyable_after = buyable }
  elseif cmd == "brestore" then
    local c64 = to64(station)
    local had = tonumber(args.had) or 0
    if had == 1 then
      local amount = tonumber(args.amount)
      if amount == nil or amount < 0 then
        return { ok = 0, error = "bad_amount" }
      end
      C.SetContainerBuyLimitOverride(c64, wareid, amount)
    else
      C.ClearContainerBuyLimitOverride(c64, wareid)
    end
    C.SetContainerWareIsBuyable(c64, wareid, (tonumber(args.buy) or 0) == 1)
    local bhad, bamount, buyable = read_buy(c64, wareid)
    return { ok = 1, error = "", bhad_after = bhad, bafter = bamount, buyable_after = buyable }
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
