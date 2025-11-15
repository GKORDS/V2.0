local GLOBAL = GLOBAL
local math = GLOBAL.math

local OVERRIDE_TAG = "mapwide_handy_remote"
local DEFAULT_RANGE = 4096

local function CalculateFullMapRange()
    local TheWorld = GLOBAL.TheWorld
    if TheWorld ~= nil and TheWorld.Map ~= nil and TheWorld.Map.GetSize ~= nil then
        local width, height = TheWorld.Map:GetSize()
        if width ~= nil and height ~= nil then
            local max_dimension = math.max(width, height)
            if max_dimension > 0 then
                -- Slightly pad the diagonal to ensure full coverage
                return math.sqrt(width * width + height * height) + 10
            end
        end
    end
    return DEFAULT_RANGE
end

local function ApplyOverride(controller)
    if controller == nil then
        return
    end

    local range = CalculateFullMapRange()
    local rangesq = range * range

    controller._mapwide_range = range
    controller._mapwide_range_sq = rangesq

    if type(controller.SetRange) == "function" then
        controller:SetRange(range)
    elseif controller.range ~= nil then
        controller.range = range
    end

    if type(controller.SetRangeSq) == "function" then
        controller:SetRangeSq(rangesq)
    elseif controller.range_sq ~= nil then
        controller.range_sq = rangesq
    end

    if type(controller.SetMaxRange) == "function" then
        controller:SetMaxRange(range)
    elseif controller.maxrange ~= nil then
        controller.maxrange = range
    end

    if controller.maxrange_sq ~= nil then
        controller.maxrange_sq = rangesq
    end

    if type(controller.SetMaxDistance) == "function" then
        controller:SetMaxDistance(range)
    end

    if controller.maxdistance ~= nil then
        controller.maxdistance = range
    end

    if controller.maxdistancesq ~= nil then
        controller.maxdistancesq = rangesq
    end

    if type(controller.SetControlDistance) == "function" then
        controller:SetControlDistance(range)
    end

    if type(controller.SetMaxControlDistance) == "function" then
        controller:SetMaxControlDistance(range)
    end

    if type(controller.GetRange) == "function" then
        if controller._mapwide_original_getrange == nil then
            controller._mapwide_original_getrange = controller.GetRange
        end
        controller.GetRange = function()
            return range
        end
    end

    if type(controller.GetRangeSq) == "function" then
        if controller._mapwide_original_getrangesq == nil then
            controller._mapwide_original_getrangesq = controller.GetRangeSq
        end
        controller.GetRangeSq = function()
            return rangesq
        end
    end

    if type(controller.IsWithinRange) == "function" then
        if controller._mapwide_original_iswithinrange == nil then
            controller._mapwide_original_iswithinrange = controller.IsWithinRange
        end
        controller.IsWithinRange = function(_, ...)
            return true
        end
    end

    if type(controller.IsInRange) == "function" then
        if controller._mapwide_original_isinrange == nil then
            controller._mapwide_original_isinrange = controller.IsInRange
        end
        controller.IsInRange = function(_, ...)
            return true
        end
    end

    if type(controller.CanControl) == "function" then
        if controller._mapwide_original_cancontrol == nil then
            controller._mapwide_original_cancontrol = controller.CanControl
        end
        controller.CanControl = function(self, target, ...)
            local original = self._mapwide_original_cancontrol
            if original ~= nil then
                local ok = original(self, target, ...)
                if ok == false then
                    return true
                end
                return ok
            end
            return true
        end
    end
end

local function OverrideRemote(inst)
    if inst == nil then
        return
    end

    inst:AddTag(OVERRIDE_TAG)

    local function TryApply()
        if inst.components ~= nil and inst.components.handycontroller ~= nil then
            ApplyOverride(inst.components.handycontroller)
        elseif inst.replica ~= nil and inst.replica.handycontroller ~= nil then
            ApplyOverride(inst.replica.handycontroller)
        end
    end

    inst:DoTaskInTime(0, TryApply)
    inst:ListenForEvent("handycontrollerdirty", TryApply)
    inst:ListenForEvent("equip", TryApply)
end

AddPrefabPostInit("winona_remote", OverrideRemote)

AddComponentPostInit("handycontroller", function(self)
    if self.inst ~= nil and self.inst:HasTag(OVERRIDE_TAG) then
        self.inst:DoTaskInTime(0, function()
            ApplyOverride(self)
        end)
    end
end)

AddClassPostConstruct("components/handycontroller_replica", function(self)
    if self.inst ~= nil then
        self.inst:DoTaskInTime(0, function()
            if self.inst:HasTag(OVERRIDE_TAG) then
                ApplyOverride(self)
            end
        end)
    end
end)

AddPrefabPostInit("winona_catapult", function(inst)
    local function ApplyToWeapon()
        if inst.components ~= nil and inst.components.handycontroller ~= nil then
            ApplyOverride(inst.components.handycontroller)
        end
        if inst.replica ~= nil and inst.replica.handycontroller ~= nil then
            ApplyOverride(inst.replica.handycontroller)
        end
    end

    inst:DoTaskInTime(0, ApplyToWeapon)
end)
