local loadMusicFiles = false
local lowMemory = true --!Dont use it now, unless you need more emotions from sound. That will reduce RAM costs when loading big files, but will take more time (Check lowMemoryBlock param).
local lowMemoryBlock = 4120000 -- Nice for 1 Mb of RAM
local lang = "English" -- English, Russian
local projectName = 'buckshot'
local maxFPS = 300
local assetsPath = string.gsub(string.gsub(require('shell').resolve(require('process').info().path), projectName, projectName.."_Data/"), 'CrushHandler', projectName.."_Data/")
local gpuBuffers = true
--Enjoy!

--Oleshe, original by Mike Klubnika, check and buy original game on itch.io!
--If you right owner and want you are content to be deleted, please, contact with me

local cmp = require('component')
local event = require('event')
local uni = require('unicode')
local term = require('term')
local fs = require('filesystem')
local seriala = require('serialization')
local gpu = cmp.gpu
local prevState = ''
for i,v in pairs(event.handlers) do
    if v.key == "UnknownEngine post sound process" then
        event.handlers[i] = nil
        break
    end
end
local function updateState(state)
    gpu.set(1,50,string.rep(' ',uni.len(prevState)))
    gpu.set(1,50,state)
    prevState = state
    if gpuBuffers then
        gpu.bitblt()
    end
