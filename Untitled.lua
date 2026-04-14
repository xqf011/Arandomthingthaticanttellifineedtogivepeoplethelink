local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Camera           = workspace.CurrentCamera
local isStudio         = RunService:IsStudio()

local function _map(value, inMin, inMax, outMin, outMax)
return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function _viewportPointToWorld(location, distance)
local unitRay = Camera:ScreenPointToRay(location.X, location.Y)
return unitRay.Origin + unitRay.Direction * distance
end

local function _getOffset()
return _map(Camera.ViewportSize.Y, 0, 2560, 8, 56)
end

local function _acrylicSupported()
return getgenv and (
(getgenv().NoAnticheat == nil and true or getgenv().NoAnticheat)
or not getgenv().SecureMode
) or isStudio
end

local function _createAcrylicPart()
if not _acrylicSupported() then return nil end
local part = Instance.new("Part")
part.Name         = "PrestigeUIBlur"
part.Color        = Color3.new(0, 0, 0)
part.Material     = Enum.Material.Glass
part.Size         = Vector3.new(1.04, 1.12, 0)
part.Anchored     = true
part.CanCollide   = false
part.Locked       = true
part.CastShadow   = false
part.Transparency = 0.98
local mesh = Instance.new("SpecialMesh")
mesh.MeshType = Enum.MeshType.Brick
mesh.Offset   = Vector3.new(0, 0, -0.000001)
mesh.Parent   = part
return part
end

local function _initDOF()
if not _acrylicSupported() then return end
local existing
for _, v in ipairs(Lighting:GetChildren()) do
if v:IsA("DepthOfFieldEffect") and v.Name ~= "PrestigeUIBlur" then
existing = v
break
end
end
if not existing then
existing = Instance.new("DepthOfFieldEffect")
existing.FarIntensity  = 0
existing.NearIntensity = 0
existing.FocusDistance = 500
existing.InFocusRadius = 500
existing.Enabled       = true
existing.Parent        = Lighting
end
local blurDOF = Lighting:FindFirstChild("PrestigeUIBlur")
if not blurDOF then
blurDOF = existing:Clone()
blurDOF.Name          = "PrestigeUIBlur"
blurDOF.NearIntensity = 1
blurDOF.Parent        = Lighting
end
local function sync()
blurDOF.FarIntensity  = existing.FarIntensity
blurDOF.FocusDistance = existing.FocusDistance
blurDOF.InFocusRadius = existing.InFocusRadius
end
existing:GetPropertyChangedSignal("FarIntensity"):Connect(sync)
existing:GetPropertyChangedSignal("FocusDistance"):Connect(sync)
existing:GetPropertyChangedSignal("InFocusRadius"):Connect(sync)
end

local function _getBlurFolder()
local folder = Camera:FindFirstChild("PrestigeUI Blur Elements")
if not folder then
folder = Instance.new("Folder")
folder.Name   = "PrestigeUI Blur Elements"
folder.Parent = Camera
end
return folder
end

