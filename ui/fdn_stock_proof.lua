-- Card X4-18a. Minimal Lua helper for a one-shot station stock-limit proof.
-- Vanilla globals (ego_detailmonitorhelper/helper.lua):
--   HasContainerStockLimitOverride / GetWareProductionLimit /
--   SetContainerStockLimitOverride / ClearContainerStockLimitOverride / GetWareCapacity
-- Bridge (sn_mod_support_apis interact/simple_menu):
--   player.entity blackboard GetNPCBlackboard/SetNPCBlackboard
--   raise_lua_event -> RegisterEvent; reply AddUITriggeredEvent
-- Two-phase: prepare (snapshot only) then apply (mutate). Snapshot exists on MD
-- before any mutation so a lost apply reply can still restore.
-- Does NOT change buy/sell flags, price, or trade rules. No silent load mutation.

local ffi = require("ffi")
local C = ffi.C

local L = {
  player_id = nil,
  queued_args = {},
  -- pending: {station, wareid, token, had_override, amount_before, capacity, mutated}
  pending = nil,
}

local function dbg(msg)
  if DebugError then
    DebugError("FDN_StockProof: " .. tostring(msg))
  end
end

local function ensure_player()
  if L.player_id == nil then
    L.player_id = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  end
  return L.player_id
end

local function reply(control, fields)
  AddUITriggeredEvent("FDN_StockProof", control, fields)
end

local function get_next_args()
  if #L.queued_args == 0 then
    local pid = ensure_player()
    local args_list = GetNPCBlackboard(pid, "$fdn_stock_proof_args")
    if args_list then
      for _, v in ipairs(args_list) do
        table.insert(L.queued_args, v)
      end
      SetNPCBlackboard(pid, "$fdn_stock_proof_args", nil)
    end
  end
  if #L.queued_args == 0 then
    return nil
  end
  return table.remove(L.queued_args, 1)
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

local function do_prepare(args)
  local miss = missing_apis()
  if miss then
    reply("result", { ok = 0, op = "prepared", token = args.token or 0, error = "missing_api:" .. miss })
    return
  end
  local station = args.station
  local wareid = args.wareid
  local token = args.token or 0
  if station == nil or wareid == nil or wareid == "" then
    reply("result", { ok = 0, op = "prepared", token = token, error = "bad_args" })
    return
  end
  if L.pending ~= nil then
    reply("result", { ok = 0, op = "prepared", token = token, error = "lua_busy" })
    return
  end

  local had = HasContainerStockLimitOverride(station, wareid) and true or false
  local before = tonumber(GetWareProductionLimit(station, wareid) or 0) or 0
  local capacity = tonumber(GetWareCapacity(station, wareid) or 0) or 0
  local newv = before + 1
  if capacity <= 0 then
    reply("result", { ok = 0, op = "prepared", token = token, error = "no_capacity",
      had_override = had and 1 or 0, amount_before = before, capacity = capacity })
    return
  end
  if newv > capacity then
    reply("result", { ok = 0, op = "prepared", token = token, error = "at_capacity",
      had_override = had and 1 or 0, amount_before = before, capacity = capacity })
    return
  end
  if newv < 1 then
    reply("result", { ok = 0, op = "prepared", token = token, error = "invalid_new",
      had_override = had and 1 or 0, amount_before = before, capacity = capacity })
    return
  end

  -- Persist local pending BEFORE any mutation (MD also stores from this reply).
  L.pending = {
    station = station,
    wareid = wareid,
    token = token,
    had_override = had,
    amount_before = before,
    capacity = capacity,
    amount_set = newv,
    mutated = false,
  }
  reply("result", {
    ok = 1, op = "prepared", token = token, error = "",
    had_override = had and 1 or 0,
    amount_before = before,
    amount_set = newv,
    capacity = capacity,
  })
end

