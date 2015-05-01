function widget:GetInfo()
	 return {
			name      = "Shader Heightmap",
			desc      = "Makes a heightmap w/ GLSL.",
			author    = "eronoobos",
			version   = "1",
			date      = "2015",
			license   = "GPLv2",
			layer     = 1,
			enabled   = false,
	 }
end

local mCeil = math.ceil
local mFloor = math.floor

local heightmapPath = "heightmap.png"
local GL_LUMINANCE32F_ARB = 0x8818
local maxPacketArea = 8096

local outRects
local minData, maxData, diffData, multData
local needToDraw = true

local perlinGLSL = VFS.LoadFile('LuaUI/shaders/perlin.frag')
local duneGLSL = VFS.LoadFile('LuaUI/shaders/dune.frag')
local windGLSL = VFS.LoadFile('LuaUI/shaders/wind.frag')

local heightmapScaleGLSL = [[
	uniform sampler2D heightmapTex;
	uniform float maxPos, maxNeg;
	void main() {
		gl_FragColor = texture2D(heightmapTex, gl_TexCoord[0].st);
		gl_FragColor.rgb = (gl_FragColor.rgb - maxNeg) / (maxPos - maxNeg);
	}
]]

local invertGLSL = [[
	uniform sampler2D heightmapTex;
	void main() {
		vec4 color = texture2D(heightmapTex, gl_TexCoord[0].st);
		gl_FragColor= vec4( 1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a );
	}
]]