local function createAcrylicComponent(parentFrame, windowBg)
if not _acrylicSupported() then return nil end
_initDOF()
local part = _createAcrylicPart()
if not part then return nil end
part.Color  = windowBg or Color3.fromRGB(28, 28, 28)
part.Parent = _getBlurFolder()
local mesh     = part:FindFirstChildWhichIsA("SpecialMesh")
local cleanups = {}
local positions = {
topLeft     = Vector2.new(),
topRight    = Vector2.new(),
bottomRight = Vector2.new(),
}
local function updatePositions(size, position)
positions.topLeft     = position
positions.topRight    = position + Vector2.new(size.X, 0)
positions.bottomRight = position + size
end
local function render()
local cam = workspace.CurrentCamera
if not cam then return end
local cf = cam.CFrame
local tl = _viewportPointToWorld(positions.topLeft,     0.001)
local tr = _viewportPointToWorld(positions.topRight,    0.001)
local br = _viewportPointToWorld(positions.bottomRight, 0.001)
local w  = (tr - tl).Magnitude
local h  = (tr - br).Magnitude
part.CFrame = CFrame.fromMatrix((tl + br) / 2, cf.XVector, cf.YVector, cf.ZVector)
if mesh then mesh.Scale = Vector3.new(w, h, 0) end
end
local function onChange()
local offset   = _getOffset()
local abs      = parentFrame.AbsoluteSize
local absPos   = parentFrame.AbsolutePosition
local size     = abs    - Vector2.new(offset, offset)
local position = absPos + Vector2.new(offset / 2, offset / 2)
updatePositions(size, position)
task.spawn(render)
end
local function hookCamera()
local cam = workspace.CurrentCamera
if not cam then return end
cleanups[#cleanups+1] = cam:GetPropertyChangedSignal("CFrame"):Connect(render)
cleanups[#cleanups+1] = cam:GetPropertyChangedSignal("ViewportSize"):Connect(render)
cleanups[#cleanups+1] = cam:GetPropertyChangedSignal("FieldOfView"):Connect(render)
task.spawn(render)
end
cleanups[#cleanups+1] = parentFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(onChange)
cleanups[#cleanups+1] = parentFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(onChange)
part.Destroying:Connect(function()
for _, c in ipairs(cleanups) do pcall(function() c:Disconnect() end) end
end)
hookCamera()
task.spawn(onChange)
local acrylicFrame = Instance.new("Frame")
acrylicFrame.Name                   = "AcrylicLayer"
acrylicFrame.Size                   = UDim2.fromScale(1, 1)
acrylicFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
acrylicFrame.BackgroundTransparency = 0.88
acrylicFrame.BorderSizePixel        = 0
acrylicFrame.ZIndex                 = 0
local shadow = Instance.new("ImageLabel")
shadow.Image              = "rbxassetid://8992230677"
shadow.ScaleType          = Enum.ScaleType.Slice
shadow.SliceCenter        = Rect.new(99, 99, 99, 99)
shadow.AnchorPoint        = Vector2.new(0.5, 0.5)
shadow.Size               = UDim2.new(1, 140, 1, 130)
shadow.Position           = UDim2.new(0.5, 0, 0.5, 0)
shadow.BackgroundTransparency = 1
shadow.ImageColor3        = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency  = 0.55
shadow.Name               = "Shadow"
shadow.ZIndex             = 0
shadow.Parent             = acrylicFrame
local tint = Instance.new("ImageLabel")
tint.Image              = "rbxassetid://9968344105"
tint.ImageTransparency  = 0.65
tint.ImageColor3        = Color3.fromRGB(20, 20, 30)
tint.ScaleType          = Enum.ScaleType.Tile
tint.TileSize           = UDim2.new(0, 128, 0, 128)
tint.Size               = UDim2.fromScale(1, 1)
tint.BackgroundTransparency = 1
tint.Name               = "Tint"
tint.ZIndex             = 0
tint.Parent             = acrylicFrame
local noise = Instance.new("ImageLabel")
noise.Image             = "rbxassetid://9968344227"
noise.ImageTransparency = 0.60
noise.ScaleType         = Enum.ScaleType.Tile
noise.TileSize          = UDim2.new(0, 128, 0, 128)
noise.Size              = UDim2.fromScale(1, 1)
noise.BackgroundTransparency = 1
noise.Name              = "Noise"
noise.ZIndex            = 0
noise.Parent            = acrylicFrame
local highlight = Instance.new("Frame")
highlight.Name               = "GlassHighlight"
highlight.Size               = UDim2.new(1, 0, 0, 1)
highlight.Position           = UDim2.new(0, 0, 0, 0)
highlight.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
highlight.BackgroundTransparency = 0.7
highlight.BorderSizePixel    = 0
highlight.ZIndex             = 1
highlight.Parent             = acrylicFrame
acrylicFrame.Parent = parentFrame
local function setVisible(v)
pcall(function() part.Transparency = v and 0.98 or 1 end)
acrylicFrame.Visible = v
end
return {
Frame      = acrylicFrame,
Part       = part,
SetVisible = setVisible,
Destroy    = function()
pcall(function() part:Destroy() end)
pcall(function() acrylicFrame:Destroy() end)
end,
}
end

local LucideIcons = nil
local function getLucide()
if LucideIcons then return LucideIcons end
local ok, result = pcall(function()
return loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/LucideIcons.luau"
))()
end)
if ok then LucideIcons = result end
return LucideIcons
end

local function iconAsset(name)
if not name or name == "" then return nil end
local lib = getLucide()
if not lib then return nil end
local id = lib[name]
if not id then return nil end
return "rbxassetid://" .. tostring(id)
end

local Themes = {
Ocean = {
WindowBg      = Color3.fromRGB(12,  22,  34),
WindowBorder  = Color3.fromRGB(25,  48,  72),
TitleBg       = Color3.fromRGB(8,   16,  28),
TitleBorder   = Color3.fromRGB(20,  42,  64),
SidebarBg     = Color3.fromRGB(10,  19,  31),
SidebarBorder = Color3.fromRGB(20,  42,  64),
TabNormal     = Color3.fromRGB(10,  19,  31),
TabHover      = Color3.fromRGB(18,  36,  56),
TabActive     = Color3.fromRGB(0,   168, 204),
TabNormalText = Color3.fromRGB(100, 150, 185),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(14,  26,  40),
Surface       = Color3.fromRGB(18,  36,  56),
SurfaceHover  = Color3.fromRGB(24,  48,  70),
SurfaceActive = Color3.fromRGB(30,  58,  84),
Primary       = Color3.fromRGB(0,   168, 204),
PrimaryHover  = Color3.fromRGB(30,  195, 230),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(22,  46,  68),
BorderFocus   = Color3.fromRGB(0,   168, 204),
TextPrimary   = Color3.fromRGB(200, 225, 240),
TextSecondary = Color3.fromRGB(100, 150, 185),
TextMuted     = Color3.fromRGB(50,  88,  120),
Success       = Color3.fromRGB(40,  200, 130),
Warning       = Color3.fromRGB(255, 195, 60),
Error         = Color3.fromRGB(220, 70,  80),
Info          = Color3.fromRGB(0,   168, 204),
ScrollBar     = Color3.fromRGB(30,  65,  95),
ToggleOn      = Color3.fromRGB(0,   168, 204),
ToggleOff     = Color3.fromRGB(20,  42,  64),
IconTint      = Color3.fromRGB(100, 150, 185),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Nebula = {
WindowBg      = Color3.fromRGB(14,  10,  28),
WindowBorder  = Color3.fromRGB(48,  28,  80),
TitleBg       = Color3.fromRGB(10,  6,   22),
TitleBorder   = Color3.fromRGB(42,  22,  70),
SidebarBg     = Color3.fromRGB(12,  8,   25),
SidebarBorder = Color3.fromRGB(42,  22,  70),
TabNormal     = Color3.fromRGB(12,  8,   25),
TabHover      = Color3.fromRGB(28,  16,  52),
TabActive     = Color3.fromRGB(168, 60,  220),
TabNormalText = Color3.fromRGB(140, 100, 185),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(16,  12,  32),
Surface       = Color3.fromRGB(24,  16,  44),
SurfaceHover  = Color3.fromRGB(34,  22,  58),
SurfaceActive = Color3.fromRGB(42,  28,  70),
Primary       = Color3.fromRGB(168, 60,  220),
PrimaryHover  = Color3.fromRGB(195, 90,  248),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(44,  24,  76),
BorderFocus   = Color3.fromRGB(168, 60,  220),
TextPrimary   = Color3.fromRGB(230, 210, 255),
TextSecondary = Color3.fromRGB(150, 110, 200),
TextMuted     = Color3.fromRGB(80,  55,  120),
Success       = Color3.fromRGB(60,  220, 140),
Warning       = Color3.fromRGB(255, 195, 60),
Error         = Color3.fromRGB(220, 60,  90),
Info          = Color3.fromRGB(100, 160, 255),
ScrollBar     = Color3.fromRGB(55,  30,  90),
ToggleOn      = Color3.fromRGB(168, 60,  220),
ToggleOff     = Color3.fromRGB(38,  22,  64),
IconTint      = Color3.fromRGB(150, 110, 200),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Sky = {
WindowBg      = Color3.fromRGB(20,  30,  48),
WindowBorder  = Color3.fromRGB(42,  68,  105),
TitleBg       = Color3.fromRGB(14,  22,  38),
TitleBorder   = Color3.fromRGB(36,  60,  95),
SidebarBg     = Color3.fromRGB(17,  26,  43),
SidebarBorder = Color3.fromRGB(36,  60,  95),
TabNormal     = Color3.fromRGB(17,  26,  43),
TabHover      = Color3.fromRGB(30,  48,  75),
TabActive     = Color3.fromRGB(80,  160, 255),
TabNormalText = Color3.fromRGB(110, 148, 195),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(22,  34,  54),
Surface       = Color3.fromRGB(30,  46,  72),
SurfaceHover  = Color3.fromRGB(38,  58,  88),
SurfaceActive = Color3.fromRGB(46,  70,  105),
Primary       = Color3.fromRGB(80,  160, 255),
PrimaryHover  = Color3.fromRGB(110, 185, 255),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(40,  65,  100),
BorderFocus   = Color3.fromRGB(80,  160, 255),
TextPrimary   = Color3.fromRGB(210, 228, 252),
TextSecondary = Color3.fromRGB(120, 158, 210),
TextMuted     = Color3.fromRGB(60,  90,  135),
Success       = Color3.fromRGB(50,  210, 130),
Warning       = Color3.fromRGB(255, 200, 60),
Error         = Color3.fromRGB(220, 65,  80),
Info          = Color3.fromRGB(80,  160, 255),
ScrollBar     = Color3.fromRGB(48,  78,  118),
ToggleOn      = Color3.fromRGB(80,  160, 255),
ToggleOff     = Color3.fromRGB(34,  55,  85),
IconTint      = Color3.fromRGB(120, 158, 210),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Sunset = {
WindowBg      = Color3.fromRGB(28,  16,  20),
WindowBorder  = Color3.fromRGB(70,  32,  40),
TitleBg       = Color3.fromRGB(20,  10,  14),
TitleBorder   = Color3.fromRGB(62,  26,  34),
SidebarBg     = Color3.fromRGB(24,  13,  17),
SidebarBorder = Color3.fromRGB(62,  26,  34),
TabNormal     = Color3.fromRGB(24,  13,  17),
TabHover      = Color3.fromRGB(48,  24,  30),
TabActive     = Color3.fromRGB(255, 90,  60),
TabNormalText = Color3.fromRGB(185, 120, 120),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(30,  18,  22),
Surface       = Color3.fromRGB(42,  24,  28),
SurfaceHover  = Color3.fromRGB(55,  30,  36),
SurfaceActive = Color3.fromRGB(66,  36,  42),
Primary       = Color3.fromRGB(255, 90,  60),
PrimaryHover  = Color3.fromRGB(255, 120, 80),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(65,  30,  38),
BorderFocus   = Color3.fromRGB(255, 90,  60),
TextPrimary   = Color3.fromRGB(255, 230, 220),
TextSecondary = Color3.fromRGB(195, 140, 130),
TextMuted     = Color3.fromRGB(110, 65,  70),
Success       = Color3.fromRGB(50,  200, 120),
Warning       = Color3.fromRGB(255, 195, 55),
Error         = Color3.fromRGB(220, 50,  60),
Info          = Color3.fromRGB(80,  160, 255),
ScrollBar     = Color3.fromRGB(75,  38,  44),
ToggleOn      = Color3.fromRGB(255, 90,  60),
ToggleOff     = Color3.fromRGB(55,  28,  34),
IconTint      = Color3.fromRGB(195, 140, 130),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Forest = {
WindowBg      = Color3.fromRGB(14,  22,  16),
WindowBorder  = Color3.fromRGB(30,  52,  34),
TitleBg       = Color3.fromRGB(10,  16,  12),
TitleBorder   = Color3.fromRGB(26,  46,  30),
SidebarBg     = Color3.fromRGB(12,  19,  14),
SidebarBorder = Color3.fromRGB(26,  46,  30),
TabNormal     = Color3.fromRGB(12,  19,  14),
TabHover      = Color3.fromRGB(22,  38,  25),
TabActive     = Color3.fromRGB(60,  190, 90),
TabNormalText = Color3.fromRGB(100, 150, 110),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(16,  26,  18),
Surface       = Color3.fromRGB(22,  38,  25),
SurfaceHover  = Color3.fromRGB(28,  50,  32),
SurfaceActive = Color3.fromRGB(34,  60,  38),
Primary       = Color3.fromRGB(60,  190, 90),
PrimaryHover  = Color3.fromRGB(85,  215, 115),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(28,  50,  32),
BorderFocus   = Color3.fromRGB(60,  190, 90),
TextPrimary   = Color3.fromRGB(205, 235, 210),
TextSecondary = Color3.fromRGB(110, 160, 118),
TextMuted     = Color3.fromRGB(55,  90,  62),
Success       = Color3.fromRGB(60,  190, 90),
Warning       = Color3.fromRGB(200, 185, 60),
Error         = Color3.fromRGB(200, 60,  70),
Info          = Color3.fromRGB(60,  160, 200),
ScrollBar     = Color3.fromRGB(34,  65,  40),
ToggleOn      = Color3.fromRGB(60,  190, 90),
ToggleOff     = Color3.fromRGB(26,  46,  30),
IconTint      = Color3.fromRGB(110, 160, 118),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Midnight = {
WindowBg      = Color3.fromRGB(10,  10,  18),
WindowBorder  = Color3.fromRGB(28,  28,  50),
TitleBg       = Color3.fromRGB(6,   6,   14),
TitleBorder   = Color3.fromRGB(24,  24,  44),
SidebarBg     = Color3.fromRGB(8,   8,   16),
SidebarBorder = Color3.fromRGB(24,  24,  44),
TabNormal     = Color3.fromRGB(8,   8,   16),
TabHover      = Color3.fromRGB(18,  18,  34),
TabActive     = Color3.fromRGB(110, 110, 255),
TabNormalText = Color3.fromRGB(110, 110, 160),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(12,  12,  22),
Surface       = Color3.fromRGB(18,  18,  34),
SurfaceHover  = Color3.fromRGB(24,  24,  44),
SurfaceActive = Color3.fromRGB(30,  30,  54),
Primary       = Color3.fromRGB(110, 110, 255),
PrimaryHover  = Color3.fromRGB(140, 140, 255),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(26,  26,  48),
BorderFocus   = Color3.fromRGB(110, 110, 255),
TextPrimary   = Color3.fromRGB(215, 215, 240),
TextSecondary = Color3.fromRGB(120, 120, 175),
TextMuted     = Color3.fromRGB(60,  60,  100),
Success       = Color3.fromRGB(60,  210, 130),
Warning       = Color3.fromRGB(240, 195, 60),
Error         = Color3.fromRGB(220, 60,  85),
Info          = Color3.fromRGB(110, 110, 255),
ScrollBar     = Color3.fromRGB(34,  34,  65),
ToggleOn      = Color3.fromRGB(110, 110, 255),
ToggleOff     = Color3.fromRGB(24,  24,  46),
IconTint      = Color3.fromRGB(120, 120, 175),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Rose = {
WindowBg      = Color3.fromRGB(28,  14,  22),
WindowBorder  = Color3.fromRGB(65,  30,  50),
TitleBg       = Color3.fromRGB(20,  8,   16),
TitleBorder   = Color3.fromRGB(58,  24,  44),
SidebarBg     = Color3.fromRGB(24,  11,  19),
SidebarBorder = Color3.fromRGB(58,  24,  44),
TabNormal     = Color3.fromRGB(24,  11,  19),
TabHover      = Color3.fromRGB(44,  20,  34),
TabActive     = Color3.fromRGB(240, 80,  140),
TabNormalText = Color3.fromRGB(185, 110, 150),
TabActiveText = Color3.fromRGB(255, 255, 255),
ContentBg     = Color3.fromRGB(30,  15,  24),
Surface       = Color3.fromRGB(40,  20,  32),
SurfaceHover  = Color3.fromRGB(52,  26,  42),
SurfaceActive = Color3.fromRGB(62,  32,  50),
Primary       = Color3.fromRGB(240, 80,  140),
PrimaryHover  = Color3.fromRGB(255, 110, 165),
PrimaryText   = Color3.fromRGB(255, 255, 255),
Border        = Color3.fromRGB(60,  26,  46),
BorderFocus   = Color3.fromRGB(240, 80,  140),
TextPrimary   = Color3.fromRGB(255, 220, 238),
TextSecondary = Color3.fromRGB(195, 130, 165),
TextMuted     = Color3.fromRGB(110, 65,  90),
Success       = Color3.fromRGB(55,  205, 125),
Warning       = Color3.fromRGB(255, 195, 60),
Error         = Color3.fromRGB(220, 55,  70),
Info          = Color3.fromRGB(90,  155, 255),
ScrollBar     = Color3.fromRGB(70,  30,  55),
ToggleOn      = Color3.fromRGB(240, 80,  140),
ToggleOff     = Color3.fromRGB(50,  22,  40),
IconTint      = Color3.fromRGB(195, 130, 165),
IconTintActive= Color3.fromRGB(255, 255, 255),
},
Gold = {
WindowBg      = Color3.fromRGB(22,  18,  8),
WindowBorder  = Color3.fromRGB(60,  46,  14),
TitleBg       = Color3.fromRGB(16,  12,  4),
TitleBorder   = Color3.fromRGB(54,  40,  10),
SidebarBg     = Color3.fromRGB(19,  15,  6),
SidebarBorder = Color3.fromRGB(54,  40,  10),
TabNormal     = Color3.fromRGB(19,  15,  6),
TabHover      = Color3.fromRGB(38,  28,  10),
TabActive     = Color3.fromRGB(220, 175, 40),
TabNormalText = Color3.fromRGB(170, 145, 80),
TabActiveText = Color3.fromRGB(20,  16,  4),
ContentBg     = Color3.fromRGB(24,  20,  8),
Surface       = Color3.fromRGB(34,  26,  10),
SurfaceHover  = Color3.fromRGB(46,  35,  14),
SurfaceActive = Color3.fromRGB(56,  43,  16),
Primary       = Color3.fromRGB(220, 175, 40),
PrimaryHover  = Color3.fromRGB(245, 200, 65),
PrimaryText   = Color3.fromRGB(20,  16,  4),
Border        = Color3.fromRGB(56,  42,  12),
BorderFocus   = Color3.fromRGB(220, 175, 40),
TextPrimary   = Color3.fromRGB(252, 238, 185),
TextSecondary = Color3.fromRGB(175, 150, 90),
TextMuted     = Color3.fromRGB(100, 82,  40),
Success       = Color3.fromRGB(55,  195, 115),
Warning       = Color3.fromRGB(220, 175, 40),
Error         = Color3.fromRGB(215, 60,  70),
Info          = Color3.fromRGB(75,  155, 240),
ScrollBar     = Color3.fromRGB(65,  50,  18),
ToggleOn      = Color3.fromRGB(220, 175, 40),
ToggleOff     = Color3.fromRGB(44,  34,  12),
IconTint      = Color3.fromRGB(175, 150, 90),
IconTintActive= Color3.fromRGB(20,  16,  4),
},
}
local T = {}
for k, v in pairs(Themes.Ocean) do T[k] = v end

local _themeListeners = {}
local function _onThemeChange(fn)
table.insert(_themeListeners, fn)
end
local function applyTheme(name)
local theme = Themes[name]
if not theme then return end
for k, v in pairs(theme) do T[k] = v end
for _, fn in ipairs(_themeListeners) do
pcall(fn, T)
end
end

local function inst(class, props)
local o = Instance.new(class)
for k, v in pairs(props) do o[k] = v end
return o
end

local function corner(p, r)
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, r or 6)
c.Parent = p
return c
end

local function mkStroke(p, col, thick)
local s = Instance.new("UIStroke")
s.Color     = col   or T.Border
s.Thickness = thick or 1
s.Parent    = p
return s
end

local function mkPad(p, t, r, b, l)
local u = Instance.new("UIPadding")
u.PaddingTop    = UDim.new(0, t or 8)
u.PaddingRight  = UDim.new(0, r or 8)
u.PaddingBottom = UDim.new(0, b or 8)
u.PaddingLeft   = UDim.new(0, l or 8)
u.Parent = p
return u
end

local function tw(obj, info, props)
TweenService:Create(obj, info, props):Play()
end

local fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local med  = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function mkIcon(parent, iconName, size, color, zIndex, anchorPoint, position)
local asset = iconAsset(iconName)
if not asset then return nil end
size        = size        or 16
color       = color       or T.IconTint
zIndex      = zIndex      or 3
anchorPoint = anchorPoint or Vector2.new(0, 0.5)
position    = position    or UDim2.new(0, 0, 0.5, 0)
local img = inst("ImageLabel", {
Size                   = UDim2.new(0, size, 0, size),
AnchorPoint            = anchorPoint,
Position               = position,
BackgroundTransparency = 1,
Image                  = asset,
ImageColor3            = color,
ScaleType              = Enum.ScaleType.Fit,
ZIndex                 = zIndex,
Parent                 = parent,
})
return img
end

local function makeDraggable(frame, handle)
local drag, ds, sp = false, nil, nil
local function onInputBegan(i)
if i.UserInputType == Enum.UserInputType.MouseButton1
or i.UserInputType == Enum.UserInputType.Touch then
drag = true
ds   = i.Position
sp   = frame.Position
end
end
local function onInputEnded(i)
if i.UserInputType == Enum.UserInputType.MouseButton1
or i.UserInputType == Enum.UserInputType.Touch then
drag = false
end
end
local function onInputChanged(i)
if drag and (
i.UserInputType == Enum.UserInputType.MouseMovement
or i.UserInputType == Enum.UserInputType.Touch
) then
local d = i.Position - ds
frame.Position = UDim2.new(
sp.X.Scale, sp.X.Offset + d.X,
sp.Y.Scale, sp.Y.Offset + d.Y
)
end
end
handle.InputBegan:Connect(onInputBegan)
handle.InputEnded:Connect(onInputEnded)
UserInputService.InputChanged:Connect(onInputChanged)
end

local SIDEBAR_W    = 152
local TITLEBAR_H   = 42
local TAB_H        = 38
local TAB_ICON_S   = 15
local TITLE_ICON_S = 16

local PrestigeUI = {}
PrestigeUI.__index = PrestigeUI

function PrestigeUI.new(config)
local self = setmetatable({}, PrestigeUI)
if type(config) == "string" then
config = { Title = config }
end
config = config or {}

local title = config.Title or "PrestigeUI"
local W     = config.Width  or 760
local H     = config.Height or 520

local gui = inst("ScreenGui", {
Name           = "PrestigeUI_" .. title,
ResetOnSpawn   = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
Parent         = Players.LocalPlayer:WaitForChild("PlayerGui"),
})
self.ScreenGui = gui

local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local function applySmartScale()
local vp = workspace.CurrentCamera.ViewportSize
local shortEdge = math.min(vp.X, vp.Y)
local longEdge  = math.max(vp.X, vp.Y)
local isMobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local scale
if isMobile then

local targetW = longEdge * 0.92   
scale = math.clamp(targetW / 760, 0.38, 1.0)
else

scale = math.clamp(math.min(vp.X / 820, vp.Y / 560), 0.55, 1.0)
end
uiScale.Scale = scale
end
applySmartScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applySmartScale)

local useAcrylic  = config.Acrylic == true
local WIN_RADIUS  = 16
local winBgTransp = useAcrylic and 0.52 or 1

local win = inst("CanvasGroup", {
Name                   = "Window",
Size                   = UDim2.new(0, W, 0, 0),
Position               = UDim2.new(0.5, -W/2, 0.5, -H/2),
BackgroundColor3       = T.WindowBg,
BackgroundTransparency = winBgTransp,
BorderSizePixel        = 0,
ZIndex                 = 1,
Parent                 = gui,
})
corner(win, WIN_RADIUS)
mkStroke(win, T.WindowBorder, 1)
self.Window   = win
self._W, self._H = W, H

self._acrylic = nil
if useAcrylic then
local ac = createAcrylicComponent(win, T.WindowBg)
if ac then
self._acrylic  = ac
ac.Frame.ZIndex = 0
end
end

tw(win, med, { Size = UDim2.new(0, W, 0, H), BackgroundTransparency = winBgTransp })

local tb = inst("Frame", {
Name             = "TitleBar",
Size             = UDim2.new(1, 0, 0, TITLEBAR_H),
BackgroundColor3 = T.TitleBg,
BorderSizePixel  = 0,
ZIndex           = 5,
Parent           = win,
})
inst("Frame", {
Size             = UDim2.new(1, 0, 0, 1),
Position         = UDim2.new(0, 0, 1, -1),
BackgroundColor3 = T.TitleBorder,
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = tb,
})

local titleIconW = 0
local iconCfg    = config.Icon
if iconCfg and iconCfg ~= "" then
local asset
if iconCfg:match("^rbxassetid://") then
asset = iconCfg
else
asset = iconAsset(iconCfg)
end
if asset then
inst("ImageLabel", {
Size                   = UDim2.new(0, TITLE_ICON_S, 0, TITLE_ICON_S),
AnchorPoint            = Vector2.new(0, 0.5),
Position               = UDim2.new(0, 14, 0.5, 0),
BackgroundTransparency = 1,
Image                  = asset,
ImageColor3            = T.Primary,
ScaleType              = Enum.ScaleType.Fit,
ZIndex                 = 6,
Parent                 = tb,
})
titleIconW = TITLE_ICON_S + 8
end
end

if titleIconW == 0 then
local dot = inst("Frame", {
Size             = UDim2.new(0, 8, 0, 8),
Position         = UDim2.new(0, 14, 0.5, -4),
BackgroundColor3 = T.Primary,
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = tb,
})
corner(dot, 4)
titleIconW = 8 + 8
end

inst("TextLabel", {
Size                   = UDim2.new(1, -(14 + titleIconW + 70), 1, 0),
Position               = UDim2.new(0, 14 + titleIconW + 4, 0, 0),
BackgroundTransparency = 1,
Text                   = title,
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 6,
Parent                 = tb,
})

local function mkTbBtn(xOff, label)
local btn = inst("TextButton", {
Size             = UDim2.new(0, 26, 0, 26),
Position         = UDim2.new(1, xOff, 0.5, -13),
BackgroundColor3 = T.Surface,
Text             = label,
TextColor3       = T.TextSecondary,
TextSize         = 11,
Font             = Enum.Font.GothamMedium,
BorderSizePixel  = 0,
AutoButtonColor  = false,
ZIndex           = 6,
Parent           = tb,
})
corner(btn, 4)
btn.MouseEnter:Connect(function() tw(btn, fast, { BackgroundColor3 = T.Primary, TextColor3 = T.PrimaryText }) end)
btn.MouseLeave:Connect(function() tw(btn, fast, { BackgroundColor3 = T.Surface, TextColor3 = T.TextSecondary }) end)
return btn
end

local closeBtn = mkTbBtn(-34, "X")
local minBtn   = mkTbBtn(-64, "-")

local minimized = false
minBtn.MouseButton1Click:Connect(function()
minimized = not minimized
tw(win, med, { Size = UDim2.new(0, W, 0, minimized and TITLEBAR_H or H) })
if self._acrylic then self._acrylic.SetVisible(not minimized) end
end)
closeBtn.MouseButton1Click:Connect(function()
tw(win, fast, { Size = UDim2.new(0, W, 0, 0), BackgroundTransparency = 1 })
if self._acrylic then self._acrylic.SetVisible(false) end
task.delay(0.22, function() gui:Destroy() end)
end)

makeDraggable(win, tb)


local keybind = config.Keybind or Enum.KeyCode.RightShift
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end
if input.KeyCode == keybind then
guiVisible = not guiVisible
if guiVisible then
win.Visible = true
tw(win, med, { BackgroundTransparency = winBgTransp })
else
tw(win, med, { BackgroundTransparency = 1 })
task.delay(0.22, function()
if not guiVisible then win.Visible = false end
end)
end
if self._acrylic then self._acrylic.SetVisible(guiVisible) end
end
end)

local body = inst("Frame", {
Name                   = "Body",
Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H),
Position               = UDim2.new(0, 0, 0, TITLEBAR_H),
BackgroundTransparency = 1,
BorderSizePixel        = 0,
ZIndex                 = 2,
Parent                 = win,
})

local sidebar = inst("Frame", {
Name             = "Sidebar",
Size             = UDim2.new(0, SIDEBAR_W, 1, 0),
BackgroundColor3 = T.SidebarBg,
BorderSizePixel  = 0,
ZIndex           = 3,
Parent           = body,
})
inst("Frame", {
Size             = UDim2.new(0, 1, 1, 0),
Position         = UDim2.new(1, -1, 0, 0),
BackgroundColor3 = T.SidebarBorder,
BorderSizePixel  = 0,
ZIndex           = 4,
Parent           = sidebar,
})

local tabList = inst("Frame", {
Name                   = "TabList",
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
ZIndex                 = 4,
Parent                 = sidebar,
})
inst("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding   = UDim.new(0, 2),
Parent    = tabList,
})
mkPad(tabList, 8, 6, 8, 6)

local contentArea = inst("Frame", {
Name             = "ContentArea",
Size             = UDim2.new(1, -SIDEBAR_W, 1, 0),
Position         = UDim2.new(0, SIDEBAR_W, 0, 0),
BackgroundColor3 = T.ContentBg,
BorderSizePixel  = 0,
ZIndex           = 3,
Parent           = body,
})

self._tabList     = tabList
self._contentArea = contentArea
self._tabs        = {}
self._tabData     = {}
self._tabOrder    = 0
self._activeTab   = nil
self._toggleStyle = (config.ToggleStyle == "basic") and "basic" or "box"
self._currentTheme = config.Theme or "Ocean"
applyTheme(self._currentTheme)


local winStroke = win:FindFirstChildWhichIsA("UIStroke")
_onThemeChange(function(t)
win.BackgroundColor3         = t.WindowBg
if winStroke then winStroke.Color = t.WindowBorder end
tb.BackgroundColor3          = t.TitleBg
sidebar.BackgroundColor3     = t.SidebarBg
contentArea.BackgroundColor3 = t.ContentBg
for _, td in pairs(self._tabData) do
local isActive = (self._activeTab == td.name)
td.btn.BackgroundColor3 = isActive and t.TabActive or t.TabNormal
td.btnLabel.TextColor3  = isActive and t.TabActiveText or t.TabNormalText
if td.iconImg then
td.iconImg.ImageColor3 = isActive and t.IconTintActive or t.IconTint
end
end
end)

return self

end

function PrestigeUI:CreateHomeTab(config)
config = config or {}

self._tabOrder = self._tabOrder + 1
local TAB_TITLE = "Home"

local btn = inst("Frame", {
Name             = "TabBtn_Home",
Size             = UDim2.new(1, 0, 0, TAB_H),
BackgroundColor3 = T.TabNormal,
BorderSizePixel  = 0,
LayoutOrder      = 0,
ZIndex           = 5,
Parent           = self._tabList,
})
corner(btn, 5)

local indicator = inst("Frame", {
Size             = UDim2.new(0, 3, 0.55, 0),
Position         = UDim2.new(0, 0, 0.225, 0),
BackgroundColor3 = T.PrimaryText,
BorderSizePixel  = 0,
Visible          = false,
ZIndex           = 6,
Parent           = btn,
})
corner(indicator, 2)

local homeIconImg = mkIcon(btn, "house", TAB_ICON_S, T.IconTint, 6, Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0))
local textOff     = homeIconImg and (10 + TAB_ICON_S + 7) or 10

local btnLabel = inst("TextLabel", {
Size                   = UDim2.new(1, -(textOff + 4), 1, 0),
Position               = UDim2.new(0, textOff, 0, 0),
BackgroundTransparency = 1,
Text                   = TAB_TITLE,
TextColor3             = T.TabNormalText,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 6,
Parent                 = btn,
})

local clickArea = inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 7,
Parent                 = btn,
})

local panel = inst("ScrollingFrame", {
Name                 = "Panel_Home",
Size                 = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
BorderSizePixel      = 0,
ScrollBarThickness   = 5,
ScrollBarImageColor3 = T.ScrollBar,
ScrollingDirection   = Enum.ScrollingDirection.Y,
CanvasSize           = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize  = Enum.AutomaticSize.None,
ElasticBehavior      = Enum.ElasticBehavior.Never,
Visible              = false,
ZIndex               = 4,
Parent               = self._contentArea,
})

local inner = inst("Frame", {
Size                   = UDim2.new(1, -8, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex                 = 4,
Parent                 = panel,
})
mkPad(inner, 14, 14, 14, 14)
local innerLayout = inst("UIListLayout", {
SortOrder           = Enum.SortOrder.LayoutOrder,
FillDirection       = Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Left,
VerticalAlignment   = Enum.VerticalAlignment.Top,
Padding             = UDim.new(0, 10),
Parent              = inner,
})
innerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
panel.CanvasSize = UDim2.new(0, 0, 0, innerLayout.AbsoluteContentSize.Y + 28)
end)

local plr = Players.LocalPlayer

local banner = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 76),
BackgroundColor3 = Color3.fromRGB(22, 14, 38),
BorderSizePixel  = 0,
LayoutOrder      = 0,
ZIndex           = 5,
Parent           = inner,
})
corner(banner, 8)
local accentBar = inst("Frame", {
Size             = UDim2.new(0, 4, 1, 0),
BackgroundColor3 = T.Primary,
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = banner,
})
corner(accentBar, 4)

