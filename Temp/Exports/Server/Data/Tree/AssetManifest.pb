
G�������Cube - Bottom-AlignedR!
StaticMeshAssetRefsm_cube_001
����𕷹�PlayerTitles_ScoreboardZȄ��--[[

	Player Titles - Scoreboard (Client)
	1.0.2 - 2020/10/13
	Contributors
		Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--]]

------------------------------------------------------------------------------------------------------------------------
--	EXTERNAL SCRIPTS AND APIS
------------------------------------------------------------------------------------------------------------------------
local PlayerTitles = require(script:GetCustomProperty("PlayerTitles"))
local EaseUI = require(script:GetCustomProperty("EaseUI"))

------------------------------------------------------------------------------------------------------------------------
--	OBJECTS AND REFERENCES
------------------------------------------------------------------------------------------------------------------------
local Scoreboard = script:GetCustomProperty("Scoreboard"):WaitForObject()
local ScoreboardEntryTemplate = script:GetCustomProperty("ScoreboardEntryTemplate")
local ScoreboardLeaderstatHeaderTemplate = script:GetCustomProperty("ScoreboardLeaderstatHeaderTemplate")
local ScoreboardLeaderstatPlayerTemplate = script:GetCustomProperty("ScoreboardLeaderstatPlayerTemplate")

local Content = script:GetCustomProperty("Content"):WaitForObject()
local Entries = script:GetCustomProperty("Entries"):WaitForObject()
local HeaderLeaderstats = script:GetCustomProperty("HeaderLeaderstats"):WaitForObject()
local HeaderTeamColor = script:GetCustomProperty("HeaderTeamColor"):WaitForObject()
local HeaderPlayerName = script:GetCustomProperty("HeaderPlayerName"):WaitForObject()
local HeaderSocialIcon = script:GetCustomProperty("HeaderSocialIcon"):WaitForObject()
local HeaderSocialPrefix = script:GetCustomProperty("HeaderSocialPrefix"):WaitForObject()

local LeaderstatsGroup = script:GetCustomProperty("Leaderstats"):WaitForObject()

local LocalPlayer = Game.GetLocalPlayer()

------------------------------------------------------------------------------------------------------------------------
--	CONSTANTS
------------------------------------------------------------------------------------------------------------------------
local PLAYER_NAME_COLOR_MODE = Scoreboard:GetCustomProperty("PlayerNameColorMode")
local PLAYER_NAME_COLOR = Scoreboard:GetCustomProperty("PlayerNameColor")

local NEUTRAL_TEAM_COLOR = Scoreboard:GetCustomProperty("NeutralTeamColor")
local FRIENDLY_TEAM_COLOR = Scoreboard:GetCustomProperty("FriendlyTeamColor")
local ENEMY_TEAM_COLOR = Scoreboard:GetCustomProperty("EnemyTeamColor")

local SHOW_TITLE_ICON = Scoreboard:GetCustomProperty("ShowTitleIcon")
local SHOW_TITLE_PREFIX = Scoreboard:GetCustomProperty("ShowTitlePrefix")

local GAP_BETWEEN_ENTRIES = Scoreboard:GetCustomProperty("GapBetweenEntries")

local TOGGLE_BINDING = Scoreboard:GetCustomProperty("ToggleBinding")
local TOGGLE_EVENT = Scoreboard:GetCustomProperty("ToggleEvent")
local FORCE_ON_EVENT = Scoreboard:GetCustomProperty("ForceOnEvent")
local FORCE_OFF_EVENT = Scoreboard:GetCustomProperty("ForceOffEvent")

local EASE_TOGGLE = Scoreboard:GetCustomProperty("EaseToggle")
local EASING_DURATION = Scoreboard:GetCustomProperty("EasingDuration")
local EASING_EQUATION_IN = Scoreboard:GetCustomProperty("EasingEquationIn")
local EASING_DIRECTION_IN = Scoreboard:GetCustomProperty("EasingDirectionIn")
local EASING_EQUATION_OUT = Scoreboard:GetCustomProperty("EasingEquationOut")
local EASING_DIRECTION_OUT = Scoreboard:GetCustomProperty("EasingDirectionOut")

local COLOR_DEFAULT = Color.New(1, 1, 1, 1)

local LEADERSTAT_TYPES = { "KILLS", "DEATHS", "RESOURCE" }
local PLAYER_NAME_COLOR_MODES = { "STATIC", "TEAM", "TITLE" }

------------------------------------------------------------------------------------------------------------------------
--	INITIAL VARIABLES
------------------------------------------------------------------------------------------------------------------------
local localPlayerTitle = PlayerTitles.GetPlayerTitle(LocalPlayer)

local playerTeams = {}
local entries = {}
local isVisible = false

local leaderstatCount = 0

local lastTask

