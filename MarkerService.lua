local MarkerService = {}
type FontConfig = Font | Enum.Font | { Family: string, Weight: Enum.FontWeight?, Style: Enum.FontStyle? }

export type MarkerConfig = {
	Text: string?,
	Color: Color3?,
	TextColor: Color3?,
	Size: (UDim2 | Vector2)?,
	FillColor: Color3?,
	OutlineColor: Color3?,
	FillTransparency: number?,
	OutlineTransparency: number?,
	Shape: ("Square" | "Circle")?,
	ShapeIndex: number?,
	LineThickness: number?,
	Transparency: number?,
	TextFont: FontConfig?,
	AddLabel: boolean?,
}

local function GetFont(Config: FontConfig?): Font
	local Default = Font.fromEnum(Enum.Font.Code)

	if not Config then
		return Default
	end

	if typeof(Config) == "Font" then
		return Config
	elseif typeof(Config) == "EnumItem" then
		if Config.EnumType == Enum.Font then
			return Font.fromEnum(Config :: Enum.Font)
		end
	elseif typeof(Config) == "table" then
		local Family = Config.Family or "rbxasset://fonts/families/Inconsolata.json"
		local Weight = Config.Weight or Enum.FontWeight.Regular
		local Style = Config.Style or Enum.FontStyle.Normal
		return Font.new(Family, Weight, Style)
	end

	return Default
end

local function GetRelativeThickness(LineThickness: number, Size: Vector2): number
	local SmallestSide = math.min(Size.X, Size.Y)
	if SmallestSide > 0 then
		return LineThickness / SmallestSide
	end
	return LineThickness
end

local function CreateBaseBillboard(Target: Instance, Size: UDim2): BillboardGui
	local Billboard = Instance.new("BillboardGui")
	Billboard.Size = Size
	Billboard.AlwaysOnTop = true
	Billboard.MaxDistance = math.huge
	Billboard.Adornee = Target
	Billboard.Parent = Target
	return Billboard
end

function MarkerService.AddLabel(Target: Instance, Configs: MarkerConfig): TextLabel
	local Text = Configs.Text or "Label"
	local Color = Configs.TextColor or Configs.Color or Color3.new(1, 1, 1)
	local Size = (typeof(Configs.Size) == "UDim2" and Configs.Size) or UDim2.new(4, 0, 1, 0)

	local Billboard = CreateBaseBillboard(Target, Size)

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.fromScale(1, 1)
	Label.BackgroundTransparency = 1
	Label.Text = Text
	Label.TextColor3 = Color
	Label.TextScaled = true
	Label.FontFace = GetFont(Configs.TextFont)
	Label.Parent = Billboard

	return Label
end

function MarkerService.AddHighlight(Target: Instance, Configs: MarkerConfig): Highlight
	local Highlight = Instance.new("Highlight")
	Highlight.Adornee = Target
	Highlight.FillColor = Configs.FillColor or Color3.new(1, 1, 1)
	Highlight.OutlineColor = Configs.OutlineColor or Color3.new(1, 1, 1)
	Highlight.FillTransparency = Configs.FillTransparency or 0.5
	Highlight.OutlineTransparency = Configs.OutlineTransparency or 0
	Highlight.Parent = Target

	return Highlight
end

function MarkerService.AddShapeOutline(Target: Instance, Configs: MarkerConfig): (Frame, BillboardGui)
	local Shape = Configs.Shape or "Square"
	local Color = Configs.Color or Color3.new(1, 1, 1)
	local LineThickness = Configs.LineThickness or 3
	local Size = (typeof(Configs.Size) == "Vector2" and Configs.Size) or Vector2.new(4, 4)

	local Billboard = CreateBaseBillboard(Target, UDim2.new(Size.X, 0, Size.Y, 0))

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.BackgroundTransparency = 1
	Frame.Parent = Billboard

	if Shape == "Circle" then
		local UiCorner = Instance.new("UICorner")
		UiCorner.CornerRadius = UDim.new(1, 0)
		UiCorner.Parent = Frame
	end

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = GetRelativeThickness(LineThickness, Size)
	Stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	Stroke.LineJoinMode = Enum.LineJoinMode.Round
	Stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	Stroke.Color = Color
	Stroke.Parent = Frame

	return Frame, Billboard
end