local avatarRing = inst("Frame", {
Size             = UDim2.new(0, 48, 0, 48),
Position         = UDim2.new(0, 18, 0.5, -24),
BackgroundColor3 = T.Primary,
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = banner,
})
corner(avatarRing, 24)
local avatarImg = inst("ImageLabel", {
Size                   = UDim2.new(1, -4, 1, -4),
Position               = UDim2.new(0, 2, 0, 2),
BackgroundColor3       = T.SurfaceActive,
BackgroundTransparency = 0,
Image                  = "",
ScaleType              = Enum.ScaleType.Crop,
ZIndex                 = 7,
Parent                 = avatarRing,
})
corner(avatarImg, 22)

if plr then
local thumbOk, thumbUrl = pcall(function()
return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
end)
if thumbOk then avatarImg.Image = thumbUrl end
end

local function getGreeting()
local h = tonumber(os.date("%H")) or 12
if h >= 0  and h < 6  then return "Go to sleep," end
if h >= 6  and h < 12 then return "Good morning," end
if h >= 12 and h < 18 then return "Good afternoon," end
return "Good evening,"
end

inst("TextLabel", {
Size                   = UDim2.new(0.55, 0, 0, 22),
Position               = UDim2.new(0, 76, 0, 14),
BackgroundTransparency = 1,
Text                   = getGreeting() .. " " .. (plr and plr.DisplayName or "Player") .. "!",
TextColor3             = T.TextPrimary,
TextSize               = 15,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
TextTruncate           = Enum.TextTruncate.AtEnd,
ZIndex                 = 6,
Parent                 = banner,
})
inst("TextLabel", {
Size                   = UDim2.new(0.55, 0, 0, 16),
Position               = UDim2.new(0, 76, 0, 38),
BackgroundTransparency = 1,
Text                   = "@" .. (plr and plr.Name or "unknown"),
TextColor3             = T.Primary,
TextSize               = 11,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
TextTruncate           = Enum.TextTruncate.AtEnd,
ZIndex                 = 6,
Parent                 = banner,
})

local clockLbl = inst("TextLabel", {
Size                   = UDim2.new(0, 100, 0, 22),
Position               = UDim2.new(1, -112, 0, 14),
BackgroundTransparency = 1,
Text                   = "00:00:00",
TextColor3             = T.TextPrimary,
TextSize               = 15,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Right,
ZIndex                 = 6,
Parent                 = banner,
})
local dateLbl = inst("TextLabel", {
Size                   = UDim2.new(0, 100, 0, 15),
Position               = UDim2.new(1, -112, 0, 38),
BackgroundTransparency = 1,
Text                   = "00/00/00",
TextColor3             = Color3.fromRGB(190, 190, 190),
TextSize               = 11,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Right,
ZIndex                 = 6,
Parent                 = banner,
})

local function updateClock()
local t = os.date("*t")
clockLbl.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
dateLbl.Text  = string.format("%02d/%02d/%04d", t.day, t.month, t.year)
end
updateClock()
task.spawn(function()
while panel.Parent do updateClock(); task.wait(1) end
end)

local chipsRow = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 32),
BackgroundTransparency = 1,
BorderSizePixel        = 0,
LayoutOrder            = 1,
ZIndex                 = 5,
Parent                 = inner,
})
inst("UIListLayout", {
FillDirection       = Enum.FillDirection.Horizontal,
HorizontalAlignment = Enum.HorizontalAlignment.Left,
Padding             = UDim.new(0, 6),
SortOrder           = Enum.SortOrder.LayoutOrder,
Parent              = chipsRow,
})

local function mkChip(order, iconName, labelText, accent)
local chip = inst("Frame", {
Size             = UDim2.new(0, 0, 1, 0),
AutomaticSize    = Enum.AutomaticSize.X,
BackgroundColor3 = Color3.fromRGB(30, 30, 30),
BorderSizePixel  = 0,
LayoutOrder      = order,
ZIndex           = 6,
Parent           = chipsRow,
})
corner(chip, 16)
mkStroke(chip, T.Border, 1)
mkPad(chip, 0, 12, 0, 10)
local dot = inst("Frame", {
Size             = UDim2.new(0, 6, 0, 6),
Position         = UDim2.new(0, 0, 0.5, -3),
BackgroundColor3 = accent or T.Primary,
BorderSizePixel  = 0,
ZIndex           = 7,
Parent           = chip,
})
corner(dot, 3)
local lbl = inst("TextLabel", {
Size                   = UDim2.new(0, 0, 1, 0),
AutomaticSize          = Enum.AutomaticSize.X,
Position               = UDim2.new(0, 12, 0, 0),
BackgroundTransparency = 1,
Text                   = labelText,
TextColor3             = T.TextPrimary,
TextSize               = 11,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 7,
Parent                 = chip,
})
return lbl
end

