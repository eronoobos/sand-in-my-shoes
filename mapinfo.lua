--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- mapinfo.lua
--

local mapinfo = {
	name        = "Sand in my Shoes",
	shortname   = "sandinmyshoes",
	description = "sand dunes",
	author      = "eronoobos",
	version     = "1",
	--mutator   = "deployment";
	--mapfile   = "", --// location of smf/sm3 file (optional)
	modtype     = 3, --// 1=primary, 0=hidden, 3=map
	depend      = {"Map Helper v1"},
	replace     = {},

	maphardness     = 100,
	notDeformable   = false,
	gravity         = 75,
	tidalStrength   = 0,
	maxMetal        = 0.64,
	extractorRadius = 100.0,
	voidWater       = true,
	autoShowMetal   = true,


	smf = {
		minheight = 400,
		maxheight = 700,
	},

	sound = {
		preset = "mountains",
		passfilter = {
			gainlf = 1.0,
			gainhf = 1.0,
		},
		reverb = {},
	},

	resources = {
		--grassBladeTex = "",
		--grassShadingTex = "",
		-- detailTex = "detailtex.png",
		-- specularTex = "spec.tga",
		-- splatDetailTex = "splattex.tga",
		-- splatDistrTex = "splatdist.tga",
		-- skyReflectModTex = "skyreflect.bmp",
		-- detailNormalTex = "normal.tga",
		--lightEmissionTex = "",
	},

	splats = {
		texScales = {0.007, 0.0075, 0.008, 0.008},
		texMults  = {0.3, 0.4, 0.25, 0.5},
	},

	atmosphere = {
		minWind      = 5.0,
		maxWind      = 20.0,

		fogStart     = 0.4,
		fogEnd       = 0.8,
		fogColor     = {0.66, 0.62, 0.49},

		sunColor     = {0.95, 0.95, 1.0},
		skyColor     = {0.63, 0.76, 0.70},
		skyDir       = {-1.0, 0.0, 0.0},
		skyBox       = "",

		cloudDensity = 0.15,
		cloudColor   = {0.85, 0.80, 0.9},
	},

	grass = {
		bladeWaveScale = 1.0,
		bladeWidth  = 0.32,
		bladeHeight = 4.0,
		bladeAngle  = 1.57,
		bladeColor  = {0.59, 0.81, 0.57}, --// does nothing when `grassBladeTex` is set
	},

	lighting = {
		--// dynsun
		sunStartAngle = 0.0,
		sunOrbitTime  = 1440.0,
		sunDir        = {1.0, 0.4, 0.0, 1e9},

		--// unit & ground lighting
		groundAmbientColor  = {0.5, 0.5, 0.5},
		groundDiffuseColor  = {1.0, 1.0, 1.0},
		groundSpecularColor = {0.5, 0.5, 0.5},
		groundShadowDensity = 1.0,
		unitAmbientColor    = {0.55, 0.5, 0.45},
		unitDiffuseColor    = {0.975, 0.975, 1.05},
		unitSpecularColor   = {0.45, 0.55, 0.5},
		unitShadowDensity   = 0.5,
		specularExponent    = 100.0,
	},

	teams = {
		-- dummy start positions, overwritten completely after map generation
		[0] = {startPos = {x = 1228, z = 1228}},
		[1] = {startPos = {x = 4916, z = 4916}},
		[2] = {startPos = {x = 1228, z = 3684}},
		[3] = {startPos = {x = 4916, z = 2456}},
		[4] = {startPos = {x = 2456, z = 4916}},
		[5] = {startPos = {x = 3684, z = 1228}},
		[6] = {startPos = {x = 2456, z = 2456}},
		[7] = {startPos = {x = 3684, z = 3684}},
	},

	terrainTypes = {
		[0] = {
			name = "Default",
			hardness = 1.0,
			receiveTracks = false,
			moveSpeeds = {
				tank  = 1.0,
				kbot  = 1.0,
				hover = 1.0,
				ship  = 1.0,
			},
		},
	},
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Helper

local function lowerkeys(ta)
	local fix = {}
	for i,v in pairs(ta) do
		if (type(i) == "string") then
			if (i ~= i:lower()) then
				fix[#fix+1] = i
			end
		end
		if (type(v) == "table") then
			lowerkeys(v)
		end
	end
	
	for i=1,#fix do
		local idx = fix[i]
		ta[idx:lower()] = ta[idx]
		ta[idx] = nil
	end
end

lowerkeys(mapinfo)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Map Options

if (Spring) then
	local function tmerge(t1, t2)
		for i,v in pairs(t2) do
			if (type(v) == "table") then
				t1[i] = t1[i] or {}
				tmerge(t1[i], v)
			else
				t1[i] = v
			end
		end
	end

	-- make code safe in unitsync
	if (not Spring.GetMapOptions) then
		Spring.GetMapOptions = function() return {} end
	end
	function tobool(val)
		local t = type(val)
		if (t == 'nil') then
			return false
		elseif (t == 'boolean') then
			return val
		elseif (t == 'number') then
			return (val ~= 0)
		elseif (t == 'string') then
			return ((val ~= '0') and (val ~= 'false'))
		end
		return false
	end

	getfenv()["mapinfo"] = mapinfo
		local files = VFS.DirList("mapconfig/mapinfo/", "*.lua")
		table.sort(files)
		for i=1,#files do
			local newcfg = VFS.Include(files[i])
			if newcfg then
				lowerkeys(newcfg)
				tmerge(mapinfo, newcfg)
			end
		end
	getfenv()["mapinfo"] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return mapinfo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------