local function do_apply(args)
  local miss = missing_apis()
  if miss then
    reply("result", { ok = 0, op = "applied", token = args.token or 0, error = "missing_api:" .. miss })
    return
  end
  local station = args.station
  local wareid = args.wareid
  local token = args.token or 0

  -- Rebuild pending from MD snapshot if Lua reloaded after prepare.
  if L.pending == nil and args.had_override ~= nil and args.amount_before ~= nil then
    local before = tonumber(args.amount_before) or 0
    L.pending = {
      station = station,
      wareid = wareid,
      token = token,
      had_override = (tonumber(args.had_override) or 0) == 1,
      amount_before = before,
      capacity = tonumber(args.capacity) or 0,
      amount_set = before + 1,
      mutated = false,
    }
  end

  if L.pending == nil or L.pending.token ~= token then
    reply("result", { ok = 0, op = "applied", token = token, error = "no_prepare" })
    return
  end
  if L.pending.mutated then
    reply("result", {
      ok = 1, op = "applied", token = token, error = "already_mutated",
      had_override = L.pending.had_override and 1 or 0,
      amount_before = L.pending.amount_before,
      amount_set = L.pending.amount_set,
      amount_after = GetWareProductionLimit(L.pending.station, L.pending.wareid) or 0,
      had_after = HasContainerStockLimitOverride(L.pending.station, L.pending.wareid) and 1 or 0,
      capacity = L.pending.capacity or 0,
    })
    return
  end

  station = L.pending.station or station
  wareid = L.pending.wareid or wareid
  local newv = L.pending.amount_set
  SetContainerStockLimitOverride(station, wareid, newv)
  L.pending.mutated = true

  local after = tonumber(GetWareProductionLimit(station, wareid) or 0) or 0
  local had_after = HasContainerStockLimitOverride(station, wareid) and true or false
  reply("result", {
    ok = 1, op = "applied", token = token, error = "",
    had_override = L.pending.had_override and 1 or 0,
    amount_before = L.pending.amount_before,
    amount_set = newv,
    amount_after = after,
    had_after = had_after and 1 or 0,
    capacity = L.pending.capacity or 0,
  })
end

local function do_restore(args)
  local miss = missing_apis()
  if miss then
    reply("result", { ok = 0, op = "restored", token = args.token or 0, error = "missing_api:" .. miss })
    return
  end
  local station = args.station
  local wareid = args.wareid
  local token = args.token or 0
  local had
  local amount_before

  if args.had_override ~= nil then
    had = (tonumber(args.had_override) or 0) == 1
    amount_before = tonumber(args.amount_before) or 0
  elseif L.pending and L.pending.token == token then
    had = L.pending.had_override
    amount_before = L.pending.amount_before
    station = station or L.pending.station
    wareid = wareid or L.pending.wareid
  else
    reply("result", { ok = 0, op = "restored", token = token, error = "no_snapshot" })
    return
  end
  if station == nil or wareid == nil or wareid == "" then
    reply("result", { ok = 0, op = "restored", token = token, error = "bad_args" })
    return
  end

  local before_restore = tonumber(GetWareProductionLimit(station, wareid) or 0) or 0
  if had then
    SetContainerStockLimitOverride(station, wareid, amount_before)
  else
    ClearContainerStockLimitOverride(station, wareid)
  end
  local after = tonumber(GetWareProductionLimit(station, wareid) or 0) or 0
  local had_after = HasContainerStockLimitOverride(station, wareid) and true or false
  local restored_ok = 0
  if had then
    if had_after and after == amount_before then restored_ok = 1 end
  else
    if not had_after then restored_ok = 1 end
  end
  if restored_ok == 1 and L.pending and L.pending.token == token then
    L.pending = nil
  end
  reply("result", {
    ok = restored_ok, op = "restored", token = token,
    error = (restored_ok == 1) and "" or "restore_mismatch",
    had_override = had and 1 or 0,
    amount_before = amount_before,
    amount_before_restore = before_restore,
    amount_after = after,
    had_after = had_after and 1 or 0,
    restored_ok = restored_ok,
  })
end

local function on_command(_, _param)
  local args = get_next_args()
  if args == nil then
    dbg("command with empty args")
    reply("result", { ok = 0, op = "none", token = 0, error = "empty_args" })
    return
  end
  local cmd = args.cmd
  if cmd == "prepare" then
    do_prepare(args)
  elseif cmd == "apply" then
    do_apply(args)
  elseif cmd == "restore" then
    do_restore(args)
  elseif cmd == "ping" then
    local miss = missing_apis()
    reply("result", {
      ok = miss and 0 or 1, op = "ping", token = args.token or 0,
      error = miss and ("missing_api:" .. miss) or "",
    })
  else
    reply("result", { ok = 0, op = tostring(cmd or "unknown"), token = args.token or 0, error = "unknown_cmd" })
  end
end

local function Init()
  ensure_player()
  RegisterEvent("FDN_StockProof.Command", on_command)
  AddUITriggeredEvent("FDN_StockProof", "ready", { ok = 1 })
  dbg("init ok")
end

if Register_OnLoad_Init then
  Register_OnLoad_Init(Init, "extensions.fdn_x4.ui.fdn_stock_proof")
else
  dbg("Register_OnLoad_Init missing; sn_mod_support_apis required")
end