local execName        = "Unknown"
local execStatusColor = T.Warning
pcall(function()
if identifyexecutor then
execName = identifyexecutor()
elseif syn and syn.request then
execName = "Synapse X"
elseif KRNL_LOADED then
execName = "Krnl"
elseif getgenv and getgenv().fluxus then
execName = "Fluxus"
end
end)

local supported   = config.SupportedExecutors   or {}
local unsupported = config.UnsupportedExecutors or {}
for _, v in ipairs(supported)   do if v:lower() == execName:lower() then execStatusColor = T.Success; break end end
for _, v in ipairs(unsupported) do if v:lower() == execName:lower() then execStatusColor = T.Error;   break end end

local gameName = "Unknown"
pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

local pingChipLbl    = mkChip(1, "wifi",      math.floor((Players.LocalPlayer:GetNetworkPing()*1000)).."ms ping",  T.Info)
local playersChipLbl = mkChip(2, "users",     #Players:GetPlayers().."/"..Players.MaxPlayers.." players",          T.Success)
mkChip(3, "gamepad-2", gameName,                                                                                    T.Primary)
mkChip(4, "terminal",  execName,                                                                                    execStatusColor)

task.spawn(function()
while panel.Parent do
pcall(function()
pingChipLbl.Text    = math.floor((Players.LocalPlayer:GetNetworkPing()*1000)).."ms ping"
playersChipLbl.Text = #Players:GetPlayers().."/"..Players.MaxPlayers.." players"
end)
task.wait(3)
end
end)

local mainRow = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 310),
BackgroundTransparency = 1,
BorderSizePixel        = 0,
LayoutOrder            = 2,
ZIndex                 = 5,
Parent                 = inner,
})
inst("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal,
Padding       = UDim.new(0, 8),
SortOrder     = Enum.SortOrder.LayoutOrder,
Parent        = mainRow,
})

local clPanel = inst("ScrollingFrame", {
Size                 = UDim2.new(0.6, -4, 1, 0),
BackgroundColor3     = Color3.fromRGB(30, 30, 30),
BorderSizePixel      = 0,
ScrollBarThickness   = 3,
ScrollBarImageColor3 = T.ScrollBar,
CanvasSize           = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize  = Enum.AutomaticSize.Y,
LayoutOrder          = 1,
ZIndex               = 5,
Parent               = mainRow,
})
corner(clPanel, 7)
mkStroke(clPanel, Color3.fromRGB(70, 70, 70), 1)

local clInner = inst("Frame", {
Size                   = UDim2.new(1, -8, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex                 = 6,
Parent                 = clPanel,
})
mkPad(clInner, 10, 10, 10, 14)
inst("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding   = UDim.new(0, 0),
Parent    = clInner,
})

local clHdr = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 26),
BackgroundTransparency = 1,
LayoutOrder            = 0,
ZIndex                 = 6,
Parent                 = clInner,
})
mkIcon(clHdr, "history", 13, T.Primary, 7, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
inst("TextLabel", {
Size                   = UDim2.new(1, -20, 1, 0),
Position               = UDim2.new(0, 20, 0, 0),
BackgroundTransparency = 1,
Text                   = "Changelog",
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 7,
Parent                 = clHdr,
})

local changelog = config.Changelog or {}
for i, entry in ipairs(changelog) do
local isLast = (i == #changelog)
local row = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
LayoutOrder            = i,
ZIndex                 = 6,
Parent                 = clInner,
})
inst("Frame", {
Size             = UDim2.new(0, 1, 1, 0),
Position         = UDim2.new(0, 5, 0, 14),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
Visible          = not isLast,
ZIndex           = 7,
Parent           = row,
})
local dot = inst("Frame", {
Size             = UDim2.new(0, 11, 0, 11),
Position         = UDim2.new(0, 0, 0, 7),
BackgroundColor3 = (i == 1) and T.Primary or T.Border,
BorderSizePixel  = 0,
ZIndex           = 8,
Parent           = row,
})
corner(dot, 6)
if i == 1 then
local dotGlow = inst("Frame", {
Size                   = UDim2.new(0, 5, 0, 5),
Position               = UDim2.new(0.5, -2, 0.5, -2),
BackgroundColor3       = Color3.fromRGB(255, 255, 255),
BackgroundTransparency = 0.4,
BorderSizePixel        = 0,
ZIndex                 = 9,
Parent                 = dot,
})
corner(dotGlow, 3)
end
local entryContent = inst("Frame", {
Size                   = UDim2.new(1, -24, 0, 0),
Position               = UDim2.new(0, 22, 0, 2),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex                 = 7,
Parent                 = row,
})
inst("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding   = UDim.new(0, 2),
Parent    = entryContent,
})
local titleRow = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 18),
BackgroundTransparency = 1,
LayoutOrder            = 1,
ZIndex                 = 7,
Parent                 = entryContent,
})
inst("TextLabel", {
Size                   = UDim2.new(0.55, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = entry.Title or "",
TextColor3             = (i == 1) and T.TextPrimary or Color3.fromRGB(200, 200, 200),
TextSize               = 12,
Font                   = (i == 1) and Enum.Font.GothamBold or Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 8,
Parent                 = titleRow,
})
inst("TextLabel", {
Size                   = UDim2.new(0.45, 0, 1, 0),
Position               = UDim2.new(0.55, 0, 0, 0),
BackgroundTransparency = 1,
Text                   = entry.Date or "",
TextColor3             = (i == 1) and T.Primary or Color3.fromRGB(150, 150, 150),
TextSize               = 10,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Right,
ZIndex                 = 8,
Parent                 = titleRow,
})
if entry.Description and entry.Description ~= "" then
inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
Text                   = entry.Description,
TextColor3             = Color3.fromRGB(185, 185, 185),
TextSize               = 10,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
TextWrapped            = true,
LayoutOrder            = 2,
ZIndex                 = 8,
Parent                 = entryContent,
})
end
inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 10),
BackgroundTransparency = 1,
LayoutOrder            = 3,
ZIndex                 = 6,
Parent                 = entryContent,
})
end

local friendsPanel = inst("Frame", {
Size             = UDim2.new(0.4, -4, 1, 0),
BackgroundColor3 = Color3.fromRGB(30, 30, 30),
BorderSizePixel  = 0,
LayoutOrder      = 2,
ZIndex           = 5,
Parent           = mainRow,
})
corner(friendsPanel, 7)
mkStroke(friendsPanel, Color3.fromRGB(70, 70, 70), 1)

local fHdr = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 36),
BackgroundColor3 = Color3.fromRGB(28, 28, 28),
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = friendsPanel,
})
corner(fHdr, 7)
inst("Frame", {
Size             = UDim2.new(1, 0, 0, 10),
Position         = UDim2.new(0, 0, 1, -10),
BackgroundColor3 = Color3.fromRGB(28, 28, 28),
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = fHdr,
})
mkIcon(fHdr, "users", 13, T.Primary, 7, Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0))
inst("TextLabel", {
Size                   = UDim2.new(1, -34, 1, 0),
Position               = UDim2.new(0, 32, 0, 0),
BackgroundTransparency = 1,
Text                   = "Friends",
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.GothamBold,
ZIndex                 = 7,
Parent                 = fHdr,
})
local fCountLbl = inst("TextLabel", {
Size                   = UDim2.new(0, 40, 1, 0),
Position               = UDim2.new(1, -44, 0, 0),
BackgroundTransparency = 1,
Text                   = "â¦",
TextColor3             = Color3.fromRGB(190, 190, 190),
TextSize               = 11,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Right,
ZIndex                 = 7,
Parent                 = fHdr,
})

local fStatsGrid = inst("Frame", {
Size                   = UDim2.new(1, -20, 1, -52),
Position               = UDim2.new(0.5, 0, 1, -8),
AnchorPoint            = Vector2.new(0.5, 1),
BackgroundTransparency = 1,
ZIndex                 = 6,
Parent                 = friendsPanel,
})
inst("UIGridLayout", {
CellSize    = UDim2.new(0.5, -6, 0.5, -6),
CellPadding = UDim2.new(0, 10, 0, 10),
SortOrder   = Enum.SortOrder.LayoutOrder,
Parent      = fStatsGrid,
})

local function mkFStatChip(order, label, accent)
local chip = inst("Frame", {
BackgroundColor3 = Color3.fromRGB(28, 28, 28),
BorderSizePixel  = 0,
LayoutOrder      = order,
ZIndex           = 7,
Parent           = fStatsGrid,
})
corner(chip, 5)
inst("UIListLayout", {
SortOrder           = Enum.SortOrder.LayoutOrder,
FillDirection       = Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Center,
VerticalAlignment   = Enum.VerticalAlignment.Center,
Padding             = UDim.new(0, 1),
Parent              = chip,
})
local valLbl2 = inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 16),
BackgroundTransparency = 1,
Text                   = "-",
TextColor3             = accent,
TextSize               = 14,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Center,
LayoutOrder            = 1,
ZIndex                 = 8,
Parent                 = chip,
})
inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 12),
BackgroundTransparency = 1,
Text                   = label,
TextColor3             = Color3.fromRGB(160, 160, 160),
TextSize               = 9,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Center,
LayoutOrder            = 2,
ZIndex                 = 8,
Parent                 = chip,
})
return valLbl2
end

local fInServer = mkFStatChip(1, "in server",  T.Primary)
local fOnline   = mkFStatChip(2, "online",     T.Success)
local fOffline  = mkFStatChip(3, "offline",    Color3.fromRGB(120, 120, 120))
local fTotal    = mkFStatChip(4, "total",      T.Info)

task.spawn(function()
local localPlayer   = Players.LocalPlayer
local serverPlayers = {}
for _, p in ipairs(Players:GetPlayers()) do
serverPlayers[p.UserId] = true
end
local success, result = pcall(function()
return localPlayer:GetFriendsOnline()
end)
local inServer, onlineOut, total = 0, 0, 0
if success and result then
total = #result
for _, friend in ipairs(result) do
if serverPlayers[friend.VisitorId] then
inServer = inServer + 1
else
onlineOut = onlineOut + 1
end
end
end
local realTotal = total
pcall(function()
local pages = Players:GetFriendsAsync(localPlayer.UserId)
local count = 0
repeat
for _ in ipairs(pages:GetCurrentPage()) do count = count + 1 end
if not pages.IsFinished then pages:AdvanceToNextPageAsync() end
until pages.IsFinished
realTotal = count
end)
local offline = math.max(0, realTotal - inServer - onlineOut)
fInServer.Text = tostring(inServer)
fOnline.Text   = tostring(onlineOut)
fOffline.Text  = tostring(offline)
fTotal.Text    = tostring(realTotal)
fCountLbl.Text = realTotal .. " total"
end)

if config.DiscordInvite and config.DiscordInvite ~= "" then
local discordBanner = inst("Frame", {
Size                 = UDim2.new(1, 0, 0, 62),
BackgroundColor3     = Color3.fromRGB(24, 25, 56),
BorderSizePixel      = 0,
ClipsDescendants     = true,
LayoutOrder          = 3,
ZIndex               = 5,
Parent               = inner,
})
corner(discordBanner, 8)
mkStroke(discordBanner, Color3.fromRGB(55, 60, 140), 1)

local dCircle = inst("Frame", {
Size             = UDim2.new(0, 26, 0, 26),
AnchorPoint      = Vector2.new(0, 0.5),
Position         = UDim2.new(0, 12, 0.5, 0),
BackgroundColor3 = Color3.fromRGB(88, 101, 242),
BorderSizePixel  = 0,
ZIndex           = 7,
Parent           = discordBanner,
})
corner(dCircle, 13)
inst("ImageLabel", {
Size                   = UDim2.new(0, 18, 0, 18),
AnchorPoint            = Vector2.new(0.5, 0.5),
Position               = UDim2.new(0.5, 0, 0.5, 0),
BackgroundTransparency = 1,
Image                  = "rbxassetid://114656582279734",
ScaleType              = Enum.ScaleType.Fit,
ZIndex                 = 8,
Parent                 = dCircle,
})
inst("TextLabel", {
Size                   = UDim2.new(0.5, 0, 0, 16),
Position               = UDim2.new(0, 54, 0, 11),
BackgroundTransparency = 1,
Text                   = "Discord Server",
TextColor3             = Color3.fromRGB(235, 236, 255),
TextSize               = 12,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 8,
Parent                 = discordBanner,
})
inst("TextLabel", {
Size                   = UDim2.new(0.5, 0, 0, 12),
Position               = UDim2.new(0, 54, 0, 28),
BackgroundTransparency = 1,
Text                   = "Click to copy the invite",
TextColor3             = Color3.fromRGB(140, 145, 210),
TextSize               = 10,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 8,
Parent                 = discordBanner,
})
local pill = inst("Frame", {
Size             = UDim2.new(0, 0, 0, 22),
AutomaticSize    = Enum.AutomaticSize.X,
Position         = UDim2.new(1, -14, 0.5, 0),
AnchorPoint      = Vector2.new(1, 0.5),
BackgroundColor3 = Color3.fromRGB(15, 16, 38),
BorderSizePixel  = 0,
ZIndex           = 8,
Parent           = discordBanner,
})
corner(pill, 14)
mkStroke(pill, Color3.fromRGB(66, 72, 140), 1)
mkPad(pill, 0, 12, 0, 10)
local pillIcon = mkIcon(pill, "copy", 12, Color3.fromRGB(140, 148, 220), 7, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
local pillLbl  = inst("TextLabel", {
Size                   = UDim2.new(0, 0, 1, 0),
AutomaticSize          = Enum.AutomaticSize.X,
Position               = UDim2.new(0, 18, 0, 0),
BackgroundTransparency = 1,
Text                   = "discord.gg/" .. config.DiscordInvite,
TextColor3             = Color3.fromRGB(170, 175, 230),
TextSize               = 11,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 9,
Parent                 = pill,
})
local pillBtn = inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 10,
Parent                 = pill,
})
local copying = false
local function doCopy()
if copying then return end
copying = true
pcall(function() setclipboard("https://discord.gg/" .. config.DiscordInvite) end)
pillLbl.Text = "Copied!"
tw(pill,    fast, { BackgroundColor3 = Color3.fromRGB(20, 50, 30) })
tw(pillLbl, fast, { TextColor3 = Color3.fromRGB(100, 220, 130) })
if pillIcon then tw(pillIcon, fast, { ImageColor3 = Color3.fromRGB(100, 220, 130) }) end
task.delay(2, function()
if pill.Parent then
pillLbl.Text = "discord.gg/" .. config.DiscordInvite
tw(pill,    fast, { BackgroundColor3 = Color3.fromRGB(15, 16, 38) })
tw(pillLbl, fast, { TextColor3 = Color3.fromRGB(170, 175, 230) })
if pillIcon then tw(pillIcon, fast, { ImageColor3 = Color3.fromRGB(140, 148, 220) }) end
end
copying = false
end)
end
pillBtn.MouseEnter:Connect(function()
tw(pill,    fast, { BackgroundColor3 = Color3.fromRGB(22, 24, 55) })
tw(pillLbl, fast, { TextColor3 = Color3.fromRGB(200, 205, 255) })
if pillIcon then tw(pillIcon, fast, { ImageColor3 = Color3.fromRGB(170, 178, 255) }) end
end)
pillBtn.MouseLeave:Connect(function()
if not copying then
tw(pill,    fast, { BackgroundColor3 = Color3.fromRGB(15, 16, 38) })
tw(pillLbl, fast, { TextColor3 = Color3.fromRGB(170, 175, 230) })
if pillIcon then tw(pillIcon, fast, { ImageColor3 = Color3.fromRGB(140, 148, 220) }) end
end
end)
pillBtn.MouseButton1Click:Connect(doCopy)
local bannerBtn = inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 6,
Parent                 = discordBanner,
})
bannerBtn.MouseEnter:Connect(function()
tw(discordBanner, fast, { BackgroundColor3 = Color3.fromRGB(28, 30, 65) })
end)
bannerBtn.MouseLeave:Connect(function()
tw(discordBanner, fast, { BackgroundColor3 = Color3.fromRGB(24, 25, 56) })
end)
bannerBtn.MouseButton1Click:Connect(doCopy)

