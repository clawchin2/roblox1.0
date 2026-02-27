--!strict
-- SoundManager.lua
-- Centralized audio system for Endless Escape
-- Location: ReplicatedStorage/Modules/SoundManager.lua
-- Handles: SFX, background music, volume controls, mute functionality

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SoundManager = {}

-- ============================================================================
-- ASSET IDs - Free Roblox assets
-- ============================================================================
local SOUND_IDS = {
	Jump = "rbxassetid://376021808",
	CoinCollect = "rbxassetid://1997914399",
	Death = "rbxassetid://5801257795",
	Checkpoint = "rbxassetid://175659077",
	Milestone = "rbxassetid://1537979440",
	BackgroundMusic = "rbxassetid://1838618353",
}

-- ============================================================================
-- VOLUME SETTINGS
-- ============================================================================
local DEFAULT_VOLUMES = {
	SFX = 0.6,        -- Sound effects (0.5-0.7 range)
	Music = 0.3,      -- Background music (lower for background)
	Master = 1.0,     -- Master volume multiplier
}

-- ============================================================================
-- STATE
-- ============================================================================
local state = {
	isMuted = false,
	volumes = table.clone(DEFAULT_VOLUMES),
	soundCache = {} :: {[string]: Sound},
	musicSound = nil :: Sound?,
	milestoneReached = {
		[100] = false,
		[250] = false,
		[500] = false,
		[1000] = false,
		[2500] = false,
		[5000] = false,
	},
	lastDistance = 0,
	isServer = false,
}

-- ============================================================================
-- REMOTE EVENTS (for client-server sync)
-- ============================================================================
local AudioEvents = nil
local PlaySoundEvent = nil

local function initRemoteEvents()
	AudioEvents = ReplicatedStorage:FindFirstChild("AudioEvents")
	if not AudioEvents then
		AudioEvents = Instance.new("Folder")
		AudioEvents.Name = "AudioEvents"
		AudioEvents.Parent = ReplicatedStorage
		
		PlaySoundEvent = Instance.new("RemoteEvent")
		PlaySoundEvent.Name = "PlaySound"
		PlaySoundEvent.Parent = AudioEvents
	else
		PlaySoundEvent = AudioEvents:WaitForChild("PlaySound") :: RemoteEvent
	end
end

-- ============================================================================
-- SOUND CREATION
-- ============================================================================
local function createSound(name: string, id: string, volume: number, looped: boolean?): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped or false
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = 100
	sound.RollOffMinDistance = 10
	return sound
end

-- ============================================================================
-- CLIENT-SIDE SOUND PLAYING
-- ============================================================================
local function playSoundClient(soundName: string, pitchShift: number?)
	if state.isMuted then return end
	
	local id = SOUND_IDS[soundName]
	if not id then
		warn("[SoundManager] Unknown sound: " .. tostring(soundName))
		return
	end
	
	-- Check cache for reusable sounds
	local cached = state.soundCache[soundName]
	if cached and cached.Parent then
		cached:Play()
		return
	end
	
	-- Determine volume based on sound type
	local baseVolume = DEFAULT_VOLUMES.SFX
	if soundName == "BackgroundMusic" then
		baseVolume = DEFAULT_VOLUMES.Music
	end
	
	local finalVolume = baseVolume * state.volumes.Master
	
	-- Create and play sound
	local sound = createSound(soundName, id, finalVolume, soundName == "BackgroundMusic")
	
	-- Apply pitch shift if specified (for variety)
	if pitchShift then
		sound.PlaybackSpeed = pitchShift
	end
	
	-- Parent to SoundService for global audio
	sound.Parent = SoundService
	
	-- Cache non-music sounds for reuse
	if soundName ~= "BackgroundMusic" then
		state.soundCache[soundName] = sound
		
		-- Clean up after playing
		sound.Ended:Connect(function()
			sound.Parent = nil
		end)
	end
	
	sound:Play()
	
	return sound
end

-- ============================================================================
-- MUSIC MANAGEMENT
-- ============================================================================
function SoundManager:StartMusic()
	if state.isServer then return end -- Only client plays music
	if state.isMuted then return end
	
	-- Stop existing music
	if state.musicSound and state.musicSound.Parent then
		state.musicSound:Destroy()
	end
	
	-- Create new music instance
	local music = createSound("BackgroundMusic", SOUND_IDS.BackgroundMusic, state.volumes.Music * state.volumes.Master, true)
	music.Parent = SoundService
	music:Play()
	
	state.musicSound = music
end

function SoundManager:StopMusic()
	if state.musicSound and state.musicSound.Parent then
		state.musicSound:Destroy()
		state.musicSound = nil
	end
end

-- ============================================================================
-- SFX TRIGGERS
-- ============================================================================
function SoundManager:PlayJump()
	if state.isServer then
		-- Server tells client to play
		if PlaySoundEvent then
			PlaySoundEvent:FireAllClients("Jump")
		end
	else
		playSoundClient("Jump", 0.9 + math.random() * 0.2) -- Slight pitch variety
	end
