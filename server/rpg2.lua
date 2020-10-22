
local particles = ImportPackage("particles")
local rockets = {}
local launched_rockets = {}

local function RPG_GetDistanceSquared3D(x, y, z, x2, y2, z2)
    return ((x2 - x)^2 + (y2 - y)^2 + (z2 - z)^2)
end

local function create_rocket(ply)
    local x,y,z = GetPlayerLocation(ply)
    local rocket_obj = CreateObject(111000, x, y, z-400,0,0,0,10,10,10)
    local tbl = {}
    tbl.ply = ply
    tbl.obj = rocket_obj
    table.insert(rockets, tbl)
    SetObjectDimension(rocket_obj, GetPlayerDimension(ply))
    SetObjectAttached(rocket_obj, 1, ply, -28.0, 6.0, 6.5, 0.0, -90.0, -10.0, "hand_r")
end

local function GetNearestPlayerFromObjectAndStreamed(obj)
   local neardist = nil
   local nearply = nil
   local x, y, z = GetObjectLocation(obj)
   for i, v in ipairs(GetAllPlayers()) do
      if IsObjectStreamedIn(v, obj) then
         if neardist then
             local x2, y2, z2 = GetPlayerLocation(v)
             local dist = RPG_GetDistanceSquared3D(x, y, z, x2, y2, z2)
             if dist < neardist then
                neardist = dist
                nearply = v
             end
         else
             local x2, y2, z2 = GetPlayerLocation(v)
             neardist = RPG_GetDistanceSquared3D(x, y, z, x2, y2, z2)
             nearply = v
         end
      end
   end
   return nearply
end

AddRemoteEvent("Destroy_rocket",function(ply, obj)
    for i,v in ipairs(launched_rockets) do
       if v.obj == obj then
          if IsValidObject(obj) then
             DestroyTimer(v.timer)
             DestroyObject(obj)
          end
          table.remove(launched_rockets,i)
          break
       end
    end
end)

local function rockets_timer()
    for i, ply in ipairs(GetAllPlayers()) do
        local hasattachedrocket = false
        local object = nil
        local index = nil
        for i2, v in ipairs(rockets) do
           if v.ply == ply then
              hasattachedrocket = true
              index = i2
              object = v.obj
           end
        end
        local veh = GetPlayerVehicle(ply)
        local weapid, ammo = GetPlayerWeapon(ply, GetPlayerEquippedWeaponSlot(ply))
        if (veh == 0 and weapid == weapon_model_id) then
             if not hasattachedrocket then
                create_rocket(ply)
             end
        elseif hasattachedrocket then
             DestroyObject(object)
             table.remove(rockets, index)
        end
    end
end

local function a_rocket_timer(rocket_obj, fx, fy, fz, ply)
    local x, y, z = GetObjectLocation(rocket_obj)
    SetObjectLocation(rocket_obj, x + fx * (rocket_speed_per_s * added_speed), y + fy * (rocket_speed_per_s * added_speed), z + fz * (rocket_speed_per_s * added_speed))
    if not IsObjectStreamedIn(ply, rocket_obj) then
        local nearply = GetNearestPlayerFromObjectAndStreamed(rocket_obj)
        if nearply then
            SetObjectPropertyValue(rocket_obj, "RocketLinetraces_client", nearply, true)
        else
            for i,v in ipairs(launched_rockets) do
                if v.obj == rocket_obj then
                   DestroyTimer(v.timer)
                   DestroyObject(rocket_obj)
                   table.remove(launched_rockets, i)
                   break
                end
             end
        end
    end
end

AddEvent("OnPlayerQuit",function(ply)
    for i,v in ipairs(rockets) do
       if v.ply == ply then
          DestroyObject(v.obj)
          table.remove(rockets,i)
          break
       end
    end
    for i,v in ipairs(launched_rockets) do
        if v.ply == ply then
           if v.timer then
              DestroyTimer(v.timer)
           end
           DestroyObject(v.obj)
           table.remove(launched_rockets,i)
           break
        end
     end
end)

AddEvent("OnPlayerWeaponShot",function(ply, weap)
    if weap == weapon_model_id then
        for i, v in ipairs(rockets) do
            if v.ply == ply then
                table.insert(launched_rockets, v)
                CallRemoteEvent(ply, "RocketLaunched", v.obj)
                table.remove(rockets, i)
            end
         end
    end
end)

AddRemoteEvent("Launched_rocket_ready_client",function(ply, rocket, fx, fy, fz, x, y, z, rx, ry, rz)
    for i, v in ipairs(launched_rockets) do
       if (v.ply == ply and rocket == v.obj) then
          SetObjectPropertyValue(v.obj, "RocketOwner", ply, true)
          SetObjectDetached(v.obj)
          SetObjectLocation(v.obj, x, y, z)
          SetObjectRotation(v.obj, rx, ry, rz)
          v.timer = CreateTimer(a_rocket_timer, rocket_timer_delay, rocket, fx, fy, fz, ply)
          if particles then
             particles.CreateLoopParticleAttached(3, v.obj, rocket_particle_id, 0, 0, 0, 0, -90, 0, 0.5, 0.5, 0.5)
          end
       end
    end
end)

AddRemoteEvent("Impact_rocket",function(ply,rocket,hitid,hittype,x,y,z)
    local found
    for i,v in ipairs(launched_rockets) do
        if v.obj == rocket then
            DestroyTimer(v.timer)
            DestroyObject(rocket)
            found = true
            table.remove(launched_rockets,i)
        end
     end
    if found then
        if hittype == 3 then
            SetVehicleHealth(hitid, GetVehicleHealth(hitid)-rocket_damage_vehicles)
        end
        CreateExplosion(16, x, y, z, GetPlayerDimension(ply))
    end
end)

AddEvent("OnPackageStart",function()
    CreateTimer(rockets_timer, create_rocket_timer)
end)

AddEvent("OnPlayerChangeDimension", function(ply, olddim, dim)
    for i, v in ipairs(rockets) do
       if v.ply == ply then
           SetObjectDimension(v.obj, dim)
       end
    end
end)