function MarkerService.Add3DShape(Target: Instance, Configs: MarkerConfig): HandleAdornment
	local ShapeIndex = Configs.ShapeIndex or 1
	local Color = Configs.Color or Color3.new(0, 1, 0)
	local Transparency = Configs.Transparency or 0.5
	local Size = Configs.Size or Target.Size

	local Shapes = {
		[1] = "BoxHandleAdornment",
		[2] = "SphereHandleAdornment",
		[3] = "CylinderHandleAdornment",
	}

	local ClassName = Shapes[ShapeIndex] or "BoxHandleAdornment"
	local ShapeObj = Instance.new(ClassName) :: any

	if Target:IsA("BasePart") then
		if ClassName == "BoxHandleAdornment" then
			ShapeObj.Size = Size
		elseif ClassName == "SphereHandleAdornment" then
			ShapeObj.Radius = math.min(Size.X, Size.Y, Size.Z) / 2
		elseif ClassName == "CylinderHandleAdornment" then
			ShapeObj.Height = Size.Y
			ShapeObj.Radius = math.min(Size.X, Size.Z) / 2
		end
	else
		if ClassName == "BoxHandleAdornment" then
			ShapeObj.Size = Vector3.new(2, 2, 2)
		elseif ClassName == "CylinderHandleAdornment" then
			ShapeObj.Height = 2
			ShapeObj.Radius = 1
		else
			ShapeObj.Radius = 1
		end
	end

	ShapeObj.Color3 = Color
	ShapeObj.AlwaysOnTop = true
	ShapeObj.Adornee = Target
	ShapeObj.Transparency = Transparency
	ShapeObj.ZIndex = 5
	ShapeObj.Parent = Target

	return ShapeObj
end

function MarkerService.AddSurfaceOutline(Target: Instance, Configs: MarkerConfig): (Part, SurfaceGui)
	local Size = (typeof(Configs.Size) == "Vector2" and Configs.Size) or Vector2.new(4, 4)
	local Color = Configs.Color or Color3.new(1, 1, 1)
	local LineThickness = Configs.LineThickness or 3

	local ThinPart = Instance.new("Part")
	ThinPart.Size = Vector3.new(Size.X, Size.Y, 0.01)
	ThinPart.Transparency = 1
	ThinPart.Anchored = true
	ThinPart.CanCollide = false
	ThinPart.CanQuery = false
	ThinPart.CastShadow = false

	if Target:IsA("BasePart") then
		ThinPart.CFrame = Target.CFrame
	end
	ThinPart.Parent = Target

	local SurfaceGui = Instance.new("SurfaceGui")
	SurfaceGui.AlwaysOnTop = true
	SurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	SurfaceGui.PixelsPerStud = 50
	SurfaceGui.Adornee = ThinPart
	SurfaceGui.Parent = ThinPart

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.BackgroundTransparency = 1
	Frame.Parent = SurfaceGui

	if Configs.Shape == "Circle" then
		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(1, 0)
		Corner.Parent = Frame
	end

	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = GetRelativeThickness(LineThickness, Size)
	Stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	Stroke.LineJoinMode = Enum.LineJoinMode.Round
	Stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	Stroke.Color = Color
	Stroke.Parent = Frame

	if Configs.AddLabel then
		local Label = Instance.new("TextLabel")
		Label.Size = UDim2.fromScale(0.8, 0.4)
		Label.Position = UDim2.fromScale(0.5, 0.5)
		Label.AnchorPoint = Vector2.new(0.5, 0.5)
		Label.BackgroundTransparency = 1
		Label.Text = Configs.Text or "Marker"
		Label.TextColor3 = Configs.TextColor or Color
		Label.TextScaled = true
		Label.FontFace = GetFont(Configs.TextFont)
		Label.Parent = Frame
	end

	return ThinPart, SurfaceGui
end

function MarkerService.AddLine(From: Vector3, To: Vector3, Color: Color3, Transparency: number, Thickness: number, Parent: Instance): Part
	local Line = Instance.new("Part")
	Line.Name = "MarkerLine"
	Line.Anchored = true
	Line.CanCollide = false
	Line.CanQuery = false
	Line.CastShadow = false
	Line.Material = Enum.Material.Neon
	Line.Color = Color
	Line.Transparency = Transparency

	MarkerService.UpdateLine(Line, From, To, Thickness)

	Line.Parent = Parent
	return Line
end

function MarkerService.UpdateLine(Line: Part, From: Vector3, To: Vector3, Thickness: number?)
	local Direction = To - From
	local Distance = Direction.Magnitude
	if Distance < 0.001 then
		Line.Size = Vector3.zero
		return
	end

	local CurrentThickness = math.max(0.005, Thickness or Line.Size.X)
	Line.Size = Vector3.new(CurrentThickness, CurrentThickness, Distance)
	Line.CFrame = CFrame.lookAt((From + To) * 0.5, To)
end

return MarkerService