end

local tabData = {
name      = TAB_TITLE,
btn       = btn,
btnLabel  = btnLabel,
iconImg   = homeIconImg,
indicator = indicator,
panel     = panel,
}
table.insert(self._tabs, 1, tabData)
self._tabData[TAB_TITLE] = tabData
self:_switchTab(TAB_TITLE)

clickArea.MouseEnter:Connect(function()
if self._activeTab ~= TAB_TITLE then
tw(btn, fast, { BackgroundColor3 = T.TabHover })
tw(btnLabel, fast, { TextColor3 = T.TextPrimary })
end
end)
clickArea.MouseLeave:Connect(function()
if self._activeTab ~= TAB_TITLE then
tw(btn, fast, { BackgroundColor3 = T.TabNormal })
tw(btnLabel, fast, { TextColor3 = T.TabNormalText })
if homeIconImg then tw(homeIconImg, fast, { ImageColor3 = T.IconTint }) end
end
end)
clickArea.MouseButton1Click:Connect(function()
self:_switchTab(TAB_TITLE)
end)

end

function PrestigeUI:CreateTab(config)
config = config or {}
local tabTitle = config.Title or ("Tab " .. (self._tabOrder + 1))
local tabIcon  = config.Icon

self._tabOrder = self._tabOrder + 1

local btn = inst("Frame", {
Name             = "TabBtn_" .. tabTitle,
Size             = UDim2.new(1, 0, 0, TAB_H),
BackgroundColor3 = T.TabNormal,
BorderSizePixel  = 0,
LayoutOrder      = self._tabOrder,
ZIndex           = 5,
Parent           = self._tabList,
})
corner(btn, 5)

local indicator = inst("Frame", {
Name             = "Indicator",
Size             = UDim2.new(0, 3, 0.55, 0),
Position         = UDim2.new(0, 0, 0.225, 0),
BackgroundColor3 = T.PrimaryText,
BorderSizePixel  = 0,
Visible          = false,
ZIndex           = 6,
Parent           = btn,
})
corner(indicator, 2)

local iconImg        = nil
local textOffsetLeft = 10

if tabIcon then
iconImg = mkIcon(btn, tabIcon, TAB_ICON_S, T.IconTint, 6, Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0))
if iconImg then
textOffsetLeft = 10 + TAB_ICON_S + 7
end
end

local btnLabel = inst("TextLabel", {
Name                   = "Label",
Size                   = UDim2.new(1, -(textOffsetLeft + 4), 1, 0),
Position               = UDim2.new(0, textOffsetLeft, 0, 0),
BackgroundTransparency = 1,
Text                   = tabTitle,
TextColor3             = T.TabNormalText,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 6,
Parent                 = btn,
})

local clickArea = inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 7,
Parent                 = btn,
})

local panel = inst("ScrollingFrame", {
Name                 = "Panel_" .. tabTitle,
Size                 = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
BorderSizePixel      = 0,
ScrollBarThickness   = 5,
ScrollBarImageColor3 = T.ScrollBar,
ScrollingDirection   = Enum.ScrollingDirection.Y,
CanvasSize           = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize  = Enum.AutomaticSize.None,
ElasticBehavior      = Enum.ElasticBehavior.Never,
Visible              = false,
ZIndex               = 4,
Parent               = self._contentArea,
})

local inner = inst("Frame", {
Name                   = "Inner",
Size                   = UDim2.new(1, -8, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex                 = 4,
Parent                 = panel,
})
mkPad(inner, 20, 20, 20, 20)

local listLayout = inst("UIListLayout", {
SortOrder           = Enum.SortOrder.LayoutOrder,
FillDirection       = Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Left,
VerticalAlignment   = Enum.VerticalAlignment.Top,
Padding             = UDim.new(0, 10),
Parent              = inner,
})

local function updateCanvas()
panel.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 40)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

local headerFrame = inst("Frame", {
Name                   = "PanelHeader",
Size                   = UDim2.new(1, 0, 0, 26),
BackgroundTransparency = 1,
LayoutOrder            = 0,
ZIndex                 = 4,
Parent                 = inner,
})

local panelIconW = 0
local panelIcon  = mkIcon(headerFrame, tabIcon, 18, T.Primary, 5, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
if panelIcon then panelIconW = 18 + 8 end

inst("TextLabel", {
Size                   = UDim2.new(1, -panelIconW, 1, 0),
Position               = UDim2.new(0, panelIconW, 0, 0),
BackgroundTransparency = 1,
Text                   = tabTitle,
TextColor3             = T.TextPrimary,
TextSize               = 16,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 5,
Parent                 = headerFrame,
})

inst("Frame", {
Name             = "Divider",
Size             = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
LayoutOrder      = 1,
ZIndex           = 4,
Parent           = inner,
})

clickArea.MouseEnter:Connect(function()
if self._activeTab ~= tabTitle then
tw(btn, fast, { BackgroundColor3 = T.TabHover })
tw(btnLabel, fast, { TextColor3 = T.TextPrimary })
end
end)
clickArea.MouseLeave:Connect(function()
if self._activeTab ~= tabTitle then
tw(btn, fast, { BackgroundColor3 = T.TabNormal })
tw(btnLabel, fast, { TextColor3 = T.TabNormalText })
if iconImg then tw(iconImg, fast, { ImageColor3 = T.IconTint }) end
end
end)
clickArea.MouseButton1Click:Connect(function()
self:_switchTab(tabTitle)
end)

local tabData = {
name      = tabTitle,
btn       = btn,
btnLabel  = btnLabel,
iconImg   = iconImg,
indicator = indicator,
panel     = panel,
}
table.insert(self._tabs, tabData)
self._tabData[tabTitle] = tabData
if not self._activeTab then
self:_switchTab(tabTitle)
end

local tabObj = {
_inner = inner,
_order = 2,
_win   = self,
}
setmetatable(tabObj, { __index = PrestigeUI._TabAPI })
return tabObj

end

function PrestigeUI:_switchTab(name)
if self._activeTab == name then return end
for _, tabData in pairs(self._tabData) do
tw(tabData.btn,      fast, { BackgroundColor3 = T.TabNormal })
tw(tabData.btnLabel, fast, { TextColor3 = T.TabNormalText })
tabData.btnLabel.Font     = Enum.Font.Gotham
if tabData.iconImg then tw(tabData.iconImg, fast, { ImageColor3 = T.IconTint }) end
tabData.indicator.Visible = false
tabData.panel.Visible     = false
end
local next = self._tabData[name]
if next then
tw(next.btn,      fast, { BackgroundColor3 = T.TabActive })
tw(next.btnLabel, fast, { TextColor3 = T.TabActiveText })
next.btnLabel.Font = Enum.Font.GothamMedium
if next.iconImg then tw(next.iconImg, fast, { ImageColor3 = T.IconTintActive }) end
next.indicator.Visible = true
next.panel.Visible     = true
end
self._activeTab = name
end

PrestigeUI._TabAPI = {}
PrestigeUI._TabAPI.__index = PrestigeUI._TabAPI

function PrestigeUI._TabAPI:_o()
self._order = self._order + 1
return self._order
end

function PrestigeUI._TabAPI:AddLabel(text, opts)
opts = opts or {}
return inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
Text                   = text,
TextColor3             = opts.Color or T.TextSecondary,
TextSize               = opts.TextSize or 10,
Font                   = opts.Font or Enum.Font.Gotham,
TextXAlignment         = opts.Align or Enum.TextXAlignment.Left,
TextWrapped            = true,
RichText               = opts.Rich or false,
LayoutOrder            = opts.Order or self:_o(),
ZIndex                 = 4,
Parent                 = self._inner,
})
end

function PrestigeUI._TabAPI:AddSeparator()
return inst("Frame", {
Size             = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
LayoutOrder      = self:_o(),
ZIndex           = 4,
Parent           = self._inner,
})
end

function PrestigeUI._TabAPI:AddButton(text, callback, opts)
opts = opts or {}
local isPrimary = opts.Primary or false
local bgN = isPrimary and T.Primary or T.Surface
local bgH = isPrimary and T.PrimaryHover or T.SurfaceHover

local btn = inst("TextButton", {
Size             = UDim2.new(1, 0, 0, opts.Height or 36),
BackgroundColor3 = bgN,
Text             = "",
BorderSizePixel  = 0,
LayoutOrder      = opts.Order or self:_o(),
AutoButtonColor  = false,
ZIndex           = 4,
Parent           = self._inner,
})
corner(btn, 5)
if not isPrimary then mkStroke(btn, T.Border, 1) end

local iconW   = 0
local iconImg = mkIcon(btn, opts.Icon, 14, isPrimary and T.PrimaryText or T.TextSecondary, 5, Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0))
if iconImg then iconW = 14 + 8 end

inst("TextLabel", {
Size                   = UDim2.new(1, -(12 + iconW), 1, 0),
Position               = UDim2.new(0, 12 + iconW, 0, 0),
BackgroundTransparency = 1,
Text                   = text,
TextColor3             = isPrimary and T.PrimaryText or T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = iconW > 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
ZIndex                 = 5,
Parent                 = btn,
})

btn.MouseEnter:Connect(function()       tw(btn, fast, { BackgroundColor3 = bgH }) end)
btn.MouseLeave:Connect(function()       tw(btn, fast, { BackgroundColor3 = bgN }) end)
btn.MouseButton1Down:Connect(function() tw(btn, fast, { BackgroundColor3 = T.SurfaceActive }) end)
btn.MouseButton1Up:Connect(function()   tw(btn, fast, { BackgroundColor3 = bgH }) end)
btn.MouseButton1Click:Connect(function() if callback then callback() end end)
return btn

end

function PrestigeUI._TabAPI:AddInput(placeholder, callback, opts)
opts = opts or {}

local container = inst("Frame", {
Size             = UDim2.new(1, 0, 0, opts.Height or 38),
BackgroundColor3 = T.Surface,
BorderSizePixel  = 0,
LayoutOrder      = opts.Order or self:_o(),
ZIndex           = 4,
Parent           = self._inner,
})
corner(container, 5)
local s = mkStroke(container, T.Border, 1)

local iconW   = 0
local iconImg = mkIcon(container, opts.Icon, 14, T.TextMuted, 6, Vector2.new(0, 0.5), UDim2.new(0, 11, 0.5, 0))
if iconImg then iconW = 14 + 6 end

local box = inst("TextBox", {
Size                   = UDim2.new(1, -(12 + iconW), 1, 0),
Position               = UDim2.new(0, 10 + iconW, 0, 0),
BackgroundTransparency = 1,
PlaceholderText        = placeholder or "",
PlaceholderColor3      = T.TextMuted,
Text                   = opts.Default or "",
TextColor3             = T.TextPrimary,
TextSize               = (opts.Default and opts.Default ~= "") and 20 or 14,
Font                   = Enum.Font.Gotham,
ClearTextOnFocus       = false,
ZIndex                 = 6,
Parent                 = container,
})

box:GetPropertyChangedSignal("Text"):Connect(function()
box.TextSize = (box.Text ~= "") and 20 or 14
end)
box.Focused:Connect(function()
tw(s, fast, { Color = T.BorderFocus })
if iconImg then tw(iconImg, fast, { ImageColor3 = T.Primary }) end
end)
box.FocusLost:Connect(function(enter)
tw(s, fast, { Color = T.Border })
if iconImg then tw(iconImg, fast, { ImageColor3 = T.TextMuted }) end
if callback then callback(box.Text, enter) end
end)
return box

end

function PrestigeUI._TabAPI:AddToggle(label, default, callback, opts)
opts  = opts or {}
local state = default or false
local style = opts.Style or self._win._toggleStyle or "box"

local row = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 40),
BackgroundColor3 = T.Surface,
BorderSizePixel  = 0,
LayoutOrder      = opts.Order or self:_o(),
ZIndex           = 4,
Parent           = self._inner,
})
corner(row, 5)
mkStroke(row, T.Border, 1)
mkPad(row, 0, 14, 0, 12)

