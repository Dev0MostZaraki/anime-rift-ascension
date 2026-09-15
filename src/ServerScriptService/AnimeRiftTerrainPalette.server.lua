local Workspace = game:GetService("Workspace")

local terrain = Workspace.Terrain

local palette = {
	[Enum.Material.Grass] = Color3.fromRGB(84, 121, 78),
	[Enum.Material.Ground] = Color3.fromRGB(118, 99, 78),
	[Enum.Material.Mud] = Color3.fromRGB(91, 74, 67),
	[Enum.Material.Rock] = Color3.fromRGB(91, 91, 99),
	[Enum.Material.Slate] = Color3.fromRGB(75, 76, 91),
	[Enum.Material.Cobblestone] = Color3.fromRGB(103, 101, 111),
	[Enum.Material.Basalt] = Color3.fromRGB(55, 48, 67),
	[Enum.Material.Snow] = Color3.fromRGB(220, 232, 239),
	[Enum.Material.Ice] = Color3.fromRGB(155, 211, 230),
	[Enum.Material.Sand] = Color3.fromRGB(177, 150, 112),
}

for material, color in pairs(palette) do
	pcall(function()
		terrain:SetMaterialColor(material, color)
	end)
end

terrain.Decoration = true
terrain.WaterColor = Color3.fromRGB(58, 130, 153)
terrain.WaterTransparency = 0.26
terrain.WaterReflectance = 0.22
terrain.WaterWaveSize = 0.12
terrain.WaterWaveSpeed = 7

print("[TerrainPalette] cohesive world palette active")
