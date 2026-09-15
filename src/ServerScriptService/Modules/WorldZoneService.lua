local ServerScriptService = game:GetService("ServerScriptService")

local WorldZoneService = {}
WorldZoneService.__index = WorldZoneService

function WorldZoneService.new(context)
	return setmetatable({
		Context = context,
		Zones = {},
		SafeCounts = {},
		Enabled = false,
	}, WorldZoneService)
end

local function volume(parent, name, center, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(center)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Transparency = 1
	part.Parent = parent
	return part
end

function WorldZoneService:GetZoneModule()
	local packages = ServerScriptService:FindFirstChild("Packages")
	local module = packages and packages:FindFirstChild("ZonePlus")
	if not module then return nil end
	local ok, result = pcall(require, module)
	if ok then return result end
	warn("[World Zones] ZonePlus require failed:", result)
	return nil
end

function WorldZoneService:BindRegion(Zone, folder, name, center, size, color)
	local detector = volume(folder, "Region_" .. string.gsub(name, "%s+", ""), center, size)
	local zone = Zone.new(detector)
	table.insert(self.Zones, zone)
	zone.playerEntered:Connect(function(player)
		if player:GetAttribute("OpenWorldRegion") ~= name then
			player:SetAttribute("OpenWorldRegion", name)
			self.Context.Remotes.ZoneEntered:FireClient(player, name, color)
		end
	end)
	zone.playerExited:Connect(function(player)
		if player:GetAttribute("OpenWorldRegion") == name then
			player:SetAttribute("OpenWorldRegion", nil)
		end
	end)
end

function WorldZoneService:BindSanctuary(Zone, folder, zoneId, center)
	local radius = self.Context.Config.Game.EggSanctuaryRadius or 26
	local detector = volume(folder, "HatcherySafeZone_" .. zoneId, center + Vector3.new(0, 16, 0), Vector3.new(radius * 2, 36, radius * 2))
	local zone = Zone.new(detector)
	table.insert(self.Zones, zone)
	zone.playerEntered:Connect(function(player)
		local count = (self.SafeCounts[player] or 0) + 1
		self.SafeCounts[player] = count
		player:SetAttribute("InHatcherySafeZone", true)
	end)
	zone.playerExited:Connect(function(player)
		local count = math.max(0, (self.SafeCounts[player] or 1) - 1)
		self.SafeCounts[player] = count
		player:SetAttribute("InHatcherySafeZone", count > 0)
	end)
end

function WorldZoneService:Start()
	local Zone = self:GetZoneModule()
	if not Zone then
		warn("[World Zones] ZonePlus unavailable; existing distance checks remain active. Run `wally install`.")
		return
	end
	local old = self.Context.WorldFolder:FindFirstChild("ZoneVolumes")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "ZoneVolumes"
	folder.Parent = self.Context.WorldFolder

	self:BindRegion(Zone, folder, "Rift Haven", Vector3.new(0, 20, 0), Vector3.new(176, 70, 176), Color3.fromRGB(139, 125, 104))
	for _, zoneData in ipairs(self.Context.Config.Zones) do
		self:BindRegion(Zone, folder, zoneData.Name, zoneData.Center + Vector3.new(0, 20, 0), Vector3.new(224, 76, 224), zoneData.Color)
		local sanctuary = self.Context.Services.OpenWorldSliceService:GetEggSanctuaryPosition(zoneData.Id)
		if sanctuary then self:BindSanctuary(Zone, folder, zoneData.Id, sanctuary) end
	end

	self.Enabled = true
	self.Context.WorldZonesActive = true
	print("[World Zones] ZonePlus active • regions + hatchery sanctuaries")
end

return WorldZoneService