------------------------------------------------------------------------------------------------------------------------
--	LOCAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil CreatePlayerLeaderstat(string, string, string)
--	Creates a leaderstat label for the Header
local function CreateHeaderLeaderstat(leaderstatName, leaderstatType, leaderstatResource)
	if(leaderstatType == "RESOURCE") then
		leaderstatName = ((leaderstatName ~= "") and leaderstatName) or ((leaderstatResource ~= "") and leaderstatResource) or (string.sub(leaderstatType, 1, 1) .. string.lower(string.sub(leaderstatType, 2, #leaderstatType)))
	else
		leaderstatName = ((leaderstatName ~= "") and leaderstatName) or (string.sub(leaderstatType, 1, 1) .. string.lower(string.sub(leaderstatType, 2, #leaderstatType)))
	end

	local leaderstat = World.SpawnAsset(ScoreboardLeaderstatHeaderTemplate, {
		parent = HeaderLeaderstats
	})
	leaderstat.name = leaderstatName
	leaderstat.x = -100 * leaderstatCount
	leaderstat.text = leaderstatName

	leaderstatCount = leaderstatCount + 1
end

--	nil CreatePlayerLeaderstat(Player, CoreObject, string, string, string, int)
--	Creates a leaderstat for a player
local function CreatePlayerLeaderstat(player, playerEntry, leaderstatName, leaderstatType, leaderstatResource, leaderstatCount)
	if(leaderstatType == "RESOURCE") then
		leaderstatName = ((leaderstatName ~= "") and leaderstatName) or ((leaderstatResource ~= "") and leaderstatResource) or (string.sub(leaderstatType, 1, 1) .. string.lower(string.sub(leaderstatType, 2, #leaderstatType)))
	else
		leaderstatName = ((leaderstatName ~= "") and leaderstatName) or (string.sub(leaderstatType, 1, 1) .. string.lower(string.sub(leaderstatType, 2, #leaderstatType)))
	end

	local leaderstat = World.SpawnAsset(ScoreboardLeaderstatPlayerTemplate, {
		parent = playerEntry
	})
	leaderstat.name = leaderstatName
	leaderstat.x = -100 * leaderstatCount

	local entryInformation = playerEntry:GetCustomProperty("Information"):WaitForObject()
	entryInformation.width = entryInformation.width - 100

	local leaderstatText = leaderstat:GetCustomProperty("Text"):WaitForObject()
	leaderstatText.text = tostring(0)

	entries[player].leaderstats[leaderstatName] = {
		name = leaderstatName,
		type = leaderstatType,
		resource = leaderstatResource,
		text = leaderstatText
	}

	return true
end

--	nil UpdatePlayerEntries()
--	Re-orders all of the players in the list
local function UpdatePlayerEntries()
	for index, entry in pairs(Entries:GetChildren()) do
		entry.y = (entry.height * (index - 1)) + (GAP_BETWEEN_ENTRIES * (index - 1))
	end
end

--	nil CreatePlayerEntry(Player)
--	Creates an entry on the Scoreboard for a player
local function CreatePlayerEntry(player)
	playerTeams[player] = player.team

	local title = PlayerTitles.GetPlayerTitle(player)

	local entry = World.SpawnAsset(ScoreboardEntryTemplate, {
		parent = Entries
	})
	entry.name = player.name

	entries[player] = {
		entry = entry,
		leaderstats = {},
	}

	local playerNameText, teamColorImage, playerIconImage, socialIconImage =
		entry:GetCustomProperty("PlayerName"):WaitForObject(),
		entry:GetCustomProperty("TeamColor"):WaitForObject(),
		entry:GetCustomProperty("PlayerIcon"):WaitForObject(),
		entry:GetCustomProperty("SocialIcon"):WaitForObject()

	playerNameText.text = player.name

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_TEAM_COLOR, FRIENDLY_TEAM_COLOR, ENEMY_TEAM_COLOR)
	teamColorImage:SetColor(teamColor)

	playerIconImage:SetImage(player)

	if(SHOW_TITLE_ICON and title and title.icon) then
		socialIconImage:SetImage(title.icon or "")
		socialIconImage:SetColor(title.iconColor or COLOR_DEFAULT)
		socialIconImage.rotationAngle = tonumber(title.iconRotation) or 0
		socialIconImage.width = socialIconImage.width + (title.extraWidth or 0)
		socialIconImage.height = socialIconImage.height + (title.extraHeight or 0)

		playerNameText.x = playerNameText.x + 26
		playerNameText.width = playerNameText.width - 26
	end

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and (PLAYER_NAME_COLOR_MODE == "TITLE")) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	elseif((PLAYER_NAME_COLOR_MODE == "STATIC") and title and title.showPrefixColorWhileStatic) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end

	local count = 0
	local leaderstats = LeaderstatsGroup:GetChildren()
	for index = #leaderstats, 1, -1 do
		local leaderstat = leaderstats[index]
		local enabled, lType, resource =
			leaderstat:GetCustomProperty("Enabled"),
			leaderstat:GetCustomProperty("Type"),
			leaderstat:GetCustomProperty("Resource")
		if(enabled) then
			local success = CreatePlayerLeaderstat(player, entry, leaderstat.name, lType, resource, count)
			if(success) then
				count = count + 1
			end
		end
	end

	UpdatePlayerEntries()
end

--	nil DeletePlayerEntry(Player)
--	Deletes an entry on the Scoreboard for a player
local function DeletePlayerEntry(player)
	playerTeams[player] = nil

	entries[player] = nil

	local entry = Entries:FindChildByName(player.name)
	if(not entry) then return end

	entry:Destroy()

	UpdatePlayerEntries()
end

--	nil UpdatePlayerEntry(Player)
--	Updates the name color and team color of a player on the Scoreboard
local function UpdatePlayerEntry(player)
	playerTeams[player] = player.team

	local entry = Entries:FindChildByName(player.name)
	if(not entry) then return end

	local title = PlayerTitles.GetPlayerTitle(player)

	local playerNameText, teamColorImage =
		entry:GetCustomProperty("PlayerName"):WaitForObject(),
		entry:GetCustomProperty("TeamColor"):WaitForObject()

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_TEAM_COLOR, FRIENDLY_TEAM_COLOR, ENEMY_TEAM_COLOR)
	teamColorImage:SetColor(teamColor)

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and PLAYER_NAME_COLOR_MODE == "TITLE") then
		playerNameText:SetColor(title.prefixColor or Color.New(0.1, 0.1, 0.1))
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end
end

--	nil UpdateHeader()
--	Updates the name color and team color for the LocalPlayer on the Header
local function UpdateHeader()
	local isNeutral = LocalPlayer.team == 0

	if(isNeutral) then
		HeaderTeamColor:SetColor(NEUTRAL_TEAM_COLOR)
	else
		HeaderTeamColor:SetColor(FRIENDLY_TEAM_COLOR)
	end

	HeaderPlayerName:SetColor(PLAYER_NAME_COLOR)
	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		if(isNeutral) then
			HeaderPlayerName:SetColor(NEUTRAL_TEAM_COLOR)
		else
			HeaderPlayerName:SetColor(FRIENDLY_TEAM_COLOR)
		end
	--[[elseif(localPlayerTitle and PLAYER_NAME_COLOR_MODE == "TITLE") then
		HeaderPlayerName:SetColor(localPlayerTitle.prefixColor or COLOR_DEFAULT)]]
	else
		HeaderPlayerName:SetColor(PLAYER_NAME_COLOR)
	end
end

--	string GetProperty(string, table)
--	Returns a value (string) based on a table of default options (strings)
local function GetProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

--	nil OnBindingReleased(Player, string)
--	Toggles the PlayerList on release of the TOGGLE_BINDING
local function OnBindingReleased(player, binding)
	if(binding ~= TOGGLE_BINDING) then return end

	ForceToggle()
end

--	nil UpdatePlayer(Player)
--	Updates the leaderstats for a player
local function UpdatePlayer(player)
	local entry = entries[player]
	if(not entry) then return end

	for leaderstatName, leaderstat in pairs(entry.leaderstats) do
		local leaderstatType = leaderstat.type

		if(leaderstatType == "KILLS") then
			leaderstat.text.text = tostring(player.kills)
		elseif(leaderstatType == "DEATHS") then
			leaderstat.text.text = tostring(player.deaths)
		elseif(leaderstatType == "RESOURCE") then
			leaderstat.text.text = tostring(player:GetResource(leaderstat.resource) or 0)
		end
	end
end

local function CreateHeaderLeaderstats()
	local count = 0
	local leaderstats = LeaderstatsGroup:GetChildren()
	for index = #leaderstats, 1, -1 do
		local leaderstat = leaderstats[index]
		local enabled, lType, resource =
			leaderstat:GetCustomProperty("Enabled"),
			leaderstat:GetCustomProperty("Type"),
			leaderstat:GetCustomProperty("Resource")

		if(enabled) then
			CreateHeaderLeaderstat(leaderstat.name, lType, resource)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
--	GLOBAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil ForceOn()
--	Forces the visibility of the PlayerList to ON
function ForceOn()
	isVisible = true

	Content.visibility = Visibility.FORCE_ON
	if(EASE_TOGGLE) then
		EaseUI.EaseY(Content, 0, EASING_DURATION, EASING_EQUATION_IN, EASING_DIRECTION_IN)
	end
end

--	nil ForceOff()
--	Forces the visibility of the PlayerList to OFF
function ForceOff()
	isVisible = false

	if(EASE_TOGGLE) then
		EaseUI.EaseY(Content, -1500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)

		local task
		task = Task.Spawn(function()
			Task.Wait(EASING_DURATION)

			if((not lastTask) or (lastTask ~= task)) then return end
			lastTask = nil

			if(not isVisible) then
				Content.visibility = Visibility.FORCE_OFF
			end
		end)
		lastTask = task
	else
		Content.visibility = Visibility.FORCE_OFF
	end
end

--	nil ForceToggle()
--	Forces the visibility of the PlayerList to toggle (ON/OFF)
function ForceToggle()
	if(isVisible) then
		ForceOff()
	else
		ForceOn()
	end
end

--	nil Tick(deltaTime)
--	Updates entries for all players and Header for LocalPlayer
function Tick()
	for _, player in pairs(Game.GetPlayers()) do
		UpdatePlayer(player)

		if((playerTeams[player] ~= nil) and (player.team ~= playerTeams[player])) then
			UpdatePlayerEntry(player)

			if(player == LocalPlayer) then
				UpdateHeader()
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
--	INITIALIZATION
------------------------------------------------------------------------------------------------------------------------

Game.playerJoinedEvent:Connect(CreatePlayerEntry)
Game.playerLeftEvent:Connect(DeletePlayerEntry)

if(#TOGGLE_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceToggle)
end

if(#FORCE_ON_EVENT > 0) then
	Events.Connect(FORCE_ON_EVENT, ForceOn)
end

if(#FORCE_OFF_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceOff)
end

if(TOGGLE_BINDING) then
	LocalPlayer.bindingReleasedEvent:Connect(OnBindingReleased)
end

PLAYER_NAME_COLOR_MODE = GetProperty(PLAYER_NAME_COLOR_MODE, PLAYER_NAME_COLOR_MODES)

EASING_EQUATION_IN = EaseUI.EasingEquation[EASING_EQUATION_IN]
EASING_DIRECTION_IN = EaseUI.EasingEquation[EASING_DIRECTION_IN]
EASING_EQUATION_OUT = EaseUI.EasingEquation[EASING_EQUATION_OUT]
EASING_DIRECTION_OUT = EaseUI.EasingEquation[EASING_DIRECTION_OUT]

HeaderPlayerName.text = LocalPlayer.name
UpdateHeader()

if(localPlayerTitle) then
	if(SHOW_TITLE_ICON and localPlayerTitle.icon) then
		HeaderSocialIcon:SetImage(localPlayerTitle.icon or "")
		HeaderSocialIcon:SetColor(localPlayerTitle.iconColor or COLOR_DEFAULT)
		HeaderSocialIcon.rotationAngle = localPlayerTitle.iconRotation or 0
		HeaderSocialIcon.width = HeaderSocialIcon.width + (localPlayerTitle.extraWidth or 0)
		HeaderSocialIcon.height = HeaderSocialIcon.height + (localPlayerTitle.extraHeight or 0)

		HeaderSocialPrefix.x = HeaderSocialPrefix.x + 20 + 8
	end

	if(SHOW_TITLE_PREFIX) then
		HeaderSocialPrefix.text = localPlayerTitle.prefix or ""
		HeaderSocialPrefix:SetColor(localPlayerTitle.prefixColor or COLOR_DEFAULT)
	else
		HeaderSocialPrefix.text = "Player"
	end
else
	HeaderSocialPrefix.text = "Player"
end

CreateHeaderLeaderstats()�

cs:PlayerTitles�������Ε

	cs:EaseUI����锘���
*
cs:ScoreboardEntryTemplate��������
4
%cs:ScoreboardLeaderstatHeaderTemplate�
�����ݵ�c
5
%cs:ScoreboardLeaderstatPlayerTemplate�������

cs:Scoreboard� 


cs:Entries� 


cs:Content� 

cs:HeaderTeamColor� 

cs:HeaderPlayerName� 

cs:HeaderSocialIcon� 

cs:HeaderSocialPrefix� 

cs:HeaderLeaderstats� 

cs:Leaderstats� 
�������ScoreboardLeaderstatPlayerb�
� ��츔��5*���츔��5ScoreboardLeaderstatPlayer"  �?  �?  �?(��מ��Ʃn2
�����σ��Z

cs:Text������σ��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�jb:

mc:euianchor:middlecenterX�
 %   ? �6


mc:euianchor:topright

mc:euianchor:topright*������σ��Text"
    �?  �?  �?(��츔��5z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterPX�7
0  �?  �?  �?%  �?"
mc:etextjustify:center0�>


mc:euianchor:middlecenter

mc:euianchor:middlecenter
NoneNone
������ݵ�cScoreboardLeaderstatHeaderb�
� ��ճ����Y*���ճ����YScoreboardLeaderstatHeader"  �?  �?  �?(������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��d:

mc:euianchor:middlecenterHX�>
StatName  �?  �?  �?%  �?"
mc:etextjustify:center0�<


mc:euianchor:bottomright

mc:euianchor:bottomright
NoneNone
��������Scoreboard Entryb�
� ��𓅸��*���𓅸��Scoreboard Entry"  �?  �?  �?(��מ��Ʃn2���������ȣ�ᙐ�Z�

cs:TeamColor�������Ե�

cs:PlayerIcon�瞡�Ǵ��

cs:SocialIcon��Ԭ�ʸτ�

cs:PlayerName���Л����

cs:Leaderstats��ȣ�ᙐ�

cs:Information���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�] :

mc:euianchor:middlecenterP� �4


mc:euianchor:topleft

mc:euianchor:topleft*���������Information"  �?  �?  �?(��𓅸��2(������Ե�瞡�Ǵ���Ԭ�ʸτ���Л����Z{

cs:TeamColor�������Ե�

cs:PlayerIcon�瞡�Ǵ��

cs:SocialIcon��Ԭ�ʸτ�

cs:PlayerName���Л����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j:

mc:euianchor:middlecenterHPX�
 %   ? �4


mc:euianchor:topleft

mc:euianchor:topleft*�������Ե�	TeamColor"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterX�&

�������  �?  �?  �?%  �?�:


mc:euianchor:middleleft

mc:euianchor:middleleft*�瞡�Ǵ��
PlayerIcon"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�� %  �@:

mc:euianchor:middlecenterX�$

�������  �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*��Ԭ�ʸτ�
SocialIcon"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  PB:

mc:euianchor:middlecenter�

�������  �?  �?  �? �<


mc:euianchor:middlecenter

mc:euianchor:middleleft*���Л����
PlayerName"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������%  (B:

mc:euianchor:middlecenterHPX�2  �?  �?  �?%  �?"
mc:etextjustify:left0�:


mc:euianchor:middleleft

mc:euianchor:middleleft*��ȣ�ᙐ�Leaderstats"
    �?  �?  �?(��𓅸��z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�h�:

mc:euianchor:middlecenterHX� �<


mc:euianchor:bottomright

mc:euianchor:bottomright
NoneNone
�8���锘���EaseUIZ�7�7-- EaseUI.lua
-- Handles easing (interpolation) of UI, interactable with FluidUI.
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--[[
	Hello, everyone! Another day, another utility! Today is sponsored by... myself!

	EaseUI is a utility that allows for both simple and advanced UI animations! Full customizability to you, the creator!

	If you need any assistance, feel free to join the Core Discord server (https://discord.gg/core-creators) and ping me (@Nicholas Foreman#0001)
	in #lua-help or #core-help! I will happily assist you. :)

	Usage:
		1) Do not put this script in the hierarchy; keep it in `Project Content` > `Scripts`
		2) Drag and drop this script into the custom properties of any script you want to use it with
		3) Inside the script that you are using EaseUI in, insert this line at the top:
			local EaseUI = require(script:GetCustomProperty("EaseUI"))
		4) Congratulations, you can proceed to use EaseUI!

	Video Tutorial: https://www.youtube.com/watch?v=TVbHI8zE9J4
	Core Forum Post: https://forums.coregames.com/t/video-easeui/424
--]]

--[[
	Enums:
		EaseUI.EasingEquation.LINEAR
		EaseUI.EasingEquation.QUADRATIC
		EaseUI.EasingEquation.CUBIC
		EaseUI.EasingEquation.QUARTIC
		EaseUI.EasingEquation.QUINTIC
		EaseUI.EasingEquation.SINE
		EaseUI.EasingEquation.EXPONENTIAL
		EaseUI.EasingEquation.CIRCULAR
		EaseUI.EasingEquation.ELASTIC
		EaseUI.EasingEquation.BACK
		EaseUI.EasingEquation.BOUNCE

		EaseUI.EasingDirection.IN
		EaseUI.EasingDirection.OUT
		EaseUI.EasingDirection.INOUT

	Functions:
		EaseUI.Ease(uiElement, property, goal, [easeDuration], [easingEquation], [easingDirection])
			uiElement
				the UI Element that you are easing

			property
				the property of the UI Element that you are easing

			goal
				the value for the property you want the UI Element that you are easing to become

			easeDuration [optional, default 1]
				the amount of time you want the ease to last

			easingEquation [optional, default LINEAR]
				the easing equation that you want to use for easing the property

			easingDirection [optional, default INOUT]
				the easing direction that you want to use for easing the property

		EaseUI.EaseX(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseY(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseWidth(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseHeight(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
		EaseUI.EaseRotation(uiElement, goal, [easeDuration], [easingEquation], [easingDirection])
--]]

--[[
	\\\\\\\\\\\\\\\\\
	DO NOT EDIT BELOW
	/////////////////
	\\\\\\\\\\\\\\\\\\\\\\\\\\\
	I URGE YOU SAVE YOUR SANITY
	///////////////////////////
	\\\\\\\\\\\\\\\\\\\
	STUFF CAN GET MESSY
	///////////////////
	\\\\\\\\\\\\\\\\\\
	PLEASE, JUST DON'T
	//////////////////
	\\\\\\\\\\\\\\\\\\\\\\\\\\
	IT'S IN YOUR BEST INTEREST
	//////////////////////////
--]]

local EasingEquations = require(script:GetCustomProperty("EasingEquations"))

local tasks = {}

local function checkTask(property)
	if(tasks[property]) then return end

	tasks[property] = {}
end

local function wrapTask(property, object, func)
	checkTask(property)

	local task = Task.Spawn(func)
	task.repeatCount = -1
	task.repeatInterval = -1

	tasks[property][object] = task
	return task
end

local function clearFromTask(object, taskType)
	checkTask(taskType)

	local task = tasks[taskType][object]
	if(not task) then return end

	task:Cancel()
	tasks[taskType][object] = nil
end

local function verifyEase(uiElement, goal, easeDuration, easingEquation, easingDirection)
	if(not Object.IsValid(uiElement)) then
		return false, "Attempting to ease an object that does not exist"
	elseif(not uiElement:IsA("UIControl")) then
		return false, "Attempting to ease an object that is not a UI Element"
	elseif(uiElement:IsA("UIContainer")) then
		return false, "Attempting to ease a UIContainer"
	elseif(type(easeDuration) ~= "number") then
		return false, "Attempting to ease with an invalid amount of time"
	elseif(type(goal) ~= "number") then
		return false, "Attempting to ease to a goal that is not a number"
	elseif(type(easingEquation) ~= "number") then
		return false, "Attempting to ease with an invalid easing equation"
	elseif(type(easingDirection) ~= "number") then
		return false, "Attempting to ease with an invalid easing direction"
	end

	return true, ""
end

local Module = {}

Module.Equation = EasingEquations.Equation
Module.EasingEquation = EasingEquations.EasingEquation
Module.EasingDirection = EasingEquations.EasingDirection

function Module.Ease(uiElement, property, goal, easeDuration, easingEquation, easingDirection)
	if(type(easeDuration) == "nil") then easeDuration = 1 end
	if(type(easingEquation) == "nil") then easingEquation = Module.EasingEquation.LINEAR end
	if(type(easingDirection) == "nil") then easingDirection = Module.EasingDirection.INOUT end

	local success, response = verifyEase(uiElement, goal, easeDuration, easingEquation, easingDirection)
	assert(success, response)

	local easingFormula = EasingEquations.GetEasingEquationFormula(easingEquation, easingDirection)
	assert(easingFormula, "Attempting to ease with an invalid easing equation enum; check that you spelled the enum correctly")

	clearFromTask(uiElement, property)

	local startTime = time()
	local start = uiElement[property]

	local direction = ((start < goal) and 1) or -1

	wrapTask(property, uiElement, function()
		if(not Object.IsValid(uiElement)) then
			return clearFromTask(uiElement, property)
		end

		local currentTime = time() - startTime

		if(currentTime >= easeDuration) then
			uiElement[property] = CoreMath.Round(goal)

			return clearFromTask(uiElement, property)
		end

		uiElement[property] = CoreMath.Round(easingFormula(currentTime, start, direction * math.abs(goal - start), easeDuration))
	end)
end

function Module.EaseX(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "x", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseY(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "y", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseWidth(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "width", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseHeight(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "height", goal, easeDuration, easingEquation, easingDirection)
end

function Module.EaseRotation(uiElement, goal, easeDuration, easingEquation, easingDirection)
	Module.Ease(uiElement, "rotationAngle", goal, easeDuration, easingEquation, easingDirection)
end

return Module#
!
cs:EasingEquations�
ѽ����i��*�EaseUI is a utility that allows for both simple and advanced UI animations! Full customizability to you, the creator!

Read the script for more information.
�7ѽ����iEasingEquationsZ�7�7-- EasingEquations.lua
-- Lua implementation of easing equations
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--[[
	References:
		https://www.gizma.com/easing/
		https://easings.net/
		https://github.com/kikito/tween.lua/blob/master/tween.lua
--]]

--[[
	Enums:
		EaseUI.EasingEquation.LINEAR
		EaseUI.EasingEquation.QUADRATIC
		EaseUI.EasingEquation.CUBIC
		EaseUI.EasingEquation.QUARTIC
		EaseUI.EasingEquation.QUINTIC
		EaseUI.EasingEquation.SINE
		EaseUI.EasingEquation.EXPONENTIAL
		EaseUI.EasingEquation.CIRCULAR
		EaseUI.EasingEquation.ELASTIC
		EaseUI.EasingEquation.BACK
		EaseUI.EasingEquation.BOUNCE

		EaseUI.EasingDirection.IN
		EaseUI.EasingDirection.OUT
		EaseUI.EasingDirection.INOUT
--]]

local function calculatePAS(p, a, c, d)
	p, a = p or d * 0.3, a or 0
	if a < math.abs(c) then return p, c, p / 4 end -- p, a, s
	return p, a, p / (2 * math.pi) * math.asin(c/a) -- p, a, s
end

local Module = {}

function Module.GetEasingEquationFormula(easingEquation, easingDirection)
	local easingEquationName
	for name, equation in pairs(Module.EasingEquation) do
		if(easingEquation == equation) then
			easingEquationName = name
			break
		end
	end
	if(not easingEquationName) then return end

	local easingDirectionName
	for name, direction in pairs(Module.EasingDirection) do
		if(easingDirection == direction) then
			easingDirectionName = name
			break
		end
	end
	if(not easingDirectionName) then return end

	local equation = Module.Equation[easingEquationName]
	if(not equation) then return end

	return equation[easingDirectionName]
end

Module.EasingEquation = {
	LINEAR = 1,
	QUADRATIC = 2,
	CUBIC = 3,
	QUARTIC = 4,
	QUINTIC = 5,
	SINE = 6,
	EXPONENTIAL = 7,
	CIRCULAR = 8,
	ELASTIC = 9,
	BACK = 10,
	BOUNCE = 11,
}

Module.EasingDirection = {
	IN = 1,
	OUT = 2,
	INOUT = 3,
}

Module.Equation = {
	--[[EQUATION = {
		IN = function(t, b, c, d)

		end,
		OUT = function(t, b, c, d)

		end,
		INOUT = function(t, b, c, d)

		end,
	},]]
	LINEAR = {
		IN = function(t, b, c, d)
			return c*t/d + b
		end,
		OUT = function(t, b, c, d)
			return c*t/d + b
		end,
		INOUT = function(t, b, c, d)
			return c*t/d + b
		end,
	},
	QUADRATIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d
			return -c * t*(t-2) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t + b
			else
				t = t - 1
				return -c/2 * (t*(t-2) - 1) + b
			end
		end,
	},
	CUBIC = {
		IN = function(t, b, c, d)
			t = t/d
			return (c*t*t*t) + b
		end,
		OUT = function(t, b, c, d)
			t = t/d
			t = t - 1
			return c*(t*t*t + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if(t < 1) then
				return c/2*t*t*t + b
			else
				t = t-2
				return c/2*(t*t*t + 2) + b
			end
		end,
	},
	QUARTIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t - 1
			return -c * (t*t*t*t - 1) + b;
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t*t*t + b
			else
				t = t - 2
				return -c/2 * (t*t*t*t - 2) + b
			end
		end,
	},
	QUINTIC = {
		IN = function(t, b, c, d)
			t = t/d
			return c*t*t*t*t*t + b
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t -1
			return c*(t*t*t*t*t + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2*t*t*t*t*t + b
			else
				t = t - 2
				return c/2*(t*t*t*t*t + 2) + b
			end
		end,
	},
	SINE = {
		IN = function(t, b, c, d)
			return -c * math.cos(t/d * (math.pi/2)) + c + b
		end,
		OUT = function(t, b, c, d)
			return c * math.sin(t/d * (math.pi/2)) + b
		end,
		INOUT = function(t, b, c, d)
			return -c/2 * (math.cos(math.pi*t/d) - 1) + b
		end,
	},
	EXPONENTIAL = {
		IN = function(t, b, c, d)
			return c * (2 ^ (10 * (t/d - 1))) + b
		end,
		OUT = function(t, b, c, d)
			return c * (-(2 ^ (-10 * t/d)) + 1) + b
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2 * (2 ^ (10 * (t - 1))) + b
			else
				t = t - 1
				return c/2 * (-(2 ^ (-10 * t)) + 2) + b
			end
		end,
	},
	CIRCULAR = {
		IN = function(t, b, c, d)
			t = t/d
			return -c * (math.sqrt(1 - t*t) - 1) + b;
		end,
		OUT = function(t, b, c, d)
			t = t/d;
			t = t - 1
			return c * math.sqrt(1 - t*t) + b;
		end,
		INOUT = function(t, b, c, d)
			t = t/(d/2)
			if (t < 1) then
				return c/2 * (2 ^ (10 * (t - 1))) + b
			else
				t = t/(d/2)
				if (t < 1) then
					return -c/2 * (math.sqrt(1 - t*t) - 1) + b
				else
					t = t- 2;
					return c/2 * (math.sqrt(1 - t*t) + 1) + b
				end
			end
		end,
	},
	ELASTIC = {
		IN = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d
			if t == 1  then return b + c end
			p, a, s = calculatePAS(p, a, c, d)
			t = t - 1
			return -(a * (2 ^ (10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
		end,
		OUT = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d
			if t == 1 then return b + c end
			p, a, s = calculatePAS(p, a, c, d)
			return a * (2 ^ (-10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
		end,
		INOUT = function(t, b, c, d)
			local a, p = 1, 1

			local s
			if t == 0 then return b end
			t = t / d * 2
			if t == 2 then return b + c end
			p, a, s = calculatePAS(p,a,c,d)
			t = t - 1
			if t < 0 then return -0.5 * (a * (2 ^ (10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p)) + b end
			return a * (2 ^ (-10 * t)) * math.sin((t * d - s) * (2 * math.pi) / p ) * 0.5 + c + b
		end,
	},
	BACK = {
		IN = function(t, b, c, d)
			local s = 1.70158

			t = t / d
			return c * t * t * ((s + 1) * t - s) + b
		end,
		OUT = function(t, b, c, d)
			local s = 1.70158

			t = t / d - 1
 			return c * (t * t * ((s + 1) * t + s) + 1) + b
		end,
		INOUT = function(t, b, c, d)
			local s = 1.70158 * 1.525

			t = t / d * 2
			if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
			t = t - 2
			return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
		end,
	},
	BOUNCE = {
		IN = function(t, b, c, d)
			return c - Module.Equation.BOUNCE.OUT(d - t, 0, c, d) + b
		end,
		OUT = function(t, b, c, d)
			t = t / d
			if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
			if t < 2 / 2.75 then
				t = t - (1.5 / 2.75)
				return c * (7.5625 * t * t + 0.75) + b
			elseif t < 2.5 / 2.75 then
				t = t - (2.25 / 2.75)
				return c * (7.5625 * t * t + 0.9375) + b
			end
			t = t - (2.625 / 2.75)
			return c * (7.5625 * t * t + 0.984375) + b
		end,
		INOUT = function(t, b, c, d)
			if t < d / 2 then return Module.Equation.BOUNCE.IN(t * 2, 0, c, d) * 0.5 + b end
  			return Module.Equation.BOUNCE.OUT(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
		end,
	},
}

return Module
�o������ΕPlayerTitlesZ�o�m--[[

	Player Titles - Module
	1.0.2 - 2020/10/13
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)


1.	Getting a MUID

	1)	Go to your profile (or use the search function for another user) on the Core website
		(https://www.coregames.com)
	2)	Copy the section of text in the URL after /user/, should look similar to:
			https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8
			Get this part:				   f9df3457225741c89209f6d484d0eba8
	3)	Paste it into the table as a string and make sure there is a comma after it:
			"f9df3457225741c89209f6d484d0eba8",
		Note: Suggested to give a comment stating who it is, so like:
			"f9df3457225741c89209f6d484d0eba8", -- NicholasForeman


2.	Adding an Icon

	1)	Select this module in Project Content
	2)	Search Core Content for your icon of choice
	3)	Drag and drop that icon into the custom properties of this module
	4)	Change its name to something that identifies it, such as "TopKiller"
	5)	Refer to it in the icon property with
			script:GetCustomProperty("IconName")


2b.	Adding a Color

	1)	Create a new line in Module.Color (approximately line 63) such as:
			COLOR_NAME = [construct color here]
		Note: Types of Color constructors are:
			Color.New(r, g, b) -- scale of 0 to 1
			Color.FromStandardHex(hex)
			Color.FromLinearHex(hex)


2c.	Adding a Title

	1)	Navigate to Module.titles (approximately line 72)
	2)	Paste this template below or copy-and-paste an additional template
		Note: The order in which a title is chosen (in the occasion a player has multiple)
		is the first one in the list, so Game Creator would be chosen before any other title
			{
				name = "Title Name",
				prefix = "Prefix",
				prefixColor = Module.Color.COLOR,
				showPrefixColorWhileStatic = false, -- Determines if the prefix color will be shown for the player name color even when the PlayerNameColorMode is STATIC
				icon = script:GetCustomProperty("IconName"),
				iconColor = Module.Color.COLOR,
				isModerator = false,
				extraWidth = 0, -- Additional width to icons, in case they are small
				extraHeight = 0, -- Additional height to icons, in case they are small
				playerMUIDs = {
					-- INSERT MUIDS OF PLAYERS HERE
				},
			}

--]]

local Module = {}

------------------------------------------------------------------------------------------------------------------------
--	STATIC VARIABLES
------------------------------------------------------------------------------------------------------------------------

Module.TeamRelation = {
	NEUTRAL = 1,
	SELF = 2,
	FRIENDLY = 3,
	ENEMY = 4,
	SELF_NEUTRAL = 5,
}

Module.Color = {
	BLUE = Color.FromStandardHex("#2196F3"),
	GREEN = Color.FromStandardHex("#4CAF50"),
	MAGENTA = Color.FromStandardHex("#E91E63"),
	ORANGE = Color.FromStandardHex("#FF9900"),
	PURPLE = Color.FromStandardHex("#9C27B0"),
	TAN = Color.FromStandardHex("#F3D19C"),
}

Module.titles = {
	{
		name = "Game Creator",
		prefix = "Game Creator",
		prefixColor = Module.Color.BLUE,
		icon = script:GetCustomProperty("GameCreator"),
		iconColor = Module.Color.BLUE,
		isModerator = true,
		extraWidth = 4,
		extraHeight = 4,
		playerMUIDs = {
			-- INSERT MUID HERE, SEE 1. ABOVE
		},
	},

	{
		name = "Moderator",
		prefix = "Moderator",
		prefixColor = Module.Color.GREEN,
		icon = script:GetCustomProperty("Moderator"),
		iconColor = Module.Color.GREEN,
		isModerator = true,
		extraWidth = 4,
		extraHeight = 4,
		playerMUIDs = {
			-- INSERT MUID HERE, SEE 1. ABOVE
		},
	},

	{
		name = "Contributor",
		prefix = "Contributor",
		prefixColor = Module.Color.MAGENTA,
		icon = script:GetCustomProperty("Contributor"),
		iconColor = Module.Color.MAGENTA,
		isModerator = false,
		extraWidth = 4,
		extraHeight = 4,
		playerMUIDs = {
			-- INSERT MUID HERE, SEE 1. ABOVE
			-- SUGGESTED FOR COMMUNITY CONTENT CONTRIBUTORS OR ANYONE THAT HELPED WITH YOUR GAME
		},
	},

	{
		name = "Quality Assurance",
		prefix = "Tester",
		prefixColor = Module.Color.MAGENTA,
		icon = script:GetCustomProperty("Tester"),
		iconColor = Module.Color.MAGENTA,
		isModerator = false,
		extraWidth = 4,
		extraHeight = 4,
		playerMUIDs = {
			-- INSERT MUID HERE, SEE 1. ABOVE
		},
	},

	{
		name = "Manticore",
		prefix = "Manticore",
		prefixColor = Module.Color.ORANGE,
		showPrefixColorWhileStatic = true,
		--icon = script:GetCustomProperty("Manticore"),
		--iconColor = Module.Color.ORANGE,
		isModerator = true,
		playerMUIDs = {
			"be501d1b587e4e6a81f301c72c8364a7", -- aBomb
			"aabd84ef7a6448a69c331121b5909cff", -- Anna
			"c14f61b74826471f974f06ff7e42d97b", -- Basilisk
			"400d8e7acb154e5bb64368411824b61d", -- Bigglebuns
			"901b7628983c4c8db4282f24afeda57a", -- Buckmonster
			"c643c92a06e943c4aef66a283f5dc1e0", -- Bumblebear
			"fb91e175e1624888805a03ebb32c50a0", -- BlueClaire
			"d97586e1f850481da13ee26d5cbddc02", -- Chris
			"3819113b7af34fb786a56960fc08136a", -- coreslinkous
			"65f3dec3b6dd45c2845a55a7af240adc", -- deadlyfishesMC
			"2d38316ed3204388acbe3c225b0c0114", -- Depp
			"8aa6e0c558be4a1c98e80229b73ffeb9", -- Dracowolfie
			"31f09de9539843a996ba240763f76641", -- featurecreeper
			"cb055adaf34a4b72b7bd02c8ae5f3ec8", -- Gabunir
			"74fd12a8ad1b4e3ca013946aa981b46e", -- Griffin
			"f207385c066b429581e6fe11ac8795bf", -- Holy
			"8a40a1c2c94f4fb0bd1430f4e37b121f", -- JayDee
			"d6c5b10f5bba4458acd46970eb25b227", -- kytsu
			"c1754d0e214741a9b15e2446ee730e68", -- lodle
			"978d4261ff404208ba49de799ce5362c", -- lokii
			"21db3c6e27af40e2aa8d78a67d0c6a32", -- max
			"43522f2d40f5480e881ec7b89567007e", -- Mehaji
			"4d64fe2c095a45ab905923395d72f51e", -- mrbigfists
			"5a7a3a3d8ccb4dc5837880f2df3002fc", -- pchiu
			"dabe472c0b2e4d5a9f4edcec4a63ad8a", -- Poippels
			"83ef77fc3dc1409992d549a68dd616dd", -- qualispec
			"20dba0f31f1b4f889b6bd70cdaaab192", -- Robotron
			"b06d130e5afd418d8ecfce2150450c69", -- rbrown
			"c078c42a742146bd99404099e4781e88", -- Scav
			"9b1e28cbd1d74f5fb4c2ddea6d81fd39", -- Sobchak
			"b4c6e32137e54571814b5e8f27aa2fcd", -- standardcombo
			"9bb9612e564644c58b2286a6853fb91e", -- Stanzilla
			"1c73b87d2d374264ab0eb4d89edc4b72", -- Stephano
			"54d6c37e71a546f7bfd480d8e654f45e", -- Tobs
			"aea40b9e2fae46908e37b42d44f3b004", -- Turbo
			"581ff579fd864966aec56450754db1fb", -- Waffle
			"fc93f85ad76f49f6984403e2f5162bce", -- zurishmi
		},
	},

	{
		name = "Team META",
		prefix = "Team META",
		prefixColor = Module.Color.PURPLE,
		icon = script:GetCustomProperty("TeamMETA"),
		iconColor = Module.Color.PURPLE,
		iconRotation = 45,
		isModerator = false,
		playerMUIDs = {
			"ef18f7661bf14d0eae60d7f31ea769af", -- TeamMETA

			"d6d9d578840a44c79a3f05c15de23bf8", -- Aggripina
			"a136c0d1d9454d539c9932354198fc29", -- Ooccoo
			"fdae8d1d32b040d792dc589edda59ced", -- Shhteve

			"eea739085f20445392c0ab999ab87bb6", -- Aj
			"557d4f1ae17646579646dfd20dcb7b66", -- AwkwardGameDev
			"d5daea732ee3422fbe85aecb900e73ec", -- Coderz
			"1f0588bf88d14c258d7384902f71f132", -- Daddio
			"1f3edd620c904e30a4e0223dd64bcc2a", -- Keppu
			"5c3b7b02607c4e368fc063c410123697", -- Knar
			"9cc8d222e6d14da68dc2ba0a9a4f0439", -- Melamoryxq
			"d1073dbcc404405cbef8ce728e53d380", -- Morticai
			"94d3fd50c4824f019421895ec8dbf099", -- Mucusinator
			"91166471c6ea4d17be6772da4973e6b7", -- mjcortes782
			"f9df3457225741c89209f6d484d0eba8", -- NicholasForeman
			"581ff579fd864966aec56450754db1fb", -- Waffle
			"e730c40ae54d4c588658667927acc6d8", -- WitcherSilver

			"1f67a03d5a8f478b993aad1c79b45640", -- Rolok
			"0ea6612ceab7456a8a3a963a94808295", -- blaking707
			"fdb45035857a4e87b17344cd891c48c5", -- KonzZwodrei
			"385b45d7abdb499f8664c6cb01df521b", -- estlogic
		},
	},

	{
		name = "Content Creator",
		prefix = "Content Creator",
		prefixColor = Module.Color.TAN,
		icon = script:GetCustomProperty("ContentCreator"),
		iconColor = Module.Color.TAN,
		isModerator = false,
		playerMUIDs = {
			"a7fa1014cab64595bee90b0049070c8e", -- Aphrim (https://www.youtube.com/channel/UCqKcZtFh25bg2JyjoKkf4mg)
			"1f0588bf88d14c258d7384902f71f132", -- Daddio (https://www.twitch.tv/daddio66)
			"fdb45035857a4e87b17344cd891c48c5", -- KonzZwodrei (https://www.twitch.tv/konz23)
			"cda3ab2fe8e14d4cb0d99eb4f6bd3312", -- LiaTheKoalaBear (https://www.twitch.tv/liathekoalabear_)
			"d1073dbcc404405cbef8ce728e53d380", -- Morticai (https://www.twitch.tv/morticai)
			"f9df3457225741c89209f6d484d0eba8", -- NicholasForeman (https://www.twitch.tv/nicholas_foreman)

			"a299961f22cf4ef1a7247951e254481f", -- Devoun (https://www.youtube.com/channel/UCalHWE_nqBsJL3iaWTe3F8Q)
			"7b1649183ca24a9c9fa43bdf5f6cf4bf", -- Esfand (https://www.twitch.tv/esfandtv)
			"fb1aa0b5124147febdfe7e16869fbdb1", -- Maya (https://www.twitch.tv/maya)
			"3130137db35f449d94f607b234785f7e", -- Mizkif (https://www.twitch.tv/mizkif)

			"7643e906555c41fcb6dfcff77396b0ce", -- BryceLovesGaming (https://www.twitch.tv/brycelovesgaming)
			"4201c90059e44d1e97e36e2c7bac5a23", -- LanaLux (https://www.twitch.tv/lana_lux)
			"2835315b26b14ecba60945876774c718", -- Mezzanine (https://www.twitch.tv/antoinedaniellive)
			"58523f4c55d04b96977c1fe5018e1b62", -- Phenns (https://www.twitch.tv/phenns)
			"9b74b9b6e1b44f2cb9d0e32542f45dd0", -- TheBronzeSword (https://www.twitch.tv/thebronzesword)
			"f261f4bb05b44bb2bf465b8a8346491f", -- WaveParadigm (https://www.twitch.tv/waveparadigm)
		},
	},
}

------------------------------------------------------------------------------------------------------------------------
--	STATIC FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	TeamRelation GetTeamRelation(Player, Player)
--	Returns the Module.TeamRelation between two players
function Module.GetTeamRelation(player1, player2)
	if(player1 == player2) then
		if(player1.team == 0) then
			return Module.TeamRelation.SELF_NEUTRAL
		else
			return Module.TeamRelation.SELF
		end
	elseif(player2.team == 0) then
		return Module.TeamRelation.NEUTRAL
	elseif(Teams.AreTeamsFriendly(player2.team, player1.team)) then
		return Module.TeamRelation.FRIENDLY
	else
		return Module.TeamRelation.ENEMY
	end
end

--	Color GetPlayerTeamColor(Player, Player, Color, Color, Color)
--	Returns the respective color for player2's team relation to player1
function Module.GetPlayerTeamColor(player1, player2, neutralTeamColor, friendlyTeamColor, enemyTeamColor)
	local teamRelation = Module.GetTeamRelation(player1, player2)

	if(teamRelation == Module.TeamRelation.SELF) then
		return friendlyTeamColor
	elseif(teamRelation == Module.TeamRelation.SELF_NEUTRAL) then
		return neutralTeamColor
	elseif(teamRelation == Module.TeamRelation.NEUTRAL) then
		return neutralTeamColor
	elseif(teamRelation == Module.TeamRelation.FRIENDLY) then
		return friendlyTeamColor
	elseif(teamRelation == Module.TeamRelation.ENEMY) then
		return enemyTeamColor
	end
end

--	nil SetVisibility(Player, Player, CoreObject, bool, bool, bool, bool)
--	Sets the visibility of player2's nameplate based on their relation to player1
function Module.SetVisibility(player1, player2, nameplate, showOnSelf, showOnNeutrals, showOnFriendlies, showOnEnemies)
	local relation = Module.GetTeamRelation(player1, player2)

	if(not Object.IsValid(nameplate)) then return end
	if((relation == Module.TeamRelation.SELF) or (relation == Module.TeamRelation.SELF_NEUTRAL)) then
		if(showOnSelf) then
			nameplate.visibility = Visibility.FORCE_ON
		else
			nameplate.visibility = Visibility.FORCE_OFF
		end
	elseif(relation == Module.TeamRelation.NEUTRAL) then
		if(showOnNeutrals) then
			nameplate.visibility = Visibility.FORCE_ON
		else
			nameplate.visibility = Visibility.FORCE_OFF
		end
	elseif(relation == Module.TeamRelation.FRIENDLY) then
		if(showOnFriendlies) then
			nameplate.visibility = Visibility.FORCE_ON
		else
			nameplate.visibility = Visibility.FORCE_OFF
		end
	elseif(relation == Module.TeamRelation.ENEMY) then
		if(showOnEnemies) then
			nameplate.visibility = Visibility.FORCE_ON
		else
			nameplate.visibility = Visibility.FORCE_OFF
		end
	end
end

--	table GetTitleByName(string)
--	Gets the title with a string name
function Module.GetTitleByName(titleName)
	for _, title in pairs(Module.titles) do
		if(title.name == titleName) then
			return title
		end
	end
end

--	table GetTitleByName(int)
--	Gets the title with an int id
function Module.GetTitleById(id)
	return Module.titles[id]
end

--	table GetPlayerTitleByMUID(Player)
--	Gets a title for a specific player based on their MUID
function Module.GetPlayerTitleByMUID(player)
	for _, title in pairs(Module.titles) do
		if(title.playerMUIDs) then
			for _, playerId in pairs(title.playerMUIDs) do
				if(player.id == playerId) then
					return title
				end
			end
		end
	end
end


--	table GetPlayerTitleByName(Player)
--	Gets a title for a specific player based on their name
function Module.GetPlayerTitleByName(player)
	for _, title in pairs(Module.titles) do
		if(title.playerNames) then
			for _, playerName in pairs(title.playerNames) do
				if(player.name == playerName) then
					return title
				end
			end
		end
	end
end


--	table GetPlayerTitle(Player)
--	Gets a title for a specific player
function Module.GetPlayerTitle(player)
	local title = Module.GetPlayerTitleByMUID(player)
	if(not title) then
		title = Module.GetPlayerTitleByName(player)
	end

	return title
end

------------------------------------------------------------------------------------------------------------------------
--	RETURN STATEMENT
------------------------------------------------------------------------------------------------------------------------

return Module�

cs:GameCreator�
�󬏏���G

cs:Moderator�����۳���

cs:Contributor���Ι����

	cs:Tester�������П

cs:Manticore�
�����3

cs:TeamMETA����������
 
cs:ContentCreator�
��됳���[
;��됳���[	Icon Star	R"
PlatformBrushAssetRef	Icon_Star
C���������Infinity	R*
PlatformBrushAssetRefUI_SciFI_Icon_030
E�����3Icon Manticore	R'
PlatformBrushAssetRefIcon_Manticore
I������ПScience Beaker	R*
PlatformBrushAssetRefUI_SciFI_Icon_027
D��Ι����Icon Achievement	R#
PlatformBrushAssetRef
Icon_Medal
F����۳���Hammer	R/
PlatformBrushAssetRefUI_Fantasy_icon_Hammer
=�󬏏���G
Icon Tools	R#
PlatformBrushAssetRef
Icon_Tools
?���������	Sun LightR%
BlueprintAssetRefCORESKY_SunLight
6������Ƥ�CubeR!
StaticMeshAssetRefsm_cube_002
�˭푗����ProjectHierarchyTemplate_READMEZ��--[[

	Project Hierarchy Template - README
	1.0.0 - October 15, 2020
	by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

		Hello, everyone! This is a sample project that will fit MOST design criterias. It includes a well-structured hierarchy to encourage
	well-maintained organization and simplicity. This encourages creators to not only be creative but maintain a project that prevents
	getting lost in the amazingness that will be created!


1.	Hierarchy

	|_ Settings - the folder for everything related to how the game functions
		|_ Server Settings - specific gameplay settings like game settings, team settings, and respawn settings
		|_ Player Settings - all player settings that will be used within the game
		|_ Camera Settings - all cameras that will be used within the game
	|_ User Interface - all UI that is not directly incorporated with a component, like game state ui
		• Sidenote: recommended to put UI scripts inside the UI elements
	|_ Gameplay - global scripting for the game that is not tied to a specific component/group
		|_ DefaultContext
		|_ ClientContext
	|_ Environment - everything related to the aesthetic of the game, excluding art
		|_ Sky - comes with the sky dome, sky light, and sun light but would also include extra sky objects like planets
		|_ Post Processing - all global processing effects to be applied
		|_ Lighting - area lights, point lights, and spot lights
		|_ Sound - sounds not directly related to a specific component (ex: gunshots would not be included), like background music
	|_ Spawn Points - all spawn points for the game; recommended to create groups inside this folder for teams to help organization
	|_ Components - groups/objects that are both art (building) and scripting; helps seperate scripted objects from pure art
	|_ Scenery - pure art; only groups/objects that are static and non-moving and do not require scripting


2.	Discord

	If you have any questions, feel free to join the Core Hub Discord server:
		discord.gg/core-creators
	We are a friendly group of creators and players in the Core community. Everyone is welcome to play games together or
	learn about game dev!

--]]
���Е�����Border��锲�������

color�ʶT<ʶT<ʶT<%  �?

fresnel_emissive_booste    

fresnel_sharpnesse    

fresnel_color�%  �?

	roughnesse  �?

speculare    
L锲������Basic MaterialR-
MaterialAssetRefmi_basic_pbr_material_001
��٤������META Player Titlesb�
{ ���Ĵ���*n���Ĵ���TemplateBundleDummy"
    �?  �?  �?�4Z2
�����Ɛ��

���ۏ���L
��љٓ��

��������u
NoneNone��
 2b2c56fbdeda45ffb65da5ea7a7dd032 ef18f7661bf14d0eae60d7f31ea769afTeamMETA"1.6.0*�Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.

Includes:
• PlayerTitles - This contains all of the possible social titles and their respective assignments. More documentation can be found in the script itself.
• PlayerList - A compact UI panel listing players and their corresponding teams and titles.
• Player Nameplates - Text above a player's head indicating their username, health, and titles.
• Scoreboard - A large UI panel listing players and their corresponding teams and titles alongside additional stats such as kills, deaths, or even resources.

Created by @NicholasForeman of Team META
Message @Buckmonster or @NicholasForeman in Discord with feedback or feature requests - https://discord.com/invite/core-creators

Make sure to read the PlayerTitles_README file for setup and configuration instructions

Many thanks to:
• @standardcombo for review and documentation template
• @Aggripina for thumbnail design

UPDATE 1.0.6:
1) Change Leaderstats from custom property to a group within the Scoreboard

UPDATE 1.0.5:
1) Attempted fix to nameplates randomly breaking

UPDATE 1.0.4:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.3:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.2:
1) Fix Damage Bug with PlayerTitles
2) Fix PlayerNameColorMode ToolTip showing SOCIAL_STATUS instead of TITLE
3) Improve README, Documentation for files, and Comments
�?��������uPlayerList (PlayerTitles)b�0
�0 ���७��i*����७��iPlayerList (PlayerTitles)"  �?  �?  �?(��מ��Ʃn2
ܿ��̡�ހZ�
 
cs:PlayerNameColorModejSTATIC
+
cs:PlayerNameColor�  �?  �?  �?%  �?
,
cs:NeutralTeamColor�  �?  �?  �?%  �?
-
cs:FriendlyTeamColor�"-y<N'�>�qe?%  �?
*
cs:EnemyTeamColor��g?��e=e=%  �?

cs:ShowTitleIconP

cs:ShowTitlePrefixP

cs:GapBetweenEntriesX 
$
cs:ToggleBindingjability_extra_19

cs:ToggleEventj 

cs:ForceOnEventj 

cs:ForceOffEventj 

cs:EaseToggleP 

cs:EasingDuratione���=

cs:EasingEquationInjLINEAR

cs:EasingDirectionInjIN

cs:EasingEquationOutjLINEAR

cs:EasingDirectionOutjOUT
x
cs:PlayerNameColor:tooltipjZThe color to use for a player's username; only applicable if PlayerNameColorMode is STATIC
y
cs:PlayerNameColorMode:tooltipjWDetermines how player name colors will be shown on the playerlist | STATIC, TEAM, TITLE
N
cs:NeutralTeamColor:tooltipj/The color to use for anyone on team 0 (neutral)
`
cs:FriendlyTeamColor:tooltipj@The color to use for anyone on the same team as the Local Player
�
cs:EnemyTeamColor:tooltipjeThe color to use for anyone not on the same team as the Local Player or is on team 255 (Free for All)
�
cs:ShowTitleIcon:tooltipjqDetermines if all social status icons should be disabled or enabled based on options in the SocialStatuses module
�
cs:ShowTitlePrefix:tooltipjtDetermines if all social status prefixes should be disabled or enabled based on options in the SocialStatuses module
y
cs:ToggleBinding:tooltipj]The binding that someone presses to show/hide the leaderboard; default Tab (ability_extra_19)
R
cs:ToggleEvent:tooltipj8The event that will toggle the visibility of leaderboard
V
cs:ForceOnEvent:tooltipj;The event that will force the leaderboard to become visible
Y
cs:ForceOffEvent:tooltipj=The event that will force the leaderboard to become invisible
q
cs:EaseToggle:tooltipjXDetermines if the leaderboard should just pop in/out of place, or ease/tween/interpolate
a
cs:EasingDuration:tooltipjDThe amount of time for easing; does not apply if EaseToggle is false
�
cs:EasingEquationIn:tooltipj�The easing equation that will be used to ease in; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionIn:tooltipjiThe easing direction that will be used to ease in; does not apply if EaseToggle is false | IN, OUT, INOUT
�
cs:EasingEquationOut:tooltipj�The easing equation that will be used to ease out; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionOut:tooltipjjThe easing direction that will be used to ease out; does not apply if EaseToggle is false | IN, OUT, INOUTz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�ܿ��̡�ހClientContext"
    �?  �?  �?(���७��i2���꠶������띹ˎ�z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent� *����꠶���PlayerTitles_PlayerList"
    �?  �?  �?(ܿ��̡�ހZ�
#
cs:HeaderSocialIcon��ղ������
%
cs:HeaderSocialPrefix����絅���


cs:Entries�
�������G
#
cs:HeaderPlayerName����������

cs:PlayerList�
���७��i
"
cs:HeaderTeamColor��笑�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

�˕�����J*����띹ˎ�	Container"
    �?  �?  �?(ܿ��̡�ހ2	٭��׼�z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�Y:

mc:euianchor:middlecenter� �4


mc:euianchor:topleft

mc:euianchor:topleft*�٭��׼�Content"
    �?  �?  �?(���띹ˎ�2���������𐖁��ߎz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�k��%   �-   @:

mc:euianchor:middlecenter� �6


mc:euianchor:topright

mc:euianchor:topright*���������Header"
    �?  �?  �?(٭��׼�21�����7�笑���������������ղ���������絅���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�_<:

mc:euianchor:middlecenterP� �6


mc:euianchor:topright

mc:euianchor:topright*������7
Background"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j:

mc:euianchor:middlecenterPX�
 %  @? �6


mc:euianchor:topright

mc:euianchor:topright*��笑�����	TeamColor"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�}:

mc:euianchor:middlecenterX�
   �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*����������
PlayerName"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent����������� %   A:

mc:euianchor:middlecenterHP�2  �?  �?  �?%  �?"
mc:etextjustify:left0�4


mc:euianchor:topleft

mc:euianchor:topleft*��ղ������
SocialIcon"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  �A-  ��:

mc:euianchor:middlecenter�

�������  �?  �?  �? �<


mc:euianchor:middlecenter

mc:euianchor:bottomleft*����絅���SocialPrefix"
    �?  �?  �?(��������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������%   A-  ��:

mc:euianchor:middlecenterHP�2   ?   ?   ?%  �?"
mc:etextjustify:left0�:


mc:euianchor:bottomleft

mc:euianchor:bottomleft*��𐖁��ߎEntriesPanel"
    �?  �?  �?(٭��׼�2	�������Gz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�v���������:

mc:euianchor:middlecenterHPX��>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*��������GEntries"
    �?  �?  �?(�𐖁��ߎz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�g:

mc:euianchor:middlecenterPX� �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter
NoneNone��*�Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.

Includes:
• PlayerTitles - This contains all of the possible social titles and their respective assignments. More documentation can be found in the script itself.
• PlayerList - A compact UI panel listing players and their corresponding teams and titles.
• Player Nameplates - Text above a player's head indicating their username, health, and titles.
• Scoreboard - A large UI panel listing players and their corresponding teams and titles alongside additional stats such as kills, deaths, or even resources.

Created by @NicholasForeman of Team META
Message @Buckmonster or @NicholasForeman in Discord with feedback or feature requests - https://discord.com/invite/core-creators

Make sure to read the PlayerTitles_README file for setup and configuration instructions

Many thanks to:
• @standardcombo for review and documentation template
• @Aggripina for thumbnail design

UPDATE 1.0.6:
1) Change Leaderstats from custom property to a group within the Scoreboard

UPDATE 1.0.5:
1) Attempted fix to nameplates randomly breaking

UPDATE 1.0.4:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.3:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.2:
1) Fix Damage Bug with PlayerTitles
2) Fix PlayerNameColorMode ToolTip showing SOCIAL_STATUS instead of TITLE
3) Improve README, Documentation for files, and Comments�
�a�˕�����JPlayerTitles_PlayerListZ�a�_--[[

	Player Titles - PlayerList (Client)
	1.0.2 - 2020/10/13
	Contributors
		Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--]]

------------------------------------------------------------------------------------------------------------------------
--	EXTERNAL SCRIPTS AND APIS
------------------------------------------------------------------------------------------------------------------------
local PlayerTitles = require(script:GetCustomProperty("PlayerTitles"))
local EaseUI = require(script:GetCustomProperty("EaseUI"))

------------------------------------------------------------------------------------------------------------------------
--	OBJECTS AND REFERNECES
------------------------------------------------------------------------------------------------------------------------
local PlayerList = script:GetCustomProperty("PlayerList"):WaitForObject()
local PlayerListEntryTemplate = script:GetCustomProperty("PlayerListEntryTemplate")

local Entries = script:GetCustomProperty("Entries"):WaitForObject()
local HeaderTeamColor = script:GetCustomProperty("HeaderTeamColor"):WaitForObject()
local HeaderPlayerName = script:GetCustomProperty("HeaderPlayerName"):WaitForObject()
local HeaderSocialIcon = script:GetCustomProperty("HeaderSocialIcon"):WaitForObject()
local HeaderSocialPrefix = script:GetCustomProperty("HeaderSocialPrefix"):WaitForObject()

local LocalPlayer = Game.GetLocalPlayer()

------------------------------------------------------------------------------------------------------------------------
--	CONSTANTS
------------------------------------------------------------------------------------------------------------------------
local PLAYER_NAME_COLOR_MODE = PlayerList:GetCustomProperty("PlayerNameColorMode")
local PLAYER_NAME_COLOR = PlayerList:GetCustomProperty("PlayerNameColor")

local NEUTRAL_TEAM_COLOR = PlayerList:GetCustomProperty("NeutralTeamColor")
local FRIENDLY_TEAM_COLOR = PlayerList:GetCustomProperty("FriendlyTeamColor")
local ENEMY_TEAM_COLOR = PlayerList:GetCustomProperty("EnemyTeamColor")

local SHOW_TITLE_ICON = PlayerList:GetCustomProperty("ShowTitleIcon")
local SHOW_TITLE_PREFIX = PlayerList:GetCustomProperty("ShowTitlePrefix")

local GAP_BETWEEN_ENTRIES = PlayerList:GetCustomProperty("GapBetweenEntries")

local TOGGLE_BINDING = PlayerList:GetCustomProperty("ToggleBinding")
local TOGGLE_EVENT = PlayerList:GetCustomProperty("ToggleEvent")
local FORCE_ON_EVENT = PlayerList:GetCustomProperty("ForceOnEvent")
local FORCE_OFF_EVENT = PlayerList:GetCustomProperty("ForceOffEvent")

local EASE_TOGGLE = PlayerList:GetCustomProperty("EaseToggle")
local EASING_DURATION = PlayerList:GetCustomProperty("EasingDuration")
local EASING_EQUATION_IN = PlayerList:GetCustomProperty("EasingEquationIn")
local EASING_DIRECTION_IN = PlayerList:GetCustomProperty("EasingDirectionIn")
local EASING_EQUATION_OUT = PlayerList:GetCustomProperty("EasingEquationOut")
local EASING_DIRECTION_OUT = PlayerList:GetCustomProperty("EasingDirectionOut")

local COLOR_DEFAULT = Color.New(1, 1, 1, 1)

local PLAYER_NAME_COLOR_MODES = { "STATIC", "TEAM", "TITLE" }

------------------------------------------------------------------------------------------------------------------------
--	INITIAL VARIABLES
------------------------------------------------------------------------------------------------------------------------
local localPlayerTitle = PlayerTitles.GetPlayerTitle(LocalPlayer)

local playerTeams = {}
local isVisible = true

local lastTask

------------------------------------------------------------------------------------------------------------------------
--	LOCAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil UpdatePlayerEntries()
--	Re-orders all of the players in the list
local function UpdatePlayerEntries()
	for index, entry in pairs(Entries:GetChildren()) do
		entry.y = (entry.height * (index - 1)) + (GAP_BETWEEN_ENTRIES * (index - 1))
	end
end

--	nil CreatePlayerEntry(Player)
--	Creates an entry on the PlayerList for a player
local function CreatePlayerEntry(player)
	playerTeams[player] = player.team

	local title = PlayerTitles.GetPlayerTitle(player)

	local entry = World.SpawnAsset(PlayerListEntryTemplate, {
		parent = Entries
	})
	entry.name = player.name

	local playerNameText, teamColorImage, playerIconImage, socialIconImage =
		entry:GetCustomProperty("PlayerName"):WaitForObject(),
		entry:GetCustomProperty("TeamColor"):WaitForObject(),
		entry:GetCustomProperty("PlayerIcon"):WaitForObject(),
		entry:GetCustomProperty("SocialIcon"):WaitForObject()

	playerNameText.text = player.name

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_TEAM_COLOR, FRIENDLY_TEAM_COLOR, ENEMY_TEAM_COLOR)
	teamColorImage:SetColor(teamColor)

	playerIconImage:SetImage(player)

	if(SHOW_TITLE_ICON and title and title.icon) then
		socialIconImage:SetImage(title.icon or "")
		socialIconImage:SetColor(title.iconColor or COLOR_DEFAULT)
		socialIconImage.rotationAngle = tonumber(title.iconRotation) or 0
		socialIconImage.width = socialIconImage.width + (title.extraWidth or 0)
		socialIconImage.height = socialIconImage.height + (title.extraHeight or 0)

		playerNameText.x = playerNameText.x + 26
		playerNameText.width = playerNameText.width - 26
	end

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and (PLAYER_NAME_COLOR_MODE == "TITLE")) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	elseif((PLAYER_NAME_COLOR_MODE == "STATIC") and title and title.showPrefixColorWhileStatic) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end

	UpdatePlayerEntries()
end

--	nil DeletePlayerEntry(Player)
--	Deletes an entry on the PlayerList for a player
local function DeletePlayerEntry(player)
	playerTeams[player] = nil

	local entry = Entries:FindChildByName(player.name)
	if(not entry) then return end

	entry:Destroy()

	UpdatePlayerEntries()
end

--	nil UpdatePlayerEntry(Player)
--	Updates the name color and team color of a player on the PlayerList
local function UpdatePlayerEntry(player)
	playerTeams[player] = player.team

	local entry = Entries:FindChildByName(player.name)
	if(not entry) then return end

	local title = PlayerTitles.GetPlayerTitle(player)

	local playerNameText, teamColorImage =
		entry:GetCustomProperty("PlayerName"):WaitForObject(),
		entry:GetCustomProperty("TeamColor"):WaitForObject()

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_TEAM_COLOR, FRIENDLY_TEAM_COLOR, ENEMY_TEAM_COLOR)
	teamColorImage:SetColor(teamColor)

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and (PLAYER_NAME_COLOR_MODE == "TITLE")) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	elseif((PLAYER_NAME_COLOR_MODE == "STATIC") and title and title.showPrefixColorWhileStatic) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end
end

--	nil UpdateHeader()
--	Updates the name color and team color for the LocalPlayer on the Header
local function UpdateHeader()
	local isNeutral = LocalPlayer.team == 0

	if(isNeutral) then
		HeaderTeamColor:SetColor(NEUTRAL_TEAM_COLOR)
	else
		HeaderTeamColor:SetColor(FRIENDLY_TEAM_COLOR)
	end

	HeaderPlayerName:SetColor(PLAYER_NAME_COLOR)
	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		if(isNeutral) then
			HeaderPlayerName:SetColor(NEUTRAL_TEAM_COLOR)
		else
			HeaderPlayerName:SetColor(FRIENDLY_TEAM_COLOR)
		end
	--[[elseif(localPlayerTitle and PLAYER_NAME_COLOR_MODE == "TITLE") then
		HeaderPlayerName:SetColor(localPlayerTitle.prefixColor or COLOR_DEFAULT)]]
	else
		HeaderPlayerName:SetColor(PLAYER_NAME_COLOR)
	end
end

--	string GetProperty(string, table)
--	Returns a value (string) based on a table of default options (strings)
local function GetProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

--	nil OnBindingReleased(Player, string)
--	Toggles the PlayerList on release of the TOGGLE_BINDING
local function OnBindingReleased(player, binding)
	if(binding ~= TOGGLE_BINDING) then return end

	ForceToggle()
end

------------------------------------------------------------------------------------------------------------------------
--	GLOBAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil ForceOn()
--	Forces the visibility of the PlayerList to ON
function ForceOn()
	isVisible = true

	Entries.visibility = Visibility.FORCE_ON
	if(EASE_TOGGLE) then
		EaseUI.EaseY(Entries, 0, EASING_DURATION, EASING_EQUATION_IN, EASING_DIRECTION_IN)
	end
end

--	nil ForceOff()
--	Forces the visibility of the PlayerList to OFF
function ForceOff()
	isVisible = false

	if(EASE_TOGGLE) then
		EaseUI.EaseY(Entries, -500, EASING_DURATION, EASING_EQUATION_OUT, EASING_DIRECTION_OUT)

		local task
		task = Task.Spawn(function()
			Task.Wait(EASING_DURATION)

			if((not lastTask) or (lastTask ~= task)) then return end
			lastTask = nil

			if(not isVisible) then
				Entries.visibility = Visibility.FORCE_OFF
			end
		end)
		lastTask = task
	else
		Entries.visibility = Visibility.FORCE_OFF
	end
end

--	nil ForceToggle()
--	Forces the visibility of the PlayerList to toggle (ON/OFF)
function ForceToggle()
	if(isVisible) then
		ForceOff()
	else
		ForceOn()
	end
end

--	nil Tick(deltaTime)
--	Updates entries for all players and Header for LocalPlayer
function Tick()
	for _, player in pairs(Game.GetPlayers()) do
		if((playerTeams[player] ~= nil) and (player.team ~= playerTeams[player])) then
			UpdatePlayerEntry(player)

			if(player == LocalPlayer) then
				UpdateHeader()
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
--	INITIALIZATION
------------------------------------------------------------------------------------------------------------------------

Game.playerJoinedEvent:Connect(CreatePlayerEntry)
Game.playerLeftEvent:Connect(DeletePlayerEntry)

if(#TOGGLE_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceToggle)
end

if(#FORCE_ON_EVENT > 0) then
	Events.Connect(FORCE_ON_EVENT, ForceOn)
end

if(#FORCE_OFF_EVENT > 0) then
	Events.Connect(TOGGLE_EVENT, ForceOff)
end

if(TOGGLE_BINDING) then
	LocalPlayer.bindingReleasedEvent:Connect(OnBindingReleased)
end

PLAYER_NAME_COLOR_MODE = GetProperty(PLAYER_NAME_COLOR_MODE, PLAYER_NAME_COLOR_MODES)

EASING_EQUATION_IN = EaseUI.EasingEquation[EASING_EQUATION_IN]
EASING_DIRECTION_IN = EaseUI.EasingEquation[EASING_DIRECTION_IN]
EASING_EQUATION_OUT = EaseUI.EasingEquation[EASING_EQUATION_OUT]
EASING_DIRECTION_OUT = EaseUI.EasingEquation[EASING_DIRECTION_OUT]

HeaderPlayerName.text = LocalPlayer.name
UpdateHeader()

if(localPlayerTitle) then
	if(SHOW_TITLE_ICON and localPlayerTitle.icon) then
		HeaderSocialIcon:SetImage(localPlayerTitle.icon or "")
		HeaderSocialIcon:SetColor(localPlayerTitle.iconColor or COLOR_DEFAULT)
		HeaderSocialIcon.rotationAngle = localPlayerTitle.iconRotation or 0
		HeaderSocialIcon.width = HeaderSocialIcon.width + (localPlayerTitle.extraWidth or 0)
		HeaderSocialIcon.height = HeaderSocialIcon.height + (localPlayerTitle.extraHeight or 0)

		HeaderSocialPrefix.x = HeaderSocialPrefix.x + 20 + 8
	end

	if(SHOW_TITLE_PREFIX) then
		HeaderSocialPrefix.text = localPlayerTitle.prefix or ""
		HeaderSocialPrefix:SetColor(localPlayerTitle.prefixColor or COLOR_DEFAULT)
	else
		HeaderSocialPrefix.text = "Player"
	end
else
	HeaderSocialPrefix.text = "Player"
end�

cs:PlayerTitles�������Ε

	cs:EaseUI����锘���
*
cs:PlayerListEntryTemplate�ݽ����

cs:PlayerList� 


cs:Entries� 

cs:HeaderTeamColor� 

cs:HeaderPlayerName� 

cs:HeaderSocialIcon� 

cs:HeaderSocialPrefix� 
�ݽ����PlayerList Entryb�
� �˭������*��˭������PlayerList Entry"  �?  �?  �?(��מ��Ʃn2'�������֖��µ������˯���A�˵�����Z�

cs:TeamColor��������

cs:PlayerIcon�֖��µ���
&
cs:SocialIconBackground�
���ۄ���

cs:SocialIcon�
���˯���A

cs:PlayerName��˵�����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j :

mc:euianchor:middlecenterP�
 %   ? �6


mc:euianchor:topright

mc:euianchor:topright*��������	TeamColor"
    �?  �?  �?(�˭������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��:

mc:euianchor:middlecenterX�&

�������  �?  �?  �?%  �?�:


mc:euianchor:middleleft

mc:euianchor:middleleft*�֖��µ���
PlayerIcon"
    �?  �?  �?(�˭������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�� %  �@:

mc:euianchor:middlecenterX�$

�������  �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*����˯���A
SocialIcon"
    �?  �?  �?(�˭������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  PB:

mc:euianchor:middlecenter�

�������  �?  �?  �? �<


mc:euianchor:middlecenter

mc:euianchor:middleleft*��˵�����
PlayerName"
    �?  �?  �?(�˭������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������%  (B:

mc:euianchor:middlecenterHPX�2  �?  �?  �?%  �?"
mc:etextjustify:left0�:


mc:euianchor:middleleft

mc:euianchor:middleleft
NoneNone
���љٓ��PlayerNameplates (PlayerTitles)b�
� �龣����I*��龣����IPlayerNameplates (PlayerTitles)"  �?  �?  �?(��מ��Ʃn2	����ܙȵ-Z�

 
cs:PlayerNameColorModejSTATIC
+
cs:PlayerNameColor�  �?  �?  �?%  �?

cs:ShowTitlePrefixP

cs:ShowStrokesP

cs:ShowHealthP

cs:ShowOnSelfP

cs:ShowOnNeutralsP

cs:ShowOnFriendliesP

cs:ShowOnEnemiesP
.
cs:NeutralHealthColor��";SY>���<%  �?
/
cs:FriendlyHealthColor�"-y<N'�>�qe?%  �?
,
cs:EnemyHealthColor��g?��e=e=%  �?
y
cs:PlayerNameColorMode:tooltipjWDetermines how player name colors will be shown on the playerlist | STATIC, TEAM, TITLE
x
cs:PlayerNameColor:tooltipjZThe color to use for a player's username; only applicable if PlayerNameColorMode is STATIC
S
cs:ShowHealth:tooltipj:Determines if a player's health bar should be shown or not
R
cs:ShowOnSelf:tooltipj9Determines if a player can see their own nameplate or not
N
cs:ShowOnNeutrals:tooltipj1Determines if a player can see neutral nameplates
Q
cs:ShowOnFriendlies:tooltipj2Determines if a player can see friendly nameplates
K
cs:ShowOnEnemies:tooltipj/Determines if a player can see enemy nameplates
P
cs:NeutralHealthColor:tooltipj/The color to use for anyone on team 0 (neutral)
b
cs:FriendlyHealthColor:tooltipj@The color to use for anyone on the same team as the Local Player
�
cs:EnemyHealthColor:tooltipjeThe color to use for anyone not on the same team as the Local Player or is on team 255 (Free for All)z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*�����ܙȵ-ClientContext"
    �?  �?  �?(�龣����I2
߷�㴅���z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent� *�߷�㴅���PlayerTitles_PlayerNameplates"
    �?  �?  �?(����ܙȵ-Z$
"
cs:PlayerNameplates�
�龣����Iz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

캯����_
NoneNone��*�Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.

Includes:
• PlayerTitles - This contains all of the possible social titles and their respective assignments. More documentation can be found in the script itself.
• PlayerList - A compact UI panel listing players and their corresponding teams and titles.
• Player Nameplates - Text above a player's head indicating their username, health, and titles.
• Scoreboard - A large UI panel listing players and their corresponding teams and titles alongside additional stats such as kills, deaths, or even resources.

Created by @NicholasForeman of Team META
Message @Buckmonster or @NicholasForeman in Discord with feedback or feature requests - https://discord.com/invite/core-creators

Make sure to read the PlayerTitles_README file for setup and configuration instructions

Many thanks to:
• @standardcombo for review and documentation template
• @Aggripina for thumbnail design

UPDATE 1.0.6:
1) Change Leaderstats from custom property to a group within the Scoreboard

UPDATE 1.0.5:
1) Attempted fix to nameplates randomly breaking

UPDATE 1.0.4:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.3:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.2:
1) Fix Damage Bug with PlayerTitles
2) Fix PlayerNameColorMode ToolTip showing SOCIAL_STATUS instead of TITLE
3) Improve README, Documentation for files, and Comments�
�U캯����_PlayerTitles_PlayerNameplatesZ�U�T--[[

	Player Titles - Player Nameplates (Client)
	1.0.2 - 2020/10/13
	Contributors
		Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

--]]

------------------------------------------------------------------------------------------------------------------------
--	EXTERNAL SCRIPTS AND APIS
------------------------------------------------------------------------------------------------------------------------
local PlayerTitles = require(script:GetCustomProperty("PlayerTitles"))

------------------------------------------------------------------------------------------------------------------------
--	OBJECTS AND REFERENCES
------------------------------------------------------------------------------------------------------------------------
local PlayerNameplates = script:GetCustomProperty("PlayerNameplates"):WaitForObject()
local NameplateTemplate = script:GetCustomProperty("NameplateTemplate")

local LocalPlayer = Game.GetLocalPlayer()

------------------------------------------------------------------------------------------------------------------------
--	CONSTANTS
------------------------------------------------------------------------------------------------------------------------
local PLAYER_NAME_COLOR_MODE = PlayerNameplates:GetCustomProperty("PlayerNameColorMode")
local PLAYER_NAME_COLOR = PlayerNameplates:GetCustomProperty("PlayerNameColor")

local SHOW_STROKES = PlayerNameplates:GetCustomProperty("ShowStrokes")

local SHOW_HEALTH = PlayerNameplates:GetCustomProperty("ShowHealth")
local SHOW_ON_SELF = PlayerNameplates:GetCustomProperty("ShowOnSelf")
local SHOW_ON_NEUTRALS = PlayerNameplates:GetCustomProperty("ShowOnNeutrals")
local SHOW_ON_FRIENDLIES = PlayerNameplates:GetCustomProperty("ShowOnFriendlies")
local SHOW_ON_ENEMIES = PlayerNameplates:GetCustomProperty("ShowOnEnemies")

local NEUTRAL_HEALTH_COLOR = PlayerNameplates:GetCustomProperty("NeutralHealthColor")
local FRIENDLY_HEALTH_COLOR = PlayerNameplates:GetCustomProperty("FriendlyHealthColor")
local ENEMY_HEALTH_COLOR = PlayerNameplates:GetCustomProperty("EnemyHealthColor")

local SHOW_TITLE_PREFIX = PlayerNameplates:GetCustomProperty("ShowTitlePrefix")

local PLAYER_NAME_COLOR_MODES = { "STATIC", "TEAM", "TITLE" }

local COLOR_DEFAULT = Color.New(1, 1, 1, 1)

------------------------------------------------------------------------------------------------------------------------
--	INITIAL VARIABLES
------------------------------------------------------------------------------------------------------------------------
local nameplates = {}
local playerTeams = {}
local playerHealth = {}
local playerMaxHealth = {}
local playersDead = {}

------------------------------------------------------------------------------------------------------------------------
--	LOCAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil SetText(CoreObject, string)
--	Sets the text + background text of a WorldText
local function SetText(object, text)
	if(not Object.IsValid(object)) then return end

	object.text = text
	if(not SHOW_STROKES) then return end

	for _, child in pairs(object:GetChildren()) do
		child.text = text
	end
end

--	Player FindPlayerByName(string)
--	Finds a player in all players by string name
local function FindPlayerByName(playerName)
	for _, player in pairs(Game.GetPlayers()) do
		if(player.name == playerName) then
			return player
		end
	end
end

--	nil OnPlayerJoined(Player)
--	Creates a nameplate for a player
local function OnPlayerJoined(player)
	playerTeams[player] = player.team
	playerHealth[player] = player.hitPoints
	playerMaxHealth[player] = player.maxHitPoints
	playersDead[player] = player.isDead

	local title = PlayerTitles.GetPlayerTitle(player)

	local nameplate = World.SpawnAsset(NameplateTemplate)
	nameplate.name = player.name
	nameplates[player] = nameplate

	local playerNameText, prefixText, healthText, healthBar, healthBarOutline =
		nameplate:GetCustomProperty("Name"):WaitForObject(),
		nameplate:GetCustomProperty("Prefix"):WaitForObject(),
		nameplate:GetCustomProperty("Health"):WaitForObject(),
		nameplate:GetCustomProperty("HealthBar"):WaitForObject(),
		nameplate:GetCustomProperty("HealthBarOutline"):WaitForObject()

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_HEALTH_COLOR, FRIENDLY_HEALTH_COLOR, ENEMY_HEALTH_COLOR)
	healthBar:SetColor(teamColor)

	if(not SHOW_STROKES) then
		healthBarOutline:Destroy()
	end

	SetText(playerNameText, player.name)

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and (PLAYER_NAME_COLOR_MODE == "TITLE")) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end

	if(SHOW_HEALTH) then
		SetText(healthText, string.format("%d / %d", player.hitPoints, player.maxHitPoints))
	else
		healthText.visibility = Visibility.FORCE_OFF
		healthBar.visibility = Visibility.FORCE_OFF
		healthBarOutline.visibility = Visibility.FORCE_OFF
	end

	if(SHOW_TITLE_PREFIX and title) then
		SetText(prefixText, title.prefix or "")
		prefixText:SetColor(title.prefixColor or Color.New(0.1, 0.1, 0.1))
	end

	nameplate:AttachToPlayer(player, "nameplate")

	if(not SHOW_HEALTH) then
		nameplate:SetPosition(Vector3.New(0, 0, -15))
	end

	PlayerTitles.SetVisibility(LocalPlayer, player, nameplate, SHOW_ON_SELF, SHOW_ON_NEUTRALS, SHOW_ON_FRIENDLIES, SHOW_ON_ENEMIES)
end

--	nil OnPlayerLeft(Player)
--	Destroys a player's nameplate
local function OnPlayerLeft(player)
	playerTeams[player] = nil
	playerHealth[player] = nil
	playerMaxHealth[player] = nil
	playersDead[player] = nil

	local nameplate = nameplates[player]
	if(not nameplate) then return end
	if(not Object.IsValid(nameplate)) then return end

	nameplate:Destroy()
	nameplates[player] = nil
end

--	nil UpdatePlayerNameColor(Player, CoreObject)
--	Sets the name color for a player's nameplate
local function UpdatePlayerNameColor(player, nameplate)
	if(not Object.IsValid(nameplate)) then return end

	local playerNameText = nameplate:GetCustomProperty("Name"):WaitForObject()

	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_HEALTH_COLOR, FRIENDLY_HEALTH_COLOR, ENEMY_HEALTH_COLOR)
	local title = PlayerTitles.GetPlayerTitle(player)

	if(PLAYER_NAME_COLOR_MODE == "TEAM") then
		playerNameText:SetColor(teamColor)
	elseif(title and (PLAYER_NAME_COLOR_MODE == "TITLE")) then
		playerNameText:SetColor(title.prefixColor or COLOR_DEFAULT)
	else
		playerNameText:SetColor(PLAYER_NAME_COLOR)
	end
end

--	nil UpdateHealth(Player, CoreObject)
--	Sets the health for a player's nameplate
local function UpdateHealth(player, nameplate)
	if(not Object.IsValid(nameplate)) then return end

	local nameplateHealth = nameplate:GetCustomProperty("Health"):WaitForObject()
	SetText(nameplateHealth, string.format("%d / %d", player.hitPoints or 0, player.maxHitPoints))
end

--	nil UpdateHealthColor(Player, CoreObject)
--	Sets the health color for a player's nameplate
local function UpdateHealthColor(player, nameplate)
	if(not Object.IsValid(nameplate)) then return end

	local nameplateHealthBar = nameplate:GetCustomProperty("HealthBar"):WaitForObject()
	local teamColor = PlayerTitles.GetPlayerTeamColor(LocalPlayer, player, NEUTRAL_HEALTH_COLOR, FRIENDLY_HEALTH_COLOR, ENEMY_HEALTH_COLOR)
	nameplateHealthBar:SetColor(teamColor)
end

--	nil UpdateVisibility(Player, CoreObject)
--	Sets the visibility of a player's nameplate
local function UpdateVisibility(player, nameplate)
	if(not Object.IsValid(nameplate)) then return end

	PlayerTitles.SetVisibility(LocalPlayer, player, nameplate, SHOW_ON_SELF, SHOW_ON_NEUTRALS, SHOW_ON_FRIENDLIES, SHOW_ON_ENEMIES)
end

--	nil RotateNameplate(CoreObject)
--	Rotates a nameplate locally to face the player
local function RotateNameplate(nameplate)
	if(not Object.IsValid(nameplate)) then return end

	local quaternion = Quaternion.New(LocalPlayer:GetViewWorldRotation())
	quaternion = quaternion * Quaternion.New(Vector3.UP, 180)
	for _, object in pairs(nameplate:GetChildren()) do
		if(Object.IsValid(object)) then
			object:SetWorldRotation(Rotation.New(quaternion))
		end
	end
end

--	nil Update(CoreObject)
--	Updates Rotation, Health, HealthColor, NameColor, and Visibility of a nameplate
local function Update(nameplate)
	if(not Object.IsValid(nameplate)) then return end

	RotateNameplate(nameplate)

	local player = FindPlayerByName(nameplate.name)
	if(not player) then return end

	local dead = player.isDead
	if(dead and (not playersDead[player])) then -- died
		playersDead[player] = dead
		UpdateHealth(player, nameplate, 0)
	elseif((not dead) and playersDead[player]) then -- respawned
		playersDead[player] = dead
		UpdateHealth(player, nameplate, player.hitPoints)
	elseif((playerHealth[player] ~= nil) and (player.hitPoints ~= playerHealth[player])) then
		UpdateHealth(player, nameplate)
	end
	if((playerMaxHealth[player] ~= nil) and (player.maxHitPoints ~= playerMaxHealth[player])) then
		UpdateHealth(player, nameplate)
	end
	if((playerTeams[player] ~= nil) and (player.team ~= playerTeams[player])) then
		UpdatePlayerNameColor(player, nameplate)
		UpdateHealthColor(player, nameplate)
		UpdateVisibility(player, nameplate)
	end
end

--	string GetProperty(string, table)
--	Returns a value (string) based on a table of default options (strings)
local function GetProperty(value, options)
	value = string.upper(value)

	for _, option in pairs(options) do
		if(value == option) then return value end
	end

	return options[1]
end

------------------------------------------------------------------------------------------------------------------------
--	GLOBAL FUNCTIONS
------------------------------------------------------------------------------------------------------------------------

--	nil Tick(deltaTime)
--	Updates all nameplates every frame
function Tick()
	for _, nameplate in pairs(nameplates) do
		if(Object.IsValid(nameplate)) then
			Update(nameplate)
		end
	end
end

------------------------------------------------------------------------------------------------------------------------
--	INITIALIZATIONS
------------------------------------------------------------------------------------------------------------------------

Game.playerJoinedEvent:Connect(OnPlayerJoined)
Game.playerLeftEvent:Connect(OnPlayerLeft)

PLAYER_NAME_COLOR_MODE = GetProperty(PLAYER_NAME_COLOR_MODE, PLAYER_NAME_COLOR_MODES)`

cs:PlayerTitles�������Ε
#
cs:NameplateTemplate�
��ڰۺ�

cs:PlayerNameplates� 
�(��ڰۺ�PlayerNameplateb�(
�( �㟕���ס*��㟕���סPlayerNameplate"  �?  �?  �?(�����B2灅�����������G������LZ�

	cs:Prefix�
灅���

cs:Name�
��������G

	cs:Health�
���ܿ���

cs:HealthBar��������
#
cs:HealthBarOutline��֙�����
0
ma:Shared_BaseMaterial:color�  �?  �?  �?
(
ma:Shared_BaseMaterial:id�
⫌�����z
mc:ecollisionsetting:forceoff�
mc:evisibilitysetting:forceon�
��������  (�
 *�灅���Prefix"
  �A   �?fff?fff?(�㟕���ס2&���瀻�	��Ͼ������������ƀ���ժ�lz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j  �?  �?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*����瀻�	StrokeTopLeft"$
��̽  �? �?   �?  �?  �?(灅���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*���Ͼ���StrokeTopRight"$
��̽  �� �?   �?  �?  �?(灅���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*����������StrokeBottomLeft"$
��̽  �? ��   �?  �?  �?(灅���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�ƀ���ժ�lStrokeBottomRight"$
��̽  ��  ��   �?  �?  �?(灅���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*���������GName"
  �@   �?fff?fff?(�㟕���ס2&��쯌�������ʁ�"�����̄�����������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j  �?  �?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*���쯌��StrokeTopLeft"$
��̽  �? �?   �?  �?  �?(��������Gz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*������ʁ�"StrokeTopRight"$
��̽  �� �?   �?  �?  �?(��������Gz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*������̄��StrokeBottomLeft"$
��̽  �? ��   �?  �?  �?(��������Gz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*����������StrokeBottomRight"$
��̽  �� ��   �?  �?  �?(��������Gz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�������L	HealthBar"
   �   �?  �?  �?(�㟕���ס2��������֙��������ܿ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��������	HealthBar"
  
�#;  �?sh�=(������LZa
(
ma:Shared_BaseMaterial:id�
��¬�J
5
ma:Shared_BaseMaterial:color��";SY>���<%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������  (�
 *��֙�����HealthBarOutline"
��̽ 
�#;\��?\��=(������LZR
(
ma:Shared_BaseMaterial:id�
��¬�J
&
ma:Shared_BaseMaterial:color�%  �?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
��������  (�
 *����ܿ���Health"

�̌? �̽   �?33�>33�>(������L2'������ո>���Щƚ��������Ԡ����͹����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�m
1  �?  �?  �?%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�������ո>StrokeTopLeft"$
��̽ �?
 �?   �?  �?  �?(���ܿ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*����Щƚ��StrokeTopRight"$
��̽ ��
 �?   �?  �?  �?(���ܿ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*�������Ԡ�StrokeBottomLeft"$
��̽ �?
 ��   �?  �?  �?(���ܿ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center*����͹����StrokeBottomRight"$
��̽ ��
 ��   �?  �?  �?(���ܿ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�[%  �?%  �?-  �?2$
"mc:ecoretexthorizontalalign:center:"
 mc:ecoretextverticalalign:center
NoneNone
G��¬�JOpaque EmissiveR(
MaterialAssetReffxma_opaque_emissive
=⫌�����	InvisibleR$
MaterialAssetRefmi_invisible_001
6��������CubeR!
StaticMeshAssetRefsm_cube_002
����ۏ���LPlayerTitles_READMEZ��--[[

	Player Titles - README
	1.0.2 - 2020/10/13
	Contributors
		Nicholas Foreman (META) (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

	Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit
	for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface
	components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.


1.	Setup

	1)	Edit the PlayerTitles module (Project Content > Imported Content > Player Titles > PlayerTitles) to include you
		and anyone else you want to give special titles to.
	2)	Insert the player MUIDs into the tables; documentation is provided in the script.
	3)	Drag and drop either a "PlayerList", "PlayerNameplates", or "Scoreboard" into the hierarchy (or all three!)
	4)	Alter custom properties as you wish!


2.	Usage

	Simply edit the PlayerTitles module to include yourself as a game creator (instructions provided) and drag-and-drop
	any of the templates (PlayerList, PlayerNameplates, Scoreboard) into the hierarchy.


3.	PlayerTitles

	This contains all of the possible social titles and their respective assignments. More documentation can be found in
	the script itself.


3b.	PlayerList

	A "PlayerList" is a compact UI panel listing players and their corresponding teams and titles.


3c.	Player Nameplates

	A "PlayerNameplate" is text above a player's head indicating their username, health, and titles.


3d.	Scoreboard

	A "Scoreboard" is a large UI panel listing players and their corresponding teams and titles alongside additional
	stats, such as kills, deaths, or even resources.


4.	Discord

	If you have any questions, feel free to join the Core Hub Discord server:
		discord.gg/core-creators
	We are a friendly group of creators and players interested in the games and community on Core. Open to everyone,
	regardless of your level of experience or interests.

--]]��*�Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.

Includes:
• PlayerTitles - This contains all of the possible social titles and their respective assignments. More documentation can be found in the script itself.
• PlayerList - A compact UI panel listing players and their corresponding teams and titles.
• Player Nameplates - Text above a player's head indicating their username, health, and titles.
• Scoreboard - A large UI panel listing players and their corresponding teams and titles alongside additional stats such as kills, deaths, or even resources.

Created by @NicholasForeman of Team META
Message @Buckmonster or @NicholasForeman in Discord with feedback or feature requests - https://discord.com/invite/core-creators

Make sure to read the PlayerTitles_README file for setup and configuration instructions

Many thanks to:
• @standardcombo for review and documentation template
• @Aggripina for thumbnail design

UPDATE 1.0.6:
1) Change Leaderstats from custom property to a group within the Scoreboard

UPDATE 1.0.5:
1) Attempted fix to nameplates randomly breaking

UPDATE 1.0.4:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.3:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.2:
1) Fix Damage Bug with PlayerTitles
2) Fix PlayerNameColorMode ToolTip showing SOCIAL_STATUS instead of TITLE
3) Improve README, Documentation for files, and Comments�
�G�����Ɛ��Scoreboard (PlayerTitles)b�9
�9 ���ն�꜋*����ն�꜋Scoreboard (PlayerTitles)"  �?  �?  �?(��מ��Ʃn2��Б��Ҟ͙������Z�
 
cs:PlayerNameColorModejSTATIC
+
cs:PlayerNameColor�  �?  �?  �?%  �?
,
cs:NeutralTeamColor�  �?  �?  �?%  �?
-
cs:FriendlyTeamColor�"-y<N'�>�qe?%  �?
*
cs:EnemyTeamColor��g?��e=e=%  �?

cs:ShowTitleIconP

cs:ShowTitlePrefixP

cs:GapBetweenEntriesX
$
cs:ToggleBindingjability_extra_19

cs:ToggleEventj 

cs:ForceOnEventj 

cs:ForceOffEventj 

cs:EaseToggleP 

cs:EasingDuratione���=

cs:EasingEquationInjLINEAR

cs:EasingDirectionInjIN

cs:EasingEquationOutjLINEAR

cs:EasingDirectionOutjOUT
x
cs:PlayerNameColor:tooltipjZThe color to use for a player's username; only applicable if PlayerNameColorMode is STATIC
y
cs:PlayerNameColorMode:tooltipjWDetermines how player name colors will be shown on the playerlist | STATIC, TEAM, TITLE
N
cs:NeutralTeamColor:tooltipj/The color to use for anyone on team 0 (neutral)
`
cs:FriendlyTeamColor:tooltipj@The color to use for anyone on the same team as the Local Player
�
cs:EnemyTeamColor:tooltipjeThe color to use for anyone not on the same team as the Local Player or is on team 255 (Free for All)
�
cs:ShowTitleIcon:tooltipjqDetermines if all social status icons should be disabled or enabled based on options in the SocialStatuses module
�
cs:ShowTitlePrefix:tooltipjtDetermines if all social status prefixes should be disabled or enabled based on options in the SocialStatuses module
y
cs:ToggleBinding:tooltipj]The binding that someone presses to show/hide the leaderboard; default Tab (ability_extra_19)
R
cs:ToggleEvent:tooltipj8The event that will toggle the visibility of leaderboard
V
cs:ForceOnEvent:tooltipj;The event that will force the leaderboard to become visible
Y
cs:ForceOffEvent:tooltipj=The event that will force the leaderboard to become invisible
q
cs:EaseToggle:tooltipjXDetermines if the leaderboard should just pop in/out of place, or ease/tween/interpolate
a
cs:EasingDuration:tooltipjDThe amount of time for easing; does not apply if EaseToggle is false
�
cs:EasingEquationIn:tooltipj�The easing equation that will be used to ease in; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionIn:tooltipjiThe easing direction that will be used to ease in; does not apply if EaseToggle is false | IN, OUT, INOUT
�
cs:EasingEquationOut:tooltipj�The easing equation that will be used to ease out; does not apply if EaseToggle is false | LINEAR, QUADRATIC, CUBIC, QUARTIC, QUINTIC, SINE, EXPONENTIAL, CIRCULAR, ELASTIC, BACK, BOUNCE
�
cs:EasingDirectionOut:tooltipjjThe easing direction that will be used to ease out; does not apply if EaseToggle is false | IN, OUT, INOUTz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���Б��ҞClientContext"
    �?  �?  �?(���ն�꜋2����������퐋Ҿ��]z
mc:ecollisionsetting:forceoff�)
'mc:evisibilitysetting:inheritfromparent� *����������PlayerTitles_Scoreboard"
    �?  �?  �?(��Б��ҞZ�

cs:Scoreboard����ն�꜋
$
cs:HeaderLeaderstats����ʹ���
#
cs:HeaderSocialIcon��ل�ԫ���
$
cs:HeaderSocialPrefix�
��ԓ�Ǽ�{
#
cs:HeaderPlayerName��������
!
cs:HeaderTeamColor�
��܎چĚ


cs:Content�
��͎�բ�#


cs:Entries����Ҡ����

cs:Leaderstats�͙������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
���𕷹�*��퐋Ҿ��]	Container"
    �?  �?  �?(��Б��Ҟ2	��͎�բ�#z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�Y:

mc:euianchor:middlecenter� �4


mc:euianchor:topleft

mc:euianchor:topleft*���͎�բ�#Content"
    �?  �?  �?(�퐋Ҿ��]2낉����?������Ez(
&mc:ecollisionsetting:inheritfromparent� 
mc:evisibilitysetting:forceoff�i��:

mc:euianchor:middlecenter� �>


mc:euianchor:middlecenter

mc:euianchor:middlecenter*�낉����?Header"
    �?  �?  �?(��͎�բ�#2:�̼���Ķ���܎چĚ��������ل�ԫ�����ԓ�Ǽ�{���ʹ���z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�_<:

mc:euianchor:middlecenterP� �6


mc:euianchor:topright

mc:euianchor:topright*��̼���Ķ�
Background"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�j:

mc:euianchor:middlecenterPX�
 %  @? �6


mc:euianchor:topright

mc:euianchor:topright*���܎چĚ	TeamColor"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�}:

mc:euianchor:middlecenterX�
   �?  �?  �?%  �? �:


mc:euianchor:middleleft

mc:euianchor:middleleft*��������
PlayerName"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent����������� %   A:

mc:euianchor:middlecenterHP�2  �?  �?  �?%  �?"
mc:etextjustify:left0�4


mc:euianchor:topleft

mc:euianchor:topleft*��ل�ԫ���
SocialIcon"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent��%  �A-  ��:

mc:euianchor:middlecenter�

�������  �?  �?  �? �<


mc:euianchor:middlecenter

mc:euianchor:bottomleft*���ԓ�Ǽ�{SocialPrefix"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�����������%   A-  ��:

mc:euianchor:middlecenterHP�2   ?   ?   ?%  �?"
mc:etextjustify:left0�:


mc:euianchor:bottomleft

mc:euianchor:bottomleft*����ʹ���Leaderstats"
    �?  �?  �?(낉����?z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�f� :

mc:euianchor:middlecenter� �<


mc:euianchor:bottomright

mc:euianchor:bottomright*�������EEntriesPanel"
    �?  �?  �?(��͎�բ�#2
���Ҡ����z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�v���������:

mc:euianchor:middlecenterHPX��>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*����Ҡ����Entries"
    �?  �?  �?(������Ez(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�g:

mc:euianchor:middlecenterPX� �>


mc:euianchor:bottomcenter

mc:euianchor:bottomcenter*�͙������Leaderstats"
    �?  �?  �?(���ն�꜋2��������D�����㊛��ǥ���ԵZz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*���������DKills"
    �?  �?  �?(͙������Z3


cs:EnabledP

cs:TypejKILLS

cs:Resourcej z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*������㊛�Deaths"
    �?  �?  �?(͙������Z4


cs:EnabledP

cs:TypejDEATHS

cs:Resourcej z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�*��ǥ���ԵZCurrency"
    �?  �?  �?(͙������Z>


cs:EnabledP 

cs:TypejRESOURCE

cs:ResourcejCurrencyz(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�
NoneNone��*�Player Titles allows game creators to give special roles to themselves, dedicated players, and anyone they deem fit for recognition. With a simple module it's easy to dictate and customize a hierarchy of roles. A set of user interface components shows this special recognition for everyone: playerlist, scoreboard, and nameplate.

Includes:
• PlayerTitles - This contains all of the possible social titles and their respective assignments. More documentation can be found in the script itself.
• PlayerList - A compact UI panel listing players and their corresponding teams and titles.
• Player Nameplates - Text above a player's head indicating their username, health, and titles.
• Scoreboard - A large UI panel listing players and their corresponding teams and titles alongside additional stats such as kills, deaths, or even resources.

Created by @NicholasForeman of Team META
Message @Buckmonster or @NicholasForeman in Discord with feedback or feature requests - https://discord.com/invite/core-creators

Make sure to read the PlayerTitles_README file for setup and configuration instructions

Many thanks to:
• @standardcombo for review and documentation template
• @Aggripina for thumbnail design

UPDATE 1.0.6:
1) Change Leaderstats from custom property to a group within the Scoreboard

UPDATE 1.0.5:
1) Attempted fix to nameplates randomly breaking

UPDATE 1.0.4:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.3:
1) Altered thumbnail to emphasise the nameplates (by @Aggripina)

UPDATE 1.0.2:
1) Fix Damage Bug with PlayerTitles
2) Fix PlayerNameColorMode ToolTip showing SOCIAL_STATUS instead of TITLE
3) Improve README, Documentation for files, and Comments�
]��������Cinematic Music Score Set 01
R0
AudioBlueprintAssetRefabp_CinematicMusic_ref
>�����SkylightR%
BlueprintAssetRefCORESKY_Skylight
8�����ƺmSky DomeR 
BlueprintAssetRefCORESKY_Sky
���ؕ����IKillZoneZ��-- KillZoneServer.lua
-- Kills any player that enters this component
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

local Void = script:GetCustomProperty("Trigger"):WaitForObject()

local function enteredVoid(trigger, player)
	if(not player:IsA("Player")) then return end

	player:Die()
end

Void.beginOverlapEvent:Connect(enteredVoid)


cs:Trigger�������ۆ�
c�ԫ�ϐ��+Motion Blur Post ProcessR;
BlueprintAssetRef&fxbp_post_process_advanced_motion_blur
��������KillZoneb�
� �����諃*������諃KillZone"   A   A   A(����ݶ2
���������z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�"08*
mc:etriggershape:box*����������KillZone"
  �C n�:n�:  �?(�����諃Z


cs:Trigger������諃z(
&mc:ecollisionsetting:inheritfromparent�)
'mc:evisibilitysetting:inheritfromparent�

��ؕ����I
NoneNone