local iconW   = 0
local iconImg = mkIcon(row, opts.Icon, 14, T.TextSecondary, 6, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
if iconImg then iconW = 14 + 8 end

inst("TextLabel", {
Size                   = UDim2.new(1, -(iconW + 46), 1, 0),
Position               = UDim2.new(0, iconW, 0, 0),
BackgroundTransparency = 1,
Text                   = label,
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 5,
Parent                 = row,
})

local set

if style == "box" then
local BOX = 26
local box = inst("Frame", {
Size             = UDim2.new(0, BOX, 0, BOX),
Position         = UDim2.new(1, -BOX, 0.5, -BOX/2),
BackgroundColor3 = state and T.ToggleOn or Color3.fromRGB(45, 45, 45),
BorderSizePixel  = 0,
ZIndex           = 5,
Parent           = row,
})
corner(box, 6)
local boxStroke = inst("UIStroke", {
Color           = state and T.ToggleOn or Color3.fromRGB(80, 80, 80),
Thickness       = 2,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent          = box,
})
local checkIcon = mkIcon(box, "check", 14, Color3.fromRGB(255, 255, 255), 6, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0))
if checkIcon then
checkIcon.ImageTransparency = state and 0 or 1
end
set = function(v)
state = v
if state then
tw(box,       fast, { BackgroundColor3 = T.ToggleOn })
tw(boxStroke, fast, { Color = T.ToggleOn })
if checkIcon then tw(checkIcon, fast, { ImageTransparency = 0 }) end
else
tw(box,       fast, { BackgroundColor3 = Color3.fromRGB(45, 45, 45) })
tw(boxStroke, fast, { Color = Color3.fromRGB(80, 80, 80) })
if checkIcon then tw(checkIcon, fast, { ImageTransparency = 1 }) end
end
end
else
local TW, TH = 46, 24
local track = inst("Frame", {
Size             = UDim2.new(0, TW, 0, TH),
Position         = UDim2.new(1, -TW, 0.5, -TH/2),
BackgroundColor3 = state and T.ToggleOn or Color3.fromRGB(30, 30, 30),
BorderSizePixel  = 0,
ZIndex           = 5,
Parent           = row,
})
corner(track, TH/2)
local trackStroke = inst("UIStroke", {
Color           = state and T.ToggleOn or Color3.fromRGB(15, 15, 15),
Thickness       = 0.5,
ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
Parent          = track,
})
local KS   = TH - 6
local knob = inst("Frame", {
Size             = UDim2.new(0, KS, 0, KS),
Position         = UDim2.new(0, state and (TW - KS - 3) or 3, 0.5, -KS/2),
BackgroundColor3 = Color3.fromRGB(255, 255, 255),
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = track,
})
corner(knob, KS/2)
set = function(v)
state = v
if state then
tw(track,       fast, { BackgroundColor3 = T.ToggleOn })
tw(trackStroke, fast, { Color = T.ToggleOn })
tw(knob,        fast, { Position = UDim2.new(0, TW - KS - 3, 0.5, -KS/2) })
else
tw(track,       fast, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
tw(trackStroke, fast, { Color = Color3.fromRGB(15, 15, 15) })
tw(knob,        fast, { Position = UDim2.new(0, 3, 0.5, -KS/2) })
end
end
end

inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 7,
Parent                 = row,
}).MouseButton1Click:Connect(function()
set(not state)
if callback then callback(state) end
end)

return { Get = function() return state end, Set = set }

end

function PrestigeUI._TabAPI:AddSlider(label, min, max, default, callback, opts)
opts  = opts or {}
min   = min  or 0
max   = max  or 100
local value = math.clamp(default or min, min, max)

local container = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 58),
BackgroundColor3 = T.Surface,
BorderSizePixel  = 0,
LayoutOrder      = opts.Order or self:_o(),
ZIndex           = 4,
Parent           = self._inner,
})
corner(container, 5)
mkStroke(container, T.Border, 1)
mkPad(container, 8, 14, 8, 14)

local hdr = inst("Frame", {
Size                   = UDim2.new(1, 0, 0, 18),
BackgroundTransparency = 1,
ZIndex                 = 5,
Parent                 = container,
})
inst("TextLabel", {
Size                   = UDim2.new(0.7, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = label,
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 5,
Parent                 = hdr,
})
local valLbl = inst("TextLabel", {
Size                   = UDim2.new(0.3, 0, 1, 0),
Position               = UDim2.new(0.7, 0, 0, 0),
BackgroundTransparency = 1,
Text                   = tostring(value),
TextColor3             = T.Primary,
TextSize               = 13,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Right,
ZIndex                 = 5,
Parent                 = hdr,
})

local track = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 5),
Position         = UDim2.new(0, 0, 1, -5),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
ZIndex           = 5,
Parent           = container,
})
corner(track, 3)

local pct  = (value - min) / (max - min)
local fill = inst("Frame", {
Size             = UDim2.new(pct, 0, 1, 0),
BackgroundColor3 = T.Primary,
BorderSizePixel  = 0,
ZIndex           = 6,
Parent           = track,
})
corner(fill, 3)

local knob = inst("Frame", {
Size             = UDim2.new(0, 13, 0, 13),
Position         = UDim2.new(pct, -6, 0.5, -6),
BackgroundColor3 = Color3.fromRGB(255, 255, 255),
BorderSizePixel  = 0,
ZIndex           = 7,
Parent           = track,
})
corner(knob, 7)

local dragging = false
local function update(x)
local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
value = math.floor(min + rel * (max - min) + 0.5)
valLbl.Text = tostring(value)
tw(fill, fast, { Size     = UDim2.new(rel, 0, 1, 0) })
tw(knob, fast, { Position = UDim2.new(rel, -6, 0.5, -6) })
if callback then callback(value) end
end

knob.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
end)
track.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i.Position.X) end
end)
UserInputService.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
end)

return {
Get = function() return value end,
Set = function(v)
value = math.clamp(v, min, max)
local r = (value - min) / (max - min)
valLbl.Text = tostring(value)
tw(fill, fast, { Size     = UDim2.new(r, 0, 1, 0) })
tw(knob, fast, { Position = UDim2.new(r, -6, 0.5, -6) })
end,
}

end

function PrestigeUI._TabAPI:AddDropdown(label, items, callback, opts)
opts = opts or {}
local selected = opts.Default or items[1] or ""
local open     = false

local HDR_H   = 36
local ITEM_H  = 32
local MAX_VIS = math.min(#items, 6)
local LIST_H  = MAX_VIS * ITEM_H + 8

local container = inst("Frame", {
Size             = UDim2.new(1, 0, 0, HDR_H),
BackgroundColor3 = T.Surface,
BorderSizePixel  = 0,
ClipsDescendants = true,
LayoutOrder      = opts.Order or self:_o(),
ZIndex           = 4,
Parent           = self._inner,
})
corner(container, 5)
local stroke = mkStroke(container, T.Border, 1)

local chevron = inst("ImageLabel", {
Size                   = UDim2.new(0, 14, 0, 14),
AnchorPoint            = Vector2.new(1, 0.5),
Position               = UDim2.new(1, -10, 0, HDR_H / 2),
BackgroundTransparency = 1,
Image                  = iconAsset("chevron-down") or "",
ImageColor3            = Color3.fromRGB(255, 255, 255),
ScaleType              = Enum.ScaleType.Fit,
ZIndex                 = 7,
Parent                 = container,
})

local iconW = 0
if opts.Icon then
local ico = mkIcon(container, opts.Icon, 14, Color3.fromRGB(255, 255, 255), 7, Vector2.new(0, 0.5), UDim2.new(0, 10, 0, HDR_H / 2))
if ico then iconW = 10 + 14 + 6 end
end

local LEFT  = (iconW > 0 and iconW or 10)
local RIGHT = 26

local labelLbl = inst("TextLabel", {
Size                   = UDim2.new(1, -(LEFT + RIGHT), 0, 14),
Position               = UDim2.new(0, LEFT, 0, 5),
BackgroundTransparency = 1,
Text                   = label,
TextColor3             = Color3.fromRGB(225, 225, 225),
TextSize               = 12,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Left,
TextTruncate           = Enum.TextTruncate.AtEnd,
ZIndex                 = 7,
Parent                 = container,
})

local selLbl = inst("TextLabel", {
Size                   = UDim2.new(1, -(LEFT + RIGHT), 0, 12),
Position               = UDim2.new(0, LEFT, 0, 21),
BackgroundTransparency = 1,
Text                   = selected,
TextColor3             = Color3.fromRGB(100, 100, 100),
TextSize               = 10,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
TextTruncate           = Enum.TextTruncate.AtEnd,
ZIndex                 = 7,
Parent                 = container,
})

local hdrBtn = inst("TextButton", {
Size                   = UDim2.new(1, 0, 0, HDR_H),
BackgroundTransparency = 1,
Text                   = "",
AutoButtonColor        = false,
ZIndex                 = 9,
Parent                 = container,
})

local divider = inst("Frame", {
Size                   = UDim2.new(1, -20, 0, 1),
Position               = UDim2.new(0, 10, 0, HDR_H),
BackgroundColor3       = T.Border,
BackgroundTransparency = 1,
BorderSizePixel        = 0,
ZIndex                 = 5,
Parent                 = container,
})

local scrollList = inst("ScrollingFrame", {
Size                   = UDim2.new(1, 0, 0, LIST_H),
Position               = UDim2.new(0, 0, 0, HDR_H + 1),
BackgroundTransparency = 1,
BorderSizePixel        = 0,
ScrollBarThickness     = 3,
ScrollBarImageColor3   = T.ScrollBar,
CanvasSize             = UDim2.new(0, 0, 0, 0),
ScrollingDirection     = Enum.ScrollingDirection.Y,
ZIndex                 = 5,
Parent                 = container,
})
mkPad(scrollList, 4, 6, 4, 6)
local listLayout = inst("UIListLayout", {
SortOrder = Enum.SortOrder.LayoutOrder,
Padding   = UDim.new(0, 3),
Parent    = scrollList,
})
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

local itemBtns = {}

local function setActive(ib, on)
tw(ib, fast, {
BackgroundTransparency = on and 0 or 1,
BackgroundColor3       = on and Color3.fromRGB(50, 24, 12) or T.SurfaceHover,
})
local lbl = ib:FindFirstChild("ItemLabel")
if lbl then
tw(lbl, fast, { TextColor3 = on and T.Primary or T.TextSecondary })
lbl.Font = on and Enum.Font.GothamMedium or Enum.Font.Gotham
end
local bar = ib:FindFirstChild("AccentBar")
if bar then
tw(bar, fast, {
Size                   = UDim2.new(0, 3, 0, on and 14 or 0),
BackgroundTransparency = on and 0 or 1,
})
end
end

local function doClose()
open = false
tw(container, med,  { Size = UDim2.new(1, 0, 0, HDR_H) })
tw(stroke,    fast, { Color = T.Border })
tw(divider,   fast, { BackgroundTransparency = 1 })
tw(labelLbl,  fast, { TextColor3 = Color3.fromRGB(225, 225, 225) })
tw(chevron,   med,  { Rotation = 0 })
end

local function doOpen()
open = true
tw(container, med,  { Size = UDim2.new(1, 0, 0, HDR_H + 1 + LIST_H) })
tw(stroke,    fast, { Color = T.BorderFocus })
tw(divider,   fast, { BackgroundTransparency = 0 })
tw(labelLbl,  fast, { TextColor3 = T.Primary })
tw(chevron,   med,  { Rotation = 180 })
end

for i, item in ipairs(items) do
local isSel = (item == selected)
local ib = inst("TextButton", {
Name                   = "Item_" .. i,
Size                   = UDim2.new(1, 0, 0, ITEM_H),
BackgroundColor3       = isSel and Color3.fromRGB(50, 24, 12) or T.SurfaceHover,
BackgroundTransparency = isSel and 0 or 1,
Text                   = "",
BorderSizePixel        = 0,
LayoutOrder            = i,
AutoButtonColor        = false,
ZIndex                 = 6,
Parent                 = scrollList,
})
corner(ib, 4)
local accentBar = inst("Frame", {
Name                   = "AccentBar",
Size                   = UDim2.new(0, 3, 0, isSel and 14 or 0),
AnchorPoint            = Vector2.new(0, 0.5),
Position               = UDim2.new(0, 0, 0.5, 0),
BackgroundColor3       = T.Primary,
BackgroundTransparency = isSel and 0 or 1,
BorderSizePixel        = 0,
ZIndex                 = 7,
Parent                 = ib,
})
corner(accentBar, 2)
inst("TextLabel", {
Name                   = "ItemLabel",
Size                   = UDim2.new(1, -20, 1, 0),
Position               = UDim2.new(0, 12, 0, 0),
BackgroundTransparency = 1,
Text                   = item,
TextColor3             = isSel and T.Primary or T.TextSecondary,
TextSize               = 12,
Font                   = isSel and Enum.Font.GothamMedium or Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
TextTruncate           = Enum.TextTruncate.AtEnd,
ZIndex                 = 7,
Parent                 = ib,
})
itemBtns[item] = ib
ib.MouseEnter:Connect(function()
if item ~= selected then
tw(ib, fast, { BackgroundTransparency = 0, BackgroundColor3 = T.SurfaceHover })
local lbl = ib:FindFirstChild("ItemLabel")
if lbl then tw(lbl, fast, { TextColor3 = T.TextPrimary }) end
end
end)
ib.MouseLeave:Connect(function()
if item ~= selected then
tw(ib, fast, { BackgroundTransparency = 1 })
local lbl = ib:FindFirstChild("ItemLabel")
if lbl then tw(lbl, fast, { TextColor3 = T.TextSecondary }) end
end
end)
ib.MouseButton1Down:Connect(function()
tw(ib, fast, { BackgroundColor3 = T.SurfaceActive, BackgroundTransparency = 0 })
end)
ib.MouseButton1Click:Connect(function()
if itemBtns[selected] then setActive(itemBtns[selected], false) end
selected    = item
selLbl.Text = item
setActive(ib, true)
doClose()
if callback then callback(selected) end
end)
end

hdrBtn.MouseButton1Click:Connect(function()
if open then doClose() else doOpen() end
end)
hdrBtn.MouseEnter:Connect(function()
if not open then tw(container, fast, { BackgroundColor3 = T.SurfaceHover }) end
end)
hdrBtn.MouseLeave:Connect(function()
if not open then tw(container, fast, { BackgroundColor3 = T.Surface }) end
end)

return {
Get = function() return selected end,
Set = function(v)
if itemBtns[selected] then setActive(itemBtns[selected], false) end
selected    = v
selLbl.Text = v
if itemBtns[v] then setActive(itemBtns[v], true) end
end,
}

end

function PrestigeUI:Toast(message, kind, duration)
kind     = kind     or "info"
duration = duration or 3

local colorMap = { success = T.Success, warning = T.Warning, error = T.Error, info = T.Info }
local iconMap  = { success = "circle-check", warning = "triangle-alert", error = "circle-x", info = "info" }
local accent   = colorMap[kind] or T.Info
local iconName = iconMap[kind]

local pGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local tGui = pGui:FindFirstChild("PrestigeUI_Toasts")
if not tGui then
tGui = inst("ScreenGui", {
Name           = "PrestigeUI_Toasts",
ResetOnSpawn   = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
Parent         = pGui,
})
inst("UIListLayout", {
SortOrder           = Enum.SortOrder.LayoutOrder,
HorizontalAlignment = Enum.HorizontalAlignment.Right,
VerticalAlignment   = Enum.VerticalAlignment.Bottom,
Padding             = UDim.new(0, 8),
Parent              = tGui,
})
mkPad(tGui, 0, 16, 16, 0)
end

local toast = inst("Frame", {
Size                   = UDim2.new(0, 300, 0, 52),
BackgroundColor3       = T.Surface,
BackgroundTransparency = 1,
BorderSizePixel        = 0,
ZIndex                 = 100,
Parent                 = tGui,
})
corner(toast, 5)
mkStroke(toast, T.WindowBorder, 1)

inst("Frame", {
Size             = UDim2.new(0, 3, 1, 0),
BackgroundColor3 = accent,
BorderSizePixel  = 0,
ZIndex           = 101,
Parent           = toast,
})

local iconPlaced = mkIcon(toast, iconName, 15, accent, 102, Vector2.new(0, 0.5), UDim2.new(0, 12, 0.5, 0))
if not iconPlaced then
local fallback = { success = "OK", warning = "!", error = "X", info = "i" }
inst("TextLabel", {
Size                   = UDim2.new(0, 30, 1, 0),
Position               = UDim2.new(0, 6, 0, 0),
BackgroundTransparency = 1,
Text                   = fallback[kind] or "i",
TextColor3             = accent,
TextSize               = 14,
Font                   = Enum.Font.GothamBold,
ZIndex                 = 102,
Parent                 = toast,
})
end

inst("TextLabel", {
Size                   = UDim2.new(1, -50, 1, 0),
Position               = UDim2.new(0, 44, 0, 0),
BackgroundTransparency = 1,
Text                   = message,
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
TextWrapped            = true,
ZIndex                 = 101,
Parent                 = toast,
})

tw(toast, med, { BackgroundTransparency = 0 })
task.delay(duration, function()
tw(toast, med, { BackgroundTransparency = 1 })
task.delay(0.25, function() toast:Destroy() end)
end)
return toast

end

function PrestigeUI:CreateSettingsTab()
local TAB_TITLE = "Settings"
self._tabOrder = self._tabOrder + 1

local btn = inst("Frame", {
Name             = "TabBtn_Settings",
Size             = UDim2.new(1, 0, 0, TAB_H),
BackgroundColor3 = T.TabNormal,
BorderSizePixel  = 0,
LayoutOrder      = 999,
ZIndex           = 5,
Parent           = self._tabList,
})
corner(btn, 5)

local indicator = inst("Frame", {
Size             = UDim2.new(0, 3, 0.55, 0),
Position         = UDim2.new(0, 0, 0.225, 0),
BackgroundColor3 = T.PrimaryText,
BorderSizePixel  = 0,
Visible          = false,
ZIndex           = 6,
Parent           = btn,
})
corner(indicator, 2)

local settingsIcon = mkIcon(btn, "settings", TAB_ICON_S, T.IconTint, 6, Vector2.new(0, 0.5), UDim2.new(0, 10, 0.5, 0))
local textOff = settingsIcon and (10 + TAB_ICON_S + 7) or 10

local btnLabel = inst("TextLabel", {
Size                   = UDim2.new(1, -(textOff + 4), 1, 0),
Position               = UDim2.new(0, textOff, 0, 0),
BackgroundTransparency = 1,
Text                   = TAB_TITLE,
TextColor3             = T.TabNormalText,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 6,
Parent                 = btn,
})

local clickArea = inst("TextButton", {
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
Text                   = "",
ZIndex                 = 7,
Parent                 = btn,
})

local panel = inst("ScrollingFrame", {
Name                   = "Panel_Settings",
Size                   = UDim2.new(1, 0, 1, 0),
BackgroundTransparency = 1,
BorderSizePixel        = 0,
ScrollBarThickness     = 5,
ScrollBarImageColor3   = T.ScrollBar,
ScrollingDirection     = Enum.ScrollingDirection.Y,
CanvasSize             = UDim2.new(0, 0, 0, 0),
AutomaticCanvasSize    = Enum.AutomaticSize.None,
ElasticBehavior        = Enum.ElasticBehavior.Never,
Visible                = false,
ZIndex                 = 4,
Parent                 = self._contentArea,
})

local inner = inst("Frame", {
Size                   = UDim2.new(1, -8, 0, 0),
AutomaticSize          = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
ZIndex                 = 4,
Parent                 = panel,
})
mkPad(inner, 20, 20, 20, 20)

local listLayout = inst("UIListLayout", {
SortOrder           = Enum.SortOrder.LayoutOrder,
FillDirection       = Enum.FillDirection.Vertical,
HorizontalAlignment = Enum.HorizontalAlignment.Left,
VerticalAlignment   = Enum.VerticalAlignment.Top,
Padding             = UDim.new(0, 12),
Parent              = inner,
})
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
panel.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 40)
end)