end
updateState("Loading main")
local frames = 0
local lastEvent = {}
local exiting
local ingoreBackspace
local buttons = {}
local callEverytime = {}
local deltaTime = 0
local skyBoxColor = 0x111111
local scripts = {}
local removeFromETList = {}
local addFromETList = {}
local timeWas = os.clock()
local methods = {}
local waitTillETEnds = {}
local prevUserState = ''
function methods.engineLoadingState(state)
    gpu.set(160-uni.len(prevUserState),50,string.rep(' ',#prevUserState))
    gpu.set(160-uni.len(state),50,state)
    prevUserState = state
    if gpuBuffers then
        gpu.bitblt()
    end
end
local UI = {}
local symbols = {energy = "⚡",skull = "☠",emptyDot="○",fullDot = "●",rimNumOne="Ⅰ",rimNumTwo='Ⅱ',shell = "⁍"}
local colorFilter = 0xFFFFFF
local types = {
  panel = 1,
  text = 2
}
function methods.debugPrint(str,speed)
    gpu.setForeground(0xFFFFFF)
    if type(str) == 'table' then
        print(seriala.serialize(str))
    else
        print(str)
    end
    if gpuBuffers then
        gpu.bitblt()
    end
    os.sleep(speed or 1)
end
function methods.getID()
    return math.random(0,999999999)
end
updateState("Loading keyboard")
local keyboard = {
  
  ['1'] = 2,
  ['2'] = 3,
  ['3'] = 4,
  ['4'] = 5,
  ['5'] = 6,
  ['6'] = 7,
  ['7'] = 8,
  ['8'] = 9,
  ['9'] = 10,
  ['0'] = 11,
  
  A = 30,
  B = 48,
  C = 46,
  D = 32,
  E = 18,
  F = 33,
  G = 34,
  H = 35,
  I = 23,
  J = 36,
  K = 37,
  L = 38,
  M = 50,
  N = 49,
  O = 24,
  P = 25,
  Q = 16,
  R = 19,
  S = 31,
  T = 20,
  U = 22,
  V = 47,
  W = 17,
  X = 45,
  Y = 21,
  Z = 44,
  
  ['-']= 12,
  ['+'] = 13,
  BACKSPACE = 14,
  ENTER = 28,
  ['/'] = 51,
  ['.'] = 52,
  
}
--parsing keyCodes
local keyCodes = {}
for i,v in pairs(keyboard) do
  keyCodes[v] = i
end
updateState("Loading colors")
local function hexToRgb(integerColor)
  integerColor = math.ceil(integerColor)
  return integerColor >> 16, integerColor >> 8 & 0xFF, integerColor & 0xFF
end
local function rgbToHex(r, g, b)
  r,g,b = math.ceil(r), math.ceil(g),math.ceil(b)
  return r << 16 | g << 8 | b
end
local function colorMultipleByOne(clr1,num)
    local r,g,b = hexToRgb(clr1)
    return rgbToHex(r*num,g*num,b*num)
end
local function colorMinus(clr1, clr2)
    local r1,g1,b1 = hexToRgb(clr1)
    local r2,g2,b2 = hexToRgb(clr2)
    return rgbToHex(r1-r2,g1-g2,b1-b2)
end
local function colorPlus(clr1, clr2)
    local r1,g1,b1 = hexToRgb(clr1)
    local r2,g2,b2 = hexToRgb(clr2)
    return rgbToHex(r1+r2,g1+g2,b1+b2)
end
function methods.checkMaxColor(clr, isFadeIn)
    local onReview = math.max(skyBoxColor,math.min(clr,0xFFFFFF))
    if not isFadeIn and onReview == skyBoxColor then
        return clr, true
    end
    return onReview
end
function methods.setColorFilter(clr)
    colorFilter = clr
end
function methods.getColorFilter()
    return colorFilter
end
local function blend(src, filter)
    local sr, sg, sb = hexToRgb(src or 0x010101)
    local fr, fg, fb = hexToRgb(filter or 0x010101)

    local r = math.ceil((sr * fr) / 255)
    local g = math.ceil((sg * fg) / 255)
    local b = math.ceil((sb * fb) / 255)

    return rgbToHex(r, g, b)
end
gpu.setForeground(0xFFFFFF)
gpu.setBackground(skyBoxColor)
updateState("Loading filesystem")
function methods.read(path,sound)
  if fs.exists(path) then
    local bonus = 0
    if sound then
      bonus = -1
    end
    local handle = io.open(path,'r')
    local readData = handle:read(fs.size(path)+bonus)
    handle:close()
    return readData
  else
      if gpuBuffers then
        gpu.setActiveBuffer(0)
      end
      stderr:write("No file founded: " .. currentLoading..'\nPlease, check assetsPath param in the first lines of programm and package integrity\nIf needed, reinstall or bruh install full')
      os.exit(1)
  end
end
function methods.write(path, data)
  local handle = io.open(path,'w')
  handle:write(data)
  handle:close()
  return true
end
updateState("Loading scripts pre-init")
function methods.busyLoop(time)
  local start = os.clock()
  while start+time > os.clock() do end
end
function methods.execute(name,method)
    if scripts[name] then
        if scripts[name][method] then
            return scripts[name][method]()
        end
    end
    methods.debugPrint("Scripts not found: ".. name ..'.'..method)
end
--Reading all scripts and making data base
local scriptsPath = assetsPath .. 'Scripts/'
local listHandler = fs.list(scriptsPath)
--Parsing list
local scriptsFolderList = {}
local returned = true
while returned do
    returned = listHandler()
    if returned then
        table.insert(scriptsFolderList, returned)
    end
end
--loading localizations
local loc = seriala.unserialize(methods.read(assetsPath.."Localizations/"..lang..'.lang'))
--getting buffer
if gpuBuffers then
  allocatedBuffer = gpu.allocateBuffer()
  gpu.setActiveBuffer(allocatedBuffer)
end
--flush
gpu.fill(1,1,160,50,"")
--UI
updateState("Loading UI")
local function isPointInside(object, x, y)
  return 
    x >= object.x and
    x < object.x + object.w and
    y >= object.y and
    y < object.y + object.h
end
local function click(x,y,mb)
  for i, v in pairs(buttons) do
    if isPointInside(buttons[i],x,y) then
      v.onClick(i,x,y,mb)
    end
  end
end
-- UI elements
function methods.inputHandler()
  local index = methods.getID()
  local toEnd = {text = "",onInputFinished = function() end,maxInputLen = math.huge, close = function() methods.removeFromET(index) ignoreBackspace = false end}
  callEverytime[index] = function() 
    if lastEvent[1] == 'key_down' then
      if lastEvent[4] == keyboard.BACKSPACE then
        toEnd.text = string.sub(toEnd.text,1,string.len(toEnd.text)-1)
      elseif lastEvent[4] == keyboard.ENTER then
        toEnd.onInputFinished()
        toEnd.close()
      else
        if keyCodes[lastEvent[4]] then
            if uni.len(toEnd.text) < toEnd.maxInputLen then
                toEnd.text = toEnd.text .. keyCodes[lastEvent[4]]
            end
        end
      end
    end
  end
  ignoreBackspace = true
  return toEnd
end
function methods.button(x,y,w,h,color,colorText,text,onClick)
  local textIndex, buttonsIndex, panelIndex = methods.getID(), methods.getID(), methods.getID()
  buttons[buttonsIndex]={x=x,y=y,w=w,h=h,onClick=onClick}
  UI[panelIndex]={type=types.panel,x=x,y=y,w=w,h=h,color=color}
  UI[textIndex] = {type=types.text,x=x+math.ceil(w/2)-math.ceil(uni.len(text)/2),y=y+math.ceil(h/2)-1,text=text,color=colorText}
  return {buttonsIndex,panelIndex,textIndex}
end
function methods.text(x,y,color,text)
  ID = methods.getID()
  UI[ID] = {type=types.text,x=x,y=y,text=text,color=color}
  return ID
end
function methods.panel(x,y,w,h,color)
  ID = methods.getID()
  UI[ID] = {type=types.panel,x=x,y=y,w=w,h=h,color=color}
  return ID
end
function methods.flushUI()
    UI = {}
end
function methods.waitTillET(id, method)
    waitTillETEnds[id] = method
end
function methods.removeFromET(what)
    table.insert(removeFromETList,what)
end
updateState("Loading engine features")
function methods.tick(skipET) -- skipEveryTime skips scripts that need to be called every tick
  frames = frames + 1
  timeCheckpoint = os.clock()
  if not skipET then
    for i,v in pairs(callEverytime) do
      v(i)
    end
  end
  for i = 1, #removeFromETList do
    if callEverytime[removeFromETList[i]] then
        callEverytime[removeFromETList[i]] = nil
        if waitTillETEnds[removeFromETList[i]] then
            waitTillETEnds[removeFromETList[i]]()
            waitTillETEnds[removeFromETList[i]] = nil
        end
    end
  end
  removeFromETList = {}
  gpu.setBackground(0x111111)
  gpu.fill(1,1,160,50, " ")
  for _, v in pairs(UI) do
    gpu.setBackground(0x111111)
    obj = v
    if obj.type == types.panel then
      gpu.setBackground(blend(obj.color,colorFilter))
      gpu.fill(obj.x,obj.y,obj.w,obj.h," ")
    elseif obj.type == types.text then
      gpu.setForeground(blend(obj.color,colorFilter))
      gpu.set(obj.x,obj.y,obj.text)
    end
  end
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x0)
  gpu.set(1,1,tostring(frames) .. "|" .. deltaTime)
  if gpuBuffers then
    gpu.bitblt()
  end
  deltaTime = timeCheckpoint-timeWas
  while os.clock() < timeWas + 1/maxFPS do end
  deltaTime = math.max(deltaTime,deltaTime + (1/maxFPS -deltaTime))
  timeWas = os.clock()
end
--main init
function methods.fadeIn(to,speed)
  speed = speed or 100
  to = to or 0xFFFFFF
  local ID = methods.getID()
  callEverytime[ID] = function()
    colorFilter, done = methods.checkMaxColor(colorPlus(colorFilter, colorMultipleByOne(0x010101,deltaTime*speed)), true)
    if colorFilter >= to or done then
        methods.removeFromET(ID)
        return
    end
  end
end
function methods.fadeOut(to,speed)
  speed = speed or 100
  to = to or 0x0
  local ID = methods.getID()
  callEverytime[ID] = function()
    colorFilter, done = methods.checkMaxColor(colorMinus(colorFilter, colorMultipleByOne(0x010101,deltaTime*speed)))
    if colorFilter < to or done  then
        methods.removeFromET(ID)
        return
    end
  end
end
--loading sound stuff
updateState("Loading sound")
local musicFilesCashe = {}
local sounds
local soundsPath = assetsPath.."Sounds/"
if loadMusicFiles then
  sounds = {"Before Every Load","70K","General Release","Socket Calibration","You are an Angel"}
  for i = 1, #sounds do
    local currentLoading = soundsPath..sounds[i]..".dfpwm"
    sounds[sounds[i]] = methods.read(currentLoading,true)
    os.sleep(0)
    sounds[i] = nil
  end
end
function methods.playSound(name, fadeIn)
  if cmp.isAvailable('tape_drive') then
    local tape = cmp.tape_drive
    tape.stop()
    tape.seek(-tape.getSize())
    tape.stop()
    local songLenght
    if loadMusicFiles then
      tape.write(sounds[name])
      songLenght = #sounds[name]
    else
      local path = soundsPath..name..'.dfpwm'
      local handle = io.open(path,'rb')
      songLenght = fs.size(path)
      local readData = 1
      if lowMemory then
        local filesize = fs.size(path)
        local bytery = 0
        repeat
          local bytes = handle:read(lowMemoryBlock)
          if bytes and #bytes > 0 then
            bytery = bytery + #bytes
            tape.write(bytes)
          end
        until not bytes or bytery > filesize
      else
        tape.write(handle:read(fs.size(path)-1))
      end
      handle:close()
      tape.stop()
      tape.seek(-tape.getSize())
      tape.stop()
    end
    tape.seek(-tape.getSize())
    if fadeIn then
      tape.setVolume(0)
    end
    local i = 0
    local need = 0
    local speed = 0.025
    local ID = methods.getID()
    callEverytime[ID] = function()
      need = deltaTime + need
      if need >= speed then
        need = 0
        i = i + 0.01
        if i == 1 then
          methods.removeFromET(ID)
          return
        end
        tape.setVolume(i)
      end
    end
    local ID2 = methods.getID()
    callEverytime[ID2] = function()
        if tape.getPosition() >= songLenght then
            tape.seek(-math.huge)
            tape.play()
        end
    end
    tape.setLabel(name)
    tape.play()
  end
end
function methods.stopSounds()
  if cmp.isAvailable('tape_drive') then
    local i = 1
    if exiting then
        local index
        index = event.register("UnknownEngine post sound process",function()
           i = i - 0.01
           cmp.tape_drive.setVolume(i)
          if i <= 0 then
            event.cancel(index)
            cmp.tape_drive.stop()
            cmp.tape_drive.setVolume(1)
            cmp.tape_drive.seek(-math.huge)
          end
        end,0.025,math.huge)
    else
        while true do
          i = i - 0.01
          methods.busyLoop(0.025)
          if i <= 0 then
            break
          end
          cmp.tape_drive.setVolume(i)
        end
        cmp.tape_drive.stop()
     end
  end
end
updateState("Compiling scripts...")
-- Big thanks to fingercomp bc i dont know how is this shi works
local globalEnv = setmetatable({}, {__index = _ENV})
local function runScript(code, privateVars, name)
  local vars = {}
  local sharedNames = {}
  local privateNames = {}
  local privateNamesVars = {}
  privateVars = privateVars or {}
  for i, _ in pairs(privateVars) do
    privateNamesVars[i] = true
  end
  local envMeta = {
    __index = function(self, k)
      if sharedNames[k] then
        return shared[k]
      elseif privateNamesVars[k] then
        return privateVars[k]
      elseif
          privateNames[k]
          or vars[k] ~= nil then 
        return vars[k]
      end

      return globalEnv[k]
    end,

    __newindex = function(self, k, v)
      if rawequal(sharedToken, v) then
        sharedNames[k] = true
      elseif sharedNames[k] then
        shared[k] = v
      elseif privateNamesVars[k] then
        privateVars[k] = v
      else
        privateNames[k] = true
        vars[k] = v
      end
    end,
  }

  assert(load(code, name, nil, setmetatable({}, envMeta)))()

  return vars
end
-- Yeah, that all was fingercomp, lady and gentelmans! Cool guy
function methods.deepcopy(orig) -- For 'load scene'
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[methods.deepcopy(orig_key)] = methods.deepcopy(orig_value)
        end
        setmetatable(copy, methods.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end
function methods.invoke(code,time)
    local timeWas = os.clock()
    local id = methods.getID()
    callEverytime[id] = function()
        if timeWas + time < os.clock() then
            methods.removeFromET(id)
            code()
        end
    end
end
--Compiling scripts
local nowMethods = methods.deepcopy(methods)
nowMethods.loc = loc
nowMethods.callEverytime = callEverytime
nowMethods.UI = UI
nowMethods.symbols = symbols
nowMethods.skyBoxColor = skyBoxColor
nowMethods.scripts = scripts
nowMethods.assetsPath = assetsPath
nowMethods.rootPath = string.gsub(assetsPath,'Buckshot_Data/','')
for i = 1, #scriptsFolderList do 
    scripts[string.gsub(scriptsFolderList[i],'.lua','')] = runScript(methods.read(scriptsPath..'/'..scriptsFolderList[i]), nowMethods, scriptsFolderList[i])
    os.sleep(0)
end
function methods.exit()
    exiting = true
    methods.flushUI()
    if gpuBuffers then
        gpu.setActiveBuffer(0)
        gpu.freeBuffer(allocatedBuffer)
    end
    methods.tick(true)
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x0)
    updateState('Exiting...')
    methods.stopSounds()
    term.clear()
    --Bye!
    os.exit(0)
end
updateState("Starting")
--Executing all Scripts
for i, v in pairs(scripts) do
    if v["Start"] then
        v["Start"]()
    end
end
methods.engineLoadingState = nil
local waitFPS = os.clock()
--main loop
while true do
  local name,_,e1,e2,e3 = event.pull(0)
  lastEvent = {name,"",e1,e2,e3}
  if waitFPS < os.clock() then
    frames = 0
    waitFPS = os.clock() + 1
  end
  if name == 'key_up' then
    if e2 == 14 and not ignoreBackspace then
      methods.exit()
    end
  end
  methods.tick()
end