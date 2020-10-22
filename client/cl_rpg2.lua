
local dlt = ImportPackage("debuglinetrace")
LoadPak("rpg", "/rpg/", "../../../OnsetModding/Plugins/rpg/Content")
ReplaceObjectModelMesh(111000, "/rpg/rocket")

function table_count(tbl)
    local nb = 0
    for k, v in pairs(tbl) do
       nb = nb + 1
    end
    return nb
end

function GetRocketForwardVector(obj)
    local actor = GetObjectActor(obj)
    local f = actor:GetActorRightVector()
    f.X = f.X*-1
    f.Y = f.Y*-1
    f.Z = f.Z*-1
    return f.X,f.Y,f.Z
 end

--local lastloc = nil
--local dist_between_each_teleport = 0
local oldtickcount = 0

local function rockets_timer()
	local tick = GetTickCount()
	--AddPlayerChat(tostring(tick - oldtickcount))
	local diff_tick = tick - oldtickcount
	oldtickcount = tick
    for i, v in ipairs(GetStreamedObjects(false)) do
       if (GetObjectModel(v) == 111000) then
           local fx, fy, fz = GetRocketForwardVector(v)
           local actor = GetObjectActor(v)
           local actorloc = actor:GetActorLocation()
		   local x, y, z = actorloc.X, actorloc.Y, actorloc.Z
		   local div = diff_tick
		   if diff_tick > rocket_lerp_each_server_delay then
		       div = (rocket_timer_delay / rocket_lerp_each_server_delay) - (diff_tick - (rocket_timer_delay / rocket_lerp_each_server_delay))
		   elseif diff_tick < rocket_lerp_each_server_delay then
			   div = (rocket_timer_delay / rocket_lerp_each_server_delay) + (diff_tick - (rocket_timer_delay / rocket_lerp_each_server_delay))
		   end
		   if (div == 0 or div < 0) then
			  div = 1
		   end
		   div = div * rocket_lerp_each_server_delay / (rocket_timer_delay / rocket_lerp_each_server_delay)
		   --AddPlayerChat(div)
		   local prop_other_streamer = GetObjectPropertyValue(v, "RocketLinetraces_client")
		   local rocket_owner = GetObjectPropertyValue(v, "RocketOwner")
		   if ((rocket_owner == GetPlayerId() and not prop_other_streamer) or (prop_other_streamer == GetPlayerId())) then
				local hittype, hitid, impactX, impactY, impactZ
				if dlt then
					hittype, hitid, impactX, impactY, impactZ = dlt.Debug_LineTrace(x, y, z, x + fx * (((rocket_speed_per_s * (added_speed)) / div) + 100), y + fy * (((rocket_speed_per_s * (added_speed)) / div) + 100), z + fz * (((rocket_speed_per_s * (added_speed)) / div) + 100), 5)
				else
					hittype, hitid, impactX, impactY, impactZ = LineTrace(x, y, z, x + fx * (((rocket_speed_per_s * (added_speed)) / div) + 100), y + fy * (((rocket_speed_per_s * (added_speed)) / div) + 100), z + fz * (((rocket_speed_per_s * (added_speed)) / div) + 100))
				end
				if (impactX ~= 0 and impactY ~= 0 and impactZ ~= 0) then
					if hittype == 2 then
						if rocket_owner ~= hitid then
							CallRemoteEvent("Impact_rocket", v, hitid, hittype, impactX, impactY, impactZ)
						end
					else
						CallRemoteEvent("Impact_rocket", v, hitid, hittype, impactX, impactY, impactZ)
					end
				end
		   end
		   local statrocket = GetObjectStaticMeshComponent(v)
		   statrocket:SetMobility(EComponentMobility.Movable)
		   actor:SetActorLocation(FVector(x + fx * ((rocket_speed_per_s * (added_speed)) / div), y + fy * ((rocket_speed_per_s * (added_speed)) / div), z + fz * ((rocket_speed_per_s * (added_speed)) / div)))
		   statrocket:SetMobility(EComponentMobility.Static)
		   --[[if (lastloc and lastloc[1] ~= x and lastloc[2] ~= y and lastloc[3] ~= z) then
			  local dist = GetDistance3D(lastloc[1], lastloc[2], lastloc[3], x, y, z)
			  if dist > 10 then
				 AddPlayerChat(tostring(dist))
                 AddPlayerChat("dist parcourue par le client " .. tostring(dist_between_each_teleport))
				 dist_between_each_teleport = 0
			  end
		   end
		   dist_between_each_teleport = dist_between_each_teleport + GetDistance3D(x, y, z, x + fx * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay), y + fy * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay), z + fz * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay))
		   lastloc = {x + fx * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay), y + fy * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay), z + fz * ((rocket_speed_per_s * (added_speed)) / rocket_lerp_each_server_delay)}]]--
       end
	end
end

local function AddRot(r, r2)
   r = r + r2
   if r > 180 then
	  r = -180 + (r - 180)
   elseif r < -180 then
	  r = 180 + (r + 180)
   end
   return r
end