local headerFrame = inst("Frame", {
Name                   = "PanelHeader",
Size                   = UDim2.new(1, 0, 0, 26),
BackgroundTransparency = 1,
LayoutOrder            = 0,
ZIndex                 = 4,
Parent                 = inner,
})
local hdrIcon = mkIcon(headerFrame, "settings", 18, T.Primary, 5, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
local hdrIconW = hdrIcon and 26 or 0
inst("TextLabel", {
Size                   = UDim2.new(1, -hdrIconW, 1, 0),
Position               = UDim2.new(0, hdrIconW, 0, 0),
BackgroundTransparency = 1,
Text                   = "Settings",
TextColor3             = T.TextPrimary,
TextSize               = 16,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 5,
Parent                 = headerFrame,
})

inst("Frame", {
Name             = "Divider",
Size             = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
LayoutOrder      = 1,
ZIndex           = 4,
Parent           = inner,
})


inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 16),
BackgroundTransparency = 1,
Text                   = "APPEARANCE",
TextColor3             = T.TextMuted,
TextSize               = 10,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
LayoutOrder            = 2,
ZIndex                 = 4,
Parent                 = inner,
})


local themeNames = {"Ocean", "Nebula", "Sky", "Sunset", "Forest", "Midnight", "Rose", "Gold"}
local themeAccents = {
Ocean    = Color3.fromRGB(0,   168, 204),
Nebula   = Color3.fromRGB(168, 60,  220),
Sky      = Color3.fromRGB(80,  160, 255),
Sunset   = Color3.fromRGB(255, 90,  60),
Forest   = Color3.fromRGB(60,  190, 90),
Midnight = Color3.fromRGB(110, 110, 255),
Rose     = Color3.fromRGB(240, 80,  140),
Gold     = Color3.fromRGB(220, 175, 40),
}

local pickerGrid = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 0),
AutomaticSize    = Enum.AutomaticSize.Y,
BackgroundTransparency = 1,
LayoutOrder      = 3,
ZIndex           = 4,
Parent           = inner,
})
inst("UIGridLayout", {
CellSize    = UDim2.new(0, 0, 0, 72),
CellPadding = UDim2.new(0, 8, 0, 8),
SortOrder   = Enum.SortOrder.LayoutOrder,
Parent      = pickerGrid,
})

local gridLayout = pickerGrid:FindFirstChildWhichIsA("UIGridLayout")
pickerGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
local cols = 4
local totalPad = 8 * (cols - 1)
local cellW = math.floor((pickerGrid.AbsoluteSize.X - totalPad) / cols)
gridLayout.CellSize = UDim2.new(0, cellW, 0, 72)
end)

local themeBtns = {}
local self_ref = self

local function refreshThemeBtns()
for name, data in pairs(themeBtns) do
local isActive = (self_ref._currentTheme == name)
tw(data.card, fast, {
BackgroundColor3 = isActive and Color3.fromRGB(themeAccents[name].R*255*0.22, themeAccents[name].G*255*0.22, themeAccents[name].B*255*0.22) or T.Surface,
})
local stroke = data.card:FindFirstChildWhichIsA("UIStroke")
if stroke then
tw(stroke, fast, { Color = isActive and themeAccents[name] or T.Border, Thickness = isActive and 2 or 1 })
end
data.check.Visible = isActive
end
end

for i, name in ipairs(themeNames) do
local accent = themeAccents[name]
local isActive = (self._currentTheme == name)

local card = inst("TextButton", {
	BackgroundColor3 = isActive and Color3.fromRGB(40, 30, 60) or T.Surface,
	BorderSizePixel  = 0,
	Text             = "",
	AutoButtonColor  = false,
	LayoutOrder      = i,
	ZIndex           = 5,
	Parent           = pickerGrid,
})
corner(card, 8)
local cardStroke = inst("UIStroke", {
	Color     = isActive and accent or T.Border,
	Thickness = isActive and 2 or 1,
	Parent    = card,
})

-- Color swatch strip at top
local swatch = inst("Frame", {
	Size             = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = accent,
	BorderSizePixel  = 0,
	ZIndex           = 6,
	Parent           = card,
})
local swatchCorner = Instance.new("UICorner")
swatchCorner.CornerRadius = UDim.new(0, 8)
swatchCorner.Parent = swatch
-- flat bottom on swatch
inst("Frame", {
	Size             = UDim2.new(1, 0, 0, 10),
	Position         = UDim2.new(0, 0, 1, -10),
	BackgroundColor3 = accent,
	BorderSizePixel  = 0,
	ZIndex           = 6,
	Parent           = swatch,
})

-- Theme name label
inst("TextLabel", {
	Size                   = UDim2.new(1, -8, 0, 18),
	Position               = UDim2.new(0, 4, 0, 32),
	BackgroundTransparency = 1,
	Text                   = name,
	TextColor3             = T.TextPrimary,
	TextSize               = 11,
	Font                   = Enum.Font.GothamMedium,
	TextXAlignment         = Enum.TextXAlignment.Center,
	ZIndex                 = 6,
	Parent                 = card,
})

-- Checkmark for active
local check = inst("Frame", {
	Size             = UDim2.new(0, 16, 0, 16),
	Position         = UDim2.new(1, -20, 0, 4),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel  = 0,
	Visible          = isActive,
	ZIndex           = 7,
	Parent           = card,
})
corner(check, 8)
mkIcon(check, "check", 10, accent, 8, Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0))

themeBtns[name] = { card = card, check = check }

card.MouseEnter:Connect(function()
	if self_ref._currentTheme ~= name then
		tw(card, fast, { BackgroundColor3 = T.SurfaceHover })
	end
end)
card.MouseLeave:Connect(function()
	if self_ref._currentTheme ~= name then
		tw(card, fast, { BackgroundColor3 = T.Surface })
	end
end)
card.MouseButton1Click:Connect(function()
	self_ref._currentTheme = name
	applyTheme(name)
	refreshThemeBtns()
end)


end


inst("Frame", {
Name             = "Divider2",
Size             = UDim2.new(1, 0, 0, 1),
BackgroundColor3 = T.Border,
BorderSizePixel  = 0,
LayoutOrder      = 4,
ZIndex           = 4,
Parent           = inner,
})

inst("TextLabel", {
Size                   = UDim2.new(1, 0, 0, 16),
BackgroundTransparency = 1,
Text                   = "KEYBIND",
TextColor3             = T.TextMuted,
TextSize               = 10,
Font                   = Enum.Font.GothamBold,
TextXAlignment         = Enum.TextXAlignment.Left,
LayoutOrder            = 5,
ZIndex                 = 4,
Parent                 = inner,
})

local keybindRow = inst("Frame", {
Size             = UDim2.new(1, 0, 0, 40),
BackgroundColor3 = T.Surface,
BorderSizePixel  = 0,
LayoutOrder      = 6,
ZIndex           = 4,
Parent           = inner,
})
corner(keybindRow, 6)
mkStroke(keybindRow, T.Border, 1)
mkPad(keybindRow, 0, 14, 0, 14)