end

function SoundManager:PlayCoinCollect()
	if state.isServer then
		if PlaySoundEvent then
			PlaySoundEvent:FireAllClients("CoinCollect")
		end
	else
		-- Higher pitch for consecutive coins
		local pitch = 1.0 + (math.random() * 0.3)
		playSoundClient("CoinCollect", pitch)
	end
end

function SoundManager:PlayDeath()
	if state.isServer then
		if PlaySoundEvent then
			PlaySoundEvent:FireAllClients("Death")
		end
	else
		playSoundClient("Death")
		-- Fade out music temporarily
		if state.musicSound then
			state.musicSound.Volume = state.volumes.Music * 0.1
			task.delay(3, function()
				if state.musicSound and not state.isMuted then
					state.musicSound.Volume = state.volumes.Music * state.volumes.Master
				end
			end)
		end
	end
end

function SoundManager:PlayCheckpoint()
	if state.isServer then
		if PlaySoundEvent then
			PlaySoundEvent:FireAllClients("Checkpoint")
		end
	else
		playSoundClient("Checkpoint")
	end
end

function SoundManager:PlayMilestone()
	if state.isServer then
		if PlaySoundEvent then
			PlaySoundEvent:FireAllClients("Milestone")
		end
	else
		playSoundClient("Milestone")
		-- Temporarily boost music volume for celebration
		if state.musicSound and not state.isMuted then
			local originalVol = state.musicSound.Volume
			state.musicSound.Volume = math.min(originalVol * 1.5, 0.8)
			task.delay(2, function()
				if state.musicSound then
					state.musicSound.Volume = originalVol
				end
			end)
		end
	end
end

-- ============================================================================
-- DISTANCE-BASED MILESTONE CHECKING
-- ============================================================================
function SoundManager:CheckMilestones(distance: number)
	if state.isServer then return end -- Client handles milestone sounds
	
	-- Check each milestone
	for milestone, reached in pairs(state.milestoneReached) do
		if not reached and distance >= milestone then
			state.milestoneReached[milestone] = true
			self:PlayMilestone()
			
			-- Visual feedback could be triggered here too
			print(string.format("[SoundManager] Milestone reached: %dm!", milestone))
		end
	end
	
	state.lastDistance = distance
end

function SoundManager:ResetMilestones()
	for milestone, _ in pairs(state.milestoneReached) do
		state.milestoneReached[milestone] = false
	end
	state.lastDistance = 0
end

-- ============================================================================
-- VOLUME CONTROLS
-- ============================================================================
function SoundManager:SetMasterVolume(volume: number)
	state.volumes.Master = math.clamp(volume, 0, 1)
	self:UpdateSoundVolumes()
end

function SoundManager:SetSFXVolume(volume: number)
	state.volumes.SFX = math.clamp(volume, 0, 1)
	self:UpdateSoundVolumes()
end

function SoundManager:SetMusicVolume(volume: number)
	state.volumes.Music = math.clamp(volume, 0, 1)
	self:UpdateSoundVolumes()
end

function SoundManager:UpdateSoundVolumes()
	local effectiveMuted = state.isMuted and 0 or 1
	
	-- Update music volume
	if state.musicSound then
		state.musicSound.Volume = state.volumes.Music * state.volumes.Master * effectiveMuted
	end
	
	-- Update cached SFX volumes
	for name, sound in pairs(state.soundCache) do
		if sound and sound.Parent then
			sound.Volume = state.volumes.SFX * state.volumes.Master * effectiveMuted
		end
	end
end

-- ============================================================================
-- MUTE TOGGLE
-- ============================================================================
function SoundManager:ToggleMute(): boolean
	state.isMuted = not state.isMuted
	
	if state.isMuted then
		-- Mute all sounds
		if state.musicSound then
			state.musicSound.Volume = 0
		end
		for _, sound in pairs(state.soundCache) do
			if sound and sound.Parent then
				sound.Volume = 0
			end
		end
	else
		-- Restore volumes
		self:UpdateSoundVolumes()
	end
	
	return state.isMuted
end

function SoundManager:SetMuted(muted: boolean)
	state.isMuted = muted
	self:UpdateSoundVolumes()
end

function SoundManager:IsMuted(): boolean
	return state.isMuted
end

function SoundManager:GetVolumes()
	return {
		Master = state.volumes.Master,
		SFX = state.volumes.SFX,
		Music = state.volumes.Music,
	}
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
function SoundManager:Init(isServer: boolean?)
	state.isServer = isServer or false
	
	initRemoteEvents()
	
	-- Client-side initialization
	if not state.isServer then
		-- Listen for server sound requests
		if PlaySoundEvent then
			PlaySoundEvent.OnClientEvent:Connect(function(soundName: string)
				playSoundClient(soundName)
			end)
		end
		
		-- Start background music when player joins
		task.delay(2, function()
			self:StartMusic()
		end)
		
		print("[SoundManager] Client initialized - Audio system ready!")
	else
		print("[SoundManager] Server initialized")
	end
	
	return self
end

return SoundManager