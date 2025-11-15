local GLOBAL = GLOBAL
local math = GLOBAL.math
local TILE_SCALE = GLOBAL.TILE_SCALE or 4

local function GetFullMapRadius()
    local world = GLOBAL.TheWorld
    if world ~= nil and world.Map ~= nil then
        local width, height = world.Map:GetSize()
        if width ~= nil and height ~= nil then
            local world_width = width * TILE_SCALE
            local world_height = height * TILE_SCALE
            return math.sqrt(world_width * world_width + world_height * world_height)
        end
    end
    -- Fallback large value that safely covers the map in case world data isn't ready yet.
    return 4096
end

local function ShouldOverride(inst)
    return inst ~= nil and inst.prefab == "winona_catapult"
end

local function GetOverrideRangeSq()
    local range = GetFullMapRadius()
    return range * range
end

local function ApplyServerOverrides(machine)
    if machine._fullmap_override_applied then
        return
    end
    machine._fullmap_override_applied = true


    if machine.GetActivateDistanceSq ~= nil then
        local _GetActivateDistanceSq = machine.GetActivateDistanceSq
        machine.GetActivateDistanceSq = function(self)
            if ShouldOverride(self.inst) then
                return GetOverrideRangeSq()
            end
            return _GetActivateDistanceSq(self)
        end
    else
        machine.GetActivateDistanceSq = function(self)
            if ShouldOverride(self.inst) then
                return GetOverrideRangeSq()
            end
            return 0
        end
    end

    if machine.GetActivateDistance ~= nil then
        local _GetActivateDistance = machine.GetActivateDistance
        machine.GetActivateDistance = function(self)
            if ShouldOverride(self.inst) then
                return math.sqrt(GetOverrideRangeSq())
            end
            return _GetActivateDistance(self)
        end
    else
        machine.GetActivateDistance = function(self)
            if ShouldOverride(self.inst) then
                return math.sqrt(GetOverrideRangeSq())
            end
            return 0
        end
    end
end

local function ApplyClientOverrides(replica)
    if replica._fullmap_override_applied then
        return
    end
    replica._fullmap_override_applied = true

    local range_sq_fn = function()
        return GetOverrideRangeSq()
    end

    if replica.GetActivateDistanceSq ~= nil then
        local _GetActivateDistanceSq = replica.GetActivateDistanceSq
        replica.GetActivateDistanceSq = function(self)
            if ShouldOverride(self.inst) then
                return range_sq_fn()
            end
            return _GetActivateDistanceSq(self)
        end
    else
        replica.GetActivateDistanceSq = function(self)
            if ShouldOverride(self.inst) then
                return range_sq_fn()
            end
            return 0
        end
    end

    if replica.GetActivateDistance ~= nil then
        local _GetActivateDistance = replica.GetActivateDistance
        replica.GetActivateDistance = function(self)
            if ShouldOverride(self.inst) then
                return math.sqrt(range_sq_fn())
            end
            return _GetActivateDistance(self)
        end
    else
        replica.GetActivateDistance = function(self)
            if ShouldOverride(self.inst) then
                return math.sqrt(range_sq_fn())
            end
            return 0
        end
    end
end

AddComponentPostInit("machine", function(self)
    if not ShouldOverride(self.inst) then
        return
    end

    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
        ApplyServerOverrides(self)
    end
end)

AddClassPostConstruct("components/machine_replica", function(self)
    ApplyClientOverrides(self)
end)

AddPrefabPostInit("winona_catapult", function(inst)
    if GLOBAL.TheWorld == nil or not GLOBAL.TheWorld.ismastersim then
        return
    end

    inst:DoTaskInTime(0, function()
        local machine = inst.components.machine
        if machine ~= nil then
            -- Force refresh of cached range values after the catapult finishes spawning.
            if machine.GetActivateDistanceSq ~= nil then
                machine:GetActivateDistanceSq()
            end
        end
    end)
end)