mkIcon(keybindRow, "keyboard", 14, T.TextSecondary, 5, Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
inst("TextLabel", {
Size                   = UDim2.new(0.6, 0, 1, 0),
Position               = UDim2.new(0, 22, 0, 0),
BackgroundTransparency = 1,
Text                   = "Toggle UI",
TextColor3             = T.TextPrimary,
TextSize               = 13,
Font                   = Enum.Font.Gotham,
TextXAlignment         = Enum.TextXAlignment.Left,
ZIndex                 = 5,
Parent                 = keybindRow,
})

local keybindPill = inst("Frame", {
Size             = UDim2.new(0, 0, 0, 24),
AutomaticSize    = Enum.AutomaticSize.X,
AnchorPoint      = Vector2.new(1, 0.5),
Position         = UDim2.new(1, 0, 0.5, 0),
BackgroundColor3 = T.SurfaceActive,
BorderSizePixel  = 0,
ZIndex           = 5,
Parent           = keybindRow,
})
corner(keybindPill, 5)
mkPad(keybindPill, 0, 10, 0, 10)

local keybindLbl = inst("TextLabel", {
Size                   = UDim2.new(0, 0, 1, 0),
AutomaticSize          = Enum.AutomaticSize.X,
BackgroundTransparency = 1,
Text                   = tostring(self._keybind or "RightShift"):gsub("Enum.KeyCode.", ""),
TextColor3             = T.Primary,
TextSize               = 11,
Font                   = Enum.Font.GothamMedium,
TextXAlignment         = Enum.TextXAlignment.Center,
ZIndex                 = 6,
Parent                 = keybindPill,
})


_onThemeChange(function(t)
keybindRow.BackgroundColor3 = t.Surface
keybindPill.BackgroundColor3 = t.SurfaceActive
keybindLbl.TextColor3 = t.Primary
end)


local tabData = {
name      = TAB_TITLE,
btn       = btn,
btnLabel  = btnLabel,
iconImg   = settingsIcon,
indicator = indicator,
panel     = panel,
}
table.insert(self._tabs, tabData)
self._tabData[TAB_TITLE] = tabData

clickArea.MouseEnter:Connect(function()
if self._activeTab ~= TAB_TITLE then
tw(btn, fast, { BackgroundColor3 = T.TabHover })
tw(btnLabel, fast, { TextColor3 = T.TextPrimary })
end
end)
clickArea.MouseLeave:Connect(function()
if self._activeTab ~= TAB_TITLE then
tw(btn, fast, { BackgroundColor3 = T.TabNormal })
tw(btnLabel, fast, { TextColor3 = T.TabNormalText })
if settingsIcon then tw(settingsIcon, fast, { ImageColor3 = T.IconTint }) end
end
end)
clickArea.MouseButton1Click:Connect(function()
self:_switchTab(TAB_TITLE)
end)

end

function PrestigeUI:Destroy()
if self._acrylic then
self._acrylic.Destroy()
end
self.ScreenGui:Destroy()
end


 
function PrestigeUI.ShowStartup(cfg, onDone)
cfg = cfg or {}
local title    = cfg.Title   or "PrestigeUI"
local version  = cfg.Version or "v1.0"
local duration = cfg.Duration or 3
local themeName = cfg.Theme or "Ocean"
local thm = Themes[themeName] or Themes.Ocean

PrestigeUI.ShowStartup({Title="MyScript", Version="v1.0",
Duration=3, Theme="Ocean" }, 
function()
end)

local pGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name           = "PrestigeUI_Startup"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = pGui

-- Full-screen dark overlay
local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = Color3.fromRGB(4, 4, 10)
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 1
overlay.Parent                 = sg

-- Animated accent ring
local ringSize = 90
local ring = Instance.new("Frame")
ring.Size            = UDim2.new(0, ringSize, 0, ringSize)
ring.AnchorPoint     = Vector2.new(0.5, 0.5)
ring.Position        = UDim2.new(0.5, 0, 0.42, 0)
ring.BackgroundColor3 = thm.Primary
ring.BackgroundTransparency = 0.3
ring.BorderSizePixel = 0
ring.ZIndex          = 2
ring.Parent          = overlay
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = ring

-- Inner dot
local dot = Instance.new("Frame")
dot.Size            = UDim2.new(0, ringSize - 18, 0, ringSize - 18)
dot.AnchorPoint     = Vector2.new(0.5, 0.5)
dot.Position        = UDim2.new(0.5, 0, 0.5, 0)
dot.BackgroundColor3 = thm.WindowBg
dot.BorderSizePixel  = 0
dot.ZIndex           = 3
dot.Parent           = ring
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

-- Title label
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                   = UDim2.new(0, 400, 0, 40)
titleLbl.AnchorPoint            = Vector2.new(0.5, 0)
titleLbl.Position               = UDim2.new(0.5, 0, 0.42 + (ringSize/2 + 18) / sg.AbsoluteSize.Y, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = title
titleLbl.TextColor3             = thm.TextPrimary
titleLbl.TextSize               = 26
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
titleLbl.TextTransparency       = 1
titleLbl.ZIndex                 = 2
titleLbl.Parent                 = overlay

-- Version label
local verLbl = Instance.new("TextLabel")
verLbl.Size                   = UDim2.new(0, 400, 0, 20)
verLbl.AnchorPoint            = Vector2.new(0.5, 0)
verLbl.Position               = UDim2.new(0.5, 0, 0.42 + (ringSize/2 + 62) / sg.AbsoluteSize.Y, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text                   = version
verLbl.TextColor3             = thm.Primary
verLbl.TextSize               = 13
verLbl.Font                   = Enum.Font.GothamMedium
verLbl.TextXAlignment         = Enum.TextXAlignment.Center
verLbl.TextTransparency       = 1
verLbl.ZIndex                 = 2
verLbl.Parent                 = overlay

-- Progress bar container
local barW = 200
local barCont = Instance.new("Frame")
barCont.Size             = UDim2.new(0, barW, 0, 3)
barCont.AnchorPoint      = Vector2.new(0.5, 0)
barCont.Position         = UDim2.new(0.5, 0, 0.42 + (ringSize/2 + 90) / sg.AbsoluteSize.Y, 0)
barCont.BackgroundColor3 = thm.Border
barCont.BorderSizePixel  = 0
barCont.ZIndex           = 2
barCont.Parent           = overlay
local barContCorner = Instance.new("UICorner")
barContCorner.CornerRadius = UDim.new(1, 0)
barContCorner.Parent = barCont

local barFill = Instance.new("Frame")
barFill.Size             = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = thm.Primary
barFill.BorderSizePixel  = 0
barFill.ZIndex           = 3
barFill.Parent           = barCont
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local twInfo   = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local twSlow   = TweenInfo.new(duration * 0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local twFade   = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Pulse ring animation
local function pulseRing()
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.65,
		Size = UDim2.new(0, ringSize + 8, 0, ringSize + 8),
	}):Play()
end

task.spawn(function()
	task.wait(0.15)
	-- Fade in text
	TweenService:Create(titleLbl, twInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(verLbl,   twInfo, { TextTransparency = 0 }):Play()
	pulseRing()
	-- Progress bar fill
	TweenService:Create(barFill, twSlow, { Size = UDim2.new(1, 0, 1, 0) }):Play()

	task.wait(duration)

	-- Fade out everything
	TweenService:Create(overlay, twFade, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLbl, twFade, { TextTransparency = 1 }):Play()
	TweenService:Create(verLbl,   twFade, { TextTransparency = 1 }):Play()
	TweenService:Create(barCont,  twFade, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(barFill,  twFade, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(ring,     twFade, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(dot,      twFade, { BackgroundTransparency = 1 }):Play()

	task.wait(0.55)
	sg:Destroy()
	if onDone then onDone() end
end)


end

    
function PrestigeUI.PromptKey(cfg, onResult)
cfg = cfg or {}
local validKey  = cfg.Key or ""
local title     = cfg.Title or "PrestigeUI"
local themeName = cfg.Theme or "Ocean"
local thm = Themes[themeName] or Themes.Ocean

PrestigeUI.PromptKey({ Key="MYKEY-1234", Title="MyScript",
    Theme="Ocean" }, function(success)
    if success then
end
end)

local pGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui")
sg.Name           = "PrestigeUI_KeySystem"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = pGui

-- Blurred dark overlay
local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = Color3.fromRGB(4, 4, 10)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 1
overlay.Parent                 = sg

-- Card
local cardW, cardH = 360, 220
local card = Instance.new("Frame")
card.Size            = UDim2.new(0, cardW, 0, cardH)
card.AnchorPoint     = Vector2.new(0.5, 0.5)
card.Position        = UDim2.new(0.5, 0, 0.5, 0)
card.BackgroundColor3 = thm.WindowBg
card.BorderSizePixel  = 0
card.ZIndex           = 2
card.Parent           = overlay
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card
local cardStroke = Instance.new("UIStroke")
cardStroke.Color     = thm.WindowBorder
cardStroke.Thickness = 1
cardStroke.Parent    = card

-- Accent top bar
local accentBar = Instance.new("Frame")
accentBar.Size             = UDim2.new(1, 0, 0, 3)
accentBar.BackgroundColor3 = thm.Primary
accentBar.BorderSizePixel  = 0
accentBar.ZIndex           = 3
accentBar.Parent           = card
local abCorner = Instance.new("UICorner")
abCorner.CornerRadius = UDim.new(0, 12)
abCorner.Parent = accentBar
-- flatten bottom corners of accent bar
local abFlat = Instance.new("Frame")
abFlat.Size             = UDim2.new(1, 0, 0.5, 0)
abFlat.Position         = UDim2.new(0, 0, 0.5, 0)
abFlat.BackgroundColor3 = thm.Primary
abFlat.BorderSizePixel  = 0
abFlat.ZIndex           = 3
abFlat.Parent           = accentBar

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                   = UDim2.new(1, -20, 0, 28)
titleLbl.Position               = UDim2.new(0, 10, 0, 16)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = title .. " -- Key Required"
titleLbl.TextColor3             = thm.TextPrimary
titleLbl.TextSize               = 15
titleLbl.Font                   = Enum.Font.GothamBold
titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
titleLbl.ZIndex                 = 3
titleLbl.Parent                 = card

local subLbl = Instance.new("TextLabel")
subLbl.Size                   = UDim2.new(1, -20, 0, 18)
subLbl.Position               = UDim2.new(0, 10, 0, 46)
subLbl.BackgroundTransparency = 1
subLbl.Text                   = "Enter your access key to continue"
subLbl.TextColor3             = thm.TextMuted
subLbl.TextSize               = 11
subLbl.Font                   = Enum.Font.Gotham
subLbl.TextXAlignment         = Enum.TextXAlignment.Center
subLbl.ZIndex                 = 3
subLbl.Parent                 = card

-- Input box container
local inputCont = Instance.new("Frame")
inputCont.Size             = UDim2.new(1, -28, 0, 38)
inputCont.Position         = UDim2.new(0, 14, 0, 74)
inputCont.BackgroundColor3 = thm.Surface
inputCont.BorderSizePixel  = 0
inputCont.ZIndex           = 3
inputCont.Parent           = card
local icCorner = Instance.new("UICorner")
icCorner.CornerRadius = UDim.new(0, 6)
icCorner.Parent = inputCont
local icStroke = Instance.new("UIStroke")
icStroke.Color     = thm.Border
icStroke.Thickness = 1
icStroke.Parent    = inputCont

local keyBox = Instance.new("TextBox")
keyBox.Size                   = UDim2.new(1, -16, 1, 0)
keyBox.Position               = UDim2.new(0, 8, 0, 0)
keyBox.BackgroundTransparency = 1
keyBox.PlaceholderText        = "Enter key..."
keyBox.PlaceholderColor3      = thm.TextMuted
keyBox.Text                   = ""
keyBox.TextColor3             = thm.TextPrimary
keyBox.TextSize               = 13
keyBox.Font                   = Enum.Font.GothamMedium
keyBox.ClearTextOnFocus       = false
keyBox.ZIndex                 = 4
keyBox.Parent                 = inputCont

keyBox.Focused:Connect(function()
	TweenService:Create(icStroke, TweenInfo.new(0.12), { Color = thm.BorderFocus }):Play()
end)
keyBox.FocusLost:Connect(function()
	TweenService:Create(icStroke, TweenInfo.new(0.12), { Color = thm.Border }):Play()
end)

-- Status label (hidden until attempt)
local statusLbl = Instance.new("TextLabel")
statusLbl.Size                   = UDim2.new(1, -28, 0, 16)
statusLbl.Position               = UDim2.new(0, 14, 0, 118)
statusLbl.BackgroundTransparency = 1
statusLbl.Text                   = ""
statusLbl.TextColor3             = thm.Error
statusLbl.TextSize               = 11
statusLbl.Font                   = Enum.Font.Gotham
statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
statusLbl.ZIndex                 = 3
statusLbl.Parent                 = card

-- Submit button
local submitBtn = Instance.new("TextButton")
submitBtn.Size             = UDim2.new(1, -28, 0, 36)
submitBtn.Position         = UDim2.new(0, 14, 0, 140)
submitBtn.BackgroundColor3 = thm.Primary
submitBtn.Text             = "Unlock"
submitBtn.TextColor3       = thm.PrimaryText
submitBtn.TextSize         = 13
submitBtn.Font             = Enum.Font.GothamMedium
submitBtn.BorderSizePixel  = 0
submitBtn.AutoButtonColor  = false
submitBtn.ZIndex           = 3
submitBtn.Parent           = card
local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 6)
sbCorner.Parent = submitBtn

submitBtn.MouseEnter:Connect(function()
	TweenService:Create(submitBtn, TweenInfo.new(0.12), { BackgroundColor3 = thm.PrimaryHover }):Play()
end)
submitBtn.MouseLeave:Connect(function()
	TweenService:Create(submitBtn, TweenInfo.new(0.12), { BackgroundColor3 = thm.Primary }):Play()
end)

local attempts = 0
local function tryKey()
	local entered = keyBox.Text
	if entered == validKey then
		statusLbl.Text       = "Access granted!"
		statusLbl.TextColor3 = thm.Success
		submitBtn.Text       = "..."
		task.wait(0.6)
		TweenService:Create(overlay, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card,    TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
		task.wait(0.4)
		sg:Destroy()
		if onResult then onResult(true) end
	else
		attempts = attempts + 1
		statusLbl.Text       = "Invalid key. Attempt " .. attempts
		statusLbl.TextColor3 = thm.Error
		TweenService:Create(icStroke, TweenInfo.new(0.12), { Color = thm.Error }):Play()
		-- Shake animation
		local origPos = card.Position
		for _, offset in ipairs({8, -8, 5, -5, 2, -2, 0}) do
			card.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + offset, origPos.Y.Scale, origPos.Y.Offset)
			task.wait(0.04)
		end
		task.wait(0.8)
		TweenService:Create(icStroke, TweenInfo.new(0.12), { Color = thm.Border }):Play()
	end
end

submitBtn.MouseButton1Click:Connect(tryKey)
keyBox.FocusLost:Connect(function(enter)
	if enter then tryKey() end
end)

-- Fade card in
card.BackgroundTransparency = 1
TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0
}):Play()
end
return PrestigeUI