local function PackPixels(pixels)
	local height = #pixels
	local width = #pixels[1]
	local area = height * width
	local rects = mFloor(area / maxPacketArea)
	local rectArea = mFloor(area / rects)
	local rwidth = mFloor(math.sqrt(rectArea))
	local rheight = rwidth
	if maxPacketArea > area then
		rects = 1
		rwidth = width
		rheight = height
	end
	Spring.Echo(width, height, area, rects, rwidth, rheight)
	local outRects = {}
	local minData, maxData = 99999, 0
	for z1 = 0, height-2, rheight do
		for x1 = 0, width-2, rwidth do
			local data = {}
			local x2 = math.min(x1+(rwidth-1), width-1)
			local z2 = math.min(z1+(rheight-1), height-1)
			for z = z1+1, z2+1 do
				for x = x1+1, x2+1 do
					if not pixels[z] then Spring.Echo(x, z) end
					local point = pixels[z][x]
					if not point then Spring.Echo(x, z) end
					-- if z == 1 then Spring.Echo(x, point[1], point[2], point[3], point[4]) end
					local d = point[1]
					if d < minData then minData = d end
					if d > maxData then maxData = d end
					table.insert(data, d)
				end
			end
			table.insert(outRects, {x1=x1, z1=z1, x2=x2, z2=z2, data=data})
		end
	end
	local diffData = maxData - minData
	local multData = 65535 / diffData
	Spring.Echo(minData, maxData, #outRects)
	return outRects, minData, maxData, multData
end

function widget:DrawGenesis()
	if not needToDraw then return end

	-- local perShader = gl.CreateShader({ fragment = perlinGLSL })
	-- errors = gl.GetShaderLog(perShader)
	-- if errors ~= "" then
	-- 		Spring.Echo(errors)
	-- end
	-- local perPID       = gl.GetUniformLocation(perShader, "p")
	-- local perHeightID      = gl.GetUniformLocation(perShader, "height")
	-- local perSizeID       = gl.GetUniformLocation(perShader, "size")
	-- local perOffsetID       = gl.GetUniformLocation(perShader, "offset")

	-- local winShader = gl.CreateShader({ fragment = windGLSL })
	-- errors = gl.GetShaderLog(winShader)
	-- if errors ~= "" then Spring.Echo(errors) end
	-- local winTextureID = gl.GetUniformLocation(winShader, "texture")
	-- local winOffetsID       = gl.GetUniformLocation(winShader, "offsets")
	-- local winDirectionID      = gl.GetUniformLocation(winShader, "direction")
	-- local winStrenghID      = gl.GetUniformLocation(winShader, "strengh")
	-- local winStrengh2ID       = gl.GetUniformLocation(winShader, "strengh2")

	local dunShader = gl.CreateShader({ fragment = duneGLSL })
	errors = gl.GetShaderLog(dunShader)
	if errors ~= "" then Spring.Echo(errors) end
	local dunPreviousID = gl.GetUniformLocation(dunShader, "PreviousSandDuneBuffer")
	local dunScreenSizeID = gl.GetUniformLocation(dunShader, "ScreenSize")
	local dunInitializeID = gl.GetUniformLocation(dunShader, "initialize")
	local dunRandSeedID = gl.GetUniformLocation(dunShader, "randSeed")
	local dunRandSeedLengthID = gl.GetUniformLocation(dunShader, "randSeedLength")

	local texInfo = gl.TextureInfo("$heightmap")

	local heightmapTexture = gl.CreateTexture(texInfo.xsize, texInfo.ysize, {
			border = false,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
	})
	local heightmapTexture2 = gl.CreateTexture(texInfo.xsize, texInfo.ysize, {
			border = false,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
	})
	local heightmapTexture3 = gl.CreateTexture(texInfo.xsize, texInfo.ysize, {
			border = false,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
	})

	if VFS.FileExists("heightmap-noise.png", VFS.RAW) then
			Spring.Echo("removing the existing heightmap")
			os.remove("heightmap-noise.png")
	end

	if VFS.FileExists("heightmap-wind.png", VFS.RAW) then
			Spring.Echo("removing the existing heightmap")
			os.remove("heightmap-wind.png")
	end

	local randSeeds = {}
	for i = 1, 50 do
		table.insert(randSeeds, math.random())
	end

	-- gl.UseShader(perShader)
	-- gl.Uniform(perHeightID, 1.0)
	-- gl.Uniform(perSizeID, 12)
	-- gl.Uniform(perOffsetID, 0.0)
	-- -- gl.Texture(0, heightmapTexture)
	-- gl.RenderToTexture(heightmapTexture,
	-- function()
	-- 	gl.TexRect(-1,-1, 1, 1)
	-- 	-- gl.SaveImage(0, 0, texInfo.xsize, texInfo.ysize, "heightmap-noise.png")
	-- end)
	-- gl.Texture(0, false)
	-- gl.UseShader(0)

	local reps = 100
	local res = false
	for n = 1, reps do
		gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0)
		gl.DepthTest(false)
		gl.Blending(false)
		gl.UseShader(dunShader)
		gl.UniformInt(dunPreviousID, 0)
		gl.Uniform(dunScreenSizeID, texInfo.xsize, texInfo.ysize)
		gl.UniformInt(dunInitializeID, 1)
		gl.UniformArray(dunRandSeedID, 1, randSeeds)
		gl.UniformInt(dunRandSeedLengthID, 50)
		if n >= 2 then
			gl.UniformInt(dunInitializeID, 0)
		end
		local renderSource = heightmapTexture
		local renderTarget = heightmapTexture2
		if n % 2 == 0 then
			renderSource = heightmapTexture2
			renderTarget = heightmapTexture
		end
		gl.Texture(0, renderSource)
		gl.RenderToTexture(renderTarget, function()
			gl.TexRect(-1, -1, 1, 1)
			if n == reps then
				res = gl.ReadPixels(0, 0, texInfo.xsize, texInfo.ysize)
				-- gl.SaveImage(0, 0, texInfo.xsize, texInfo.ysize, "heightmap-wind.png")
			end
		end)
		gl.UseShader(0)
		gl.Texture(false)
	end

	--[[
	gl.UseShader(winShader)
	 gl.UniformInt(winTextureID, 0)
	 gl.Uniform(winOffetsID, 1/texInfo.xsize, 1/texInfo.ysize)
	 gl.Uniform(winDirectionID, 0.0)
	 gl.Uniform(winStrenghID, 0.5)
	 gl.Uniform(winStrengh2ID, 0.5)
	 local reps = 1000
	 local res = false
	for n = 1, reps do
	 local even = n % 2 == 0
	 local renderSource = heightmapTexture
	 if even then
			renderSource = heightmapTexture2
	 end
	 gl.Texture(0, renderSource)
		local renderTarget = heightmapTexture2
		if even then renderTarget = heightmapTexture end
		gl.RenderToTexture(renderTarget,
	 function()
			gl.TexRect(-1, -1, 1, 1)
			if n == reps then
				res = gl.ReadPixels(0, 0, texInfo.xsize, texInfo.ysize)
				-- gl.SaveImage(0, 0, texInfo.xsize, texInfo.ysize, "heightmap-wind.png")
			end
	 end)
	end
	]]--

	gl.DeleteTexture(heightmapTexture)
	gl.DeleteTexture(heightmapTexture2)

	if res then
		Spring.Echo("got pixels")
		outRects, minData, maxData, multData = PackPixels(res)
	else
		Spring.Echo("no pixels")
	end

	needToDraw = false
end

function widget:GameFrame(frame)
	if frame % 2 ~= 0 then return end
	if outRects then
		local rect = table.remove(outRects)
		local data = {}
		for i, d in ipairs(rect.data) do
			local v = (d - minData) * multData
			table.insert(data, v)
		end
		local dataStr = VFS.PackU16(data)
		-- local length =
		dataStr = VFS.ZlibCompress(dataStr)
		Spring.SendLuaGaiaMsg(table.concat({'HIO', 'p', 'z', rect.x1, rect.z1, rect.x2, rect.z2, 200, 400, dataStr}, " "))
		-- Spring.Echo("sent height packet")
		if #outRects == 0 then
			Spring.Echo("done sending heightmap")
			outRects = nil
		end
	end
end