AddRemoteEvent("RocketLaunched",function(obj)
    local fx, fy, fz = GetCameraForwardVector()
	local x, y, z = GetCameraLocation(false)
	local range = 1500
	local mX, mY, mZ = GetPlayerWeaponMuzzleLocation()
	local hittype, hitid, impactX, impactY, impactZ
	if dlt then
	    hittype, hitid, impactX, impactY, impactZ = dlt.Debug_LineTrace(mX, mY, mZ, x + fx * range, y + fy * range, z + fz * range, 10)
	else
		hittype, hitid, impactX, impactY, impactZ = LineTrace(mX, mY, mZ, x + fx * range, y + fy * range, z + fz * range)
	end
	local px, py, pz = GetPlayerLocation(GetPlayerId())
	local notgood
	if (impactX ~= 0 and impactY ~= 0 and impactZ ~= 0) then
	   --AddPlayerChat(tostring(GetDistanceSquared3D(px, py, pz, impactX, impactY, impactZ)))
	   if GetDistanceSquared3D(px, py, pz, impactX, impactY, impactZ) < 500000 then
		  notgood = true
		  fx, fy, fz = GetRocketForwardVector(obj)
		  local rocketactor = GetObjectActor(obj)
		  local rocketloc = rocketactor:GetActorLocation()
		  x, y, z = rocketloc.X, rocketloc.Y, rocketloc.Z
		  local rocketrot = rocketactor:GetActorRotation()
		  rx, ry, rz = rocketrot.Pitch, rocketrot.Yaw, rocketrot.Roll
		  CallRemoteEvent("Launched_rocket_ready_client", obj, fx, fy, fz, x, y, z, rx, ry, rz)
	   end
	end
	if not notgood then
		local mult = 200
		x, y, z = x + fx * mult, y + fy * mult, z + fz * mult
		local rx, ry, rz = GetCameraRotation(false)
		rx, ry, rz = 0, AddRot(ry, 90), rx
		CallRemoteEvent("Launched_rocket_ready_client", obj, fx, fy, fz, x, y, z, rx, ry, rz)
	end
end)

AddEvent("OnObjectStreamIn",function(obj)
	if GetObjectModel(obj) == 111000 then
	   EnableObjectHitEvents(obj, false)
	   GetObjectActor(obj):SetActorEnableCollision(false)
	end
end)

AddEvent("OnPackageStart", function()
    CreateTimer(rockets_timer, rocket_timer_delay / rocket_lerp_each_server_delay)
    Weapon = GetWeaponIdentifier():NewWeapon(weapon_model_id)
	Weapon:SetWeaponType(2)
	Weapon:SetWeaponSubType(4)
	Weapon:SetWeaponModel(USkeletalMesh.LoadFromAsset("/rpg/rpg_only_sk"))
    Weapon:SetStaticWeaponModel(UStaticMesh.LoadFromAsset("/rpg/rpg_only"))
	Weapon:SetMeshScale(FVector(10.000000, 10.000000, 10.000000))
	Weapon:SetEquipTime(1.0)
	Weapon:SetUnequipTime(1.0)
	Weapon:SetAimWalkSpeed(170.0)
	Weapon:SetCameraAimTargetOffset(FVector(170.000000, 65.000000, 14.000000))
	Weapon:SetCameraAimFoV(65.0)
	Weapon:SetAimBlendTime(0.35)
	Weapon:SetRange(0.0)
	Weapon:SetRecoil(0.5)
	Weapon:SetCameraShake(0.2)
	Weapon:SetCameraShakeCrouching(0.1)
	Weapon:SetSpreadMin(0.1)
	Weapon:SetSpreadMax(4.0)
	Weapon:SetSpreadMovementModifier(0.2)
	Weapon:SetSpreadCrouchingModifier(-0.3)
	Weapon:SetRateOfFire(30.0)
	Weapon:SetMagazineModel(nil)
	Weapon:SetMagazineSize(1)
	Weapon:SetMagazineDropTime(0.32)
	Weapon:SetScope(false)
	Weapon:SetShotSound(nil)
	Weapon:SetShotAnimation(nil)
	Weapon:SetShotAnimationTime(0.5)
	Weapon:SetMuzzleFlash(nil)
	Weapon:SetShellDelay(0.0)
	Weapon:SetProjectileShell(nil)
	Weapon:SetShellSmoke(nil)
	Weapon:SetAttachmentLocationModifier(FVector(-2.5, 6.0, 6.5))
	Weapon:SetAttachmentRotationModifier(FRotator(0.0, -90.0, -10.0))
	Weapon:SetReloadAnimation(nil)
	Weapon:SetReloadAnimationTime(3.0)
	Weapon:SetCharacterReloadAnimation(UAnimSequence.LoadFromAsset("/Game/Character/Animations/Handgun/A_Taser_Reload"))
	Weapon:SetLeftHandIKLocation(FVector(-32.000000, 7.000000, -5.000000))
	Weapon:SetLeftHandARIdleIKLocation(FVector(-32.000000, 10.000000, 5.000000))
	Weapon:SetLeftHandARIdleIKLocationCrouching(FVector(-32.000000, 10.000000, 2.000000))
	Weapon:SetHUDImage(nil)
	Weapon:SetAllowAimWhileCrouching(true)
	Weapon:SetZoomInSound(nil)
	Weapon:SetZoomOutSound(nil)
	Weapon:SetEquipSound(USoundCue.LoadFromAsset("/Game/Character/Sounds/Holster/Equip_Fabric_1_A_Cue"))
	Weapon:SetUnequipSound(USoundCue.LoadFromAsset("/Game/Character/Sounds/Holster/UnEquip_Fabric_1_A_Cue1"))
	Weapon:SetReloadStartSound(nil)
	Weapon:SetReloadEndSound(nil)
	Weapon:SetNoAmmoSound(nil)
    GetWeaponIdentifier():RegisterWeapon(Weapon)
end)