local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("AnimeRiftHUD", 25)
if not gui then return end

local function waitChild(name, seconds)
	return gui:FindFirstChild(name) or gui:WaitForChild(name, seconds or 12)
end

local function setStroke(frame, transparency)
	local stroke = frame and frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = transparency
		stroke.Thickness = 1
	end
end

local combat = waitChild("CombatBar", 15)
if combat and combat:IsA("Frame") then
	combat.Size = UDim2.new(0, 456, 0, 60)
	combat.Position = UDim2.new(0.5, 0, 1, -14)
	combat.BackgroundTransparency = 0.16
	setStroke(combat, 0.58)

	local names = {"DASH", "RIFT BURST", "RIFT NOVA"}
	for index, name in ipairs(names) do
		local button = combat:FindFirstChild(name)
		if button and button:IsA("TextButton") then
			button.Size = UDim2.new(0, 140, 0, 40)
			button.Position = UDim2.new(0, 8 + (index - 1) * 150, 0, 11)
			button.BackgroundTransparency = 0.12
			setStroke(button, 0.62)

			local accent = button:FindFirstChild("Accent")
			if accent then
				accent.Size = UDim2.new(0, 3, 1, -10)
				accent.Position = UDim2.new(0, 5, 0, 5)
			end
			for _, child in ipairs(button:GetChildren()) do
				if child:IsA("TextLabel") then
					if child.Name == "Cooldown" then
						child.TextSize = 16
					elseif child.Text == "Q" or child.Text == "E" or child.Text == "R" then
						child.Size = UDim2.new(0, 28, 0, 28)
						child.Position = UDim2.new(0, 14, 0.5, -14)
						child.TextSize = 14
					else
						child.Position = UDim2.new(0, 50, 0, 0)
						child.Size = UDim2.new(1, -56, 1, 0)
						child.TextSize = 10
					end
				end
			end
		end
	end

	for _, child in ipairs(combat:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text, "STYLE //") then
			child.Size = UDim2.new(0, 230, 0, 20)
			child.Position = UDim2.new(0.5, 0, 0, -5)
			child.BackgroundTransparency = 0.24
			child.TextSize = 9
		end
	end
end

local assists = waitChild("FighterAssistBar", 15)
if assists and assists:IsA("Frame") then
	assists.Size = UDim2.new(0, 500, 0, 57)
	assists.Position = UDim2.new(0.5, 0, 1, -76)
	assists.BackgroundTransparency = 0.22
	setStroke(assists, 0.66)

	for slot = 1, 3 do
		local button = assists:FindFirstChild("Assist" .. slot)
		if button and button:IsA("TextButton") then
			button.Size = UDim2.new(0, 155, 0, 38)
			button.Position = UDim2.new(0, 10 + (slot - 1) * 164, 0, 15)
			button.BackgroundTransparency = 0.14
			setStroke(button, 0.66)
			for _, child in ipairs(button:GetChildren()) do
				if child:IsA("Frame") and child.Size.X.Offset == 32 then
					child.Size = UDim2.new(0, 28, 0, 28)
					child.Position = UDim2.new(0, 6, 0, 5)
				elseif child:IsA("TextLabel") and child.ZIndex < 5 then
					if child.Position.Y.Offset < 15 then
						child.Position = UDim2.new(0, 40, 0, 3)
						child.Size = UDim2.new(1, -44, 0, 17)
						child.TextSize = 9
					else
						child.Position = UDim2.new(0, 40, 0, 20)
						child.Size = UDim2.new(1, -44, 0, 15)
						child.TextSize = 8
					end
				end
			end
		end
	end

	for _, child in ipairs(assists:GetChildren()) do
		if child:IsA("TextLabel") and child.Text == "FIGHTER ASSISTS" then
			child.Text = "ASSISTS"
			child.Position = UDim2.new(0, 11, 0, 2)
			child.TextSize = 8
		end
	end
end

local legend = gui:FindFirstChild("MinimalLegend")
if legend then legend:Destroy() end

print("[ActionBarPolish] compact action HUD active")
