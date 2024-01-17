local loadMusicFiles =false
local lang = "English" -- English, Russian
local assetsPath = string.gsub(require('shell').resolve(require('process').info().path),'buckshot', "Buckshot_Data/")
local gpuBuffers = false
--Enjoy!
--Oleshe, original by Mike Klubnika, check and buy original game on itch.io!
--If you right owner and want ur conted to be deleted, please, contact with me
local cmp = require('component')
local event = require('event')
local uni = require('unicode')
local fs = require('filesystem')
local seriala = require('serialization')
local gpu = cmp.gpu
local allocatedBuffer
local lastEvent = {}
local ingoreBackspace
local buttons = {}
local callEverytime = {}
local deltaTime = 0
local scripts = {}
local timeWas = os.clock()
local methods = {}
local UI = {}
local symbols = {energy = "⚡",skull = "☠",emptyDot="○",fullDot = "●",rimNumOne="Ⅰ",rimNumTwo='Ⅱ',shell = "⁍"}
local colorFilter = 0xFFFFFF
local types = {
  panel = 1,
  text = 2
}
local itemsID = {
    beer = 1,
    glass = 2,
    handcuffs = 3,
    vape = 4,
    saw = 5
}
local function getID()
    return math.random(0,999999999)
end
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
local function hexToRgb(integerColor)
  return integerColor >> 16, integerColor >> 8 & 0xFF, integerColor & 0xFF
end
local function rgbToHex(r, g, b)
  return r << 16 | g << 8 | b
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
gpu.setBackground(0x111111)
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
      print("No file founded: " .. currentLoading..'\nPlease, check assetsPath param in first lines of programm')
      os.exit(1)    
  end
end
function methods.busyLoop(time)
  local start = os.clock()
  while start+time > os.clock() do end
end
function methods.write(path, data)
  local handle = io.open(path,'w')
  handle:write(data)
  handle:close()
  return true
end
function methods.execute(name,method)
    return scripts[name][method]()
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
  local index = getID()
  local toEnd = {text = "",onInputFinished = function() end, close = function() callEverytime[index] = nil ignoreBackspace = false end}
  callEverytime[index] = function() 
    if lastEvent[1] == 'key_down' then
      if lastEvent[4] == keyboard.BACKSPACE then
        toEnd.text = string.sub(toEnd.text,1,string.len(toEnd.text)-1)
      elseif lastEvent[4] == keyboard.ENTER then
        callEverytime[index] = nil
        toEnd.onInputFinished()
      else
        if keyCodes[lastEvent[4]] then
            toEnd.text = toEnd.text .. keyCodes[lastEvent[4]]
        end
      end
    end
  end
  ignoreBackspace = true
  return toEnd
end
function methods.button(x,y,w,h,color,colorText,text,onClick)
  local textIndex, buttonsIndex, panelIndex = getID(), getID(), getID()
  buttons[buttonsIndex]={x=x,y=y,w=w,h=h,onClick=onClick}
  UI[panelIndex]={type=types.panel,x=x,y=y,w=w,h=h,color=color}
  UI[textIndex] = {type=types.text,x=x+math.ceil(w/2)-math.ceil(uni.len(text)/2),y=y+math.ceil(h/2)-1,text=text,color=colorText}
  return {buttonsIndex,panelIndex,textIndex}
end
function methods.text(x,y,color,text)
  ID = getID()
  UI[ID] = {type=types.text,x=x,y=y,text=text,color=color}
  return ID
end
function methods.panel(x,y,w,h,color)
  ID = getID()
  UI[ID] = {type=types.panel,x=x,y=y,w=w,h=h,color=color}
  return ID
end
function methods.tick(skipET) -- skipEveryTime thing
  deltaTime = os.clock()-timeWas
  timeWas = os.clock()
  if not skipET then
    for i,v in pairs(callEverytime) do
      v(i)
    end
  end
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
  if gpuBuffers then
    gpu.bitblt()
  end
end
--main init
local currentShells = {}
local dealerInventory = { [0] = 9,
    0,0,0,
    0,0,0,
    0,0,0
}
local playerInventory = { [0] = 9,
    0,0,0,
    0,0,0,
    0,0,0
}
local dealerEnergy = 2
local playerEnergy = 2
local PLAYERNICKNAME = "TEST"
function methods.fadeIn()
  colorFilter = 0x010101
  while true do
    colorFilter = colorFilter + 0x010101
    methods.tick(true)
    methods.busyLoop(0.0001)
    if colorFilter == 0xFFFFFF then
      break
    end
  end
end
--loading sound stuff
local musicFilesCashe = {}
local sounds
local soundsPath = assetsPath.."Sounds/"
if loadMusicFiles then
  sounds = {"Before Every Load","General Release","Socket Calibration","You are an Angel"}
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
    tape.write(string.rep("",tape.getSize()))
    tape.seek(-tape.getSize())
    if loadMusicFiles then
      tape.write(sounds[name])
    else
      tape.write(methods.read(soundsPath..name..'.dfpwm',true))
      os.sleep(0)
    end
    tape.seek(-tape.getSize())
    if fadeIn then
      tape.setVolume(0)
    end
    local i = 0
    local need = 0
    local speed = 0.5
    ID = getID()
    callEverytime[ID] = function()
      need = deltaTime + need
      if need >= speed then
        need = 0
        i = i + 0.1
        if i == 1 then
          callEverytime[ID] = nil
          return
        end
        tape.setVolume(i)
      end
    end
    tape.setLabel(name)
    tape.play()
  end
end
function methods.stopSounds()
  if cmp.isAvailable('tape_drive') then
    local i = 1
    while true do
      i = i - 0.1
      methods.busyLoop(0.2)
      cmp.tape_drive.setVolume(i)
      if i <= 0 then
        break
      end
    end
    cmp.tape_drive.stop()
  end
end
--UI makers, like when we show energy or our side of table
local function showEnergy()
  while true do
    colorFilter = colorFilter - 0x010101
    tick(true)
    busyLoop(0.001)
    if colorFilter <= 0x010101*2 then
      break
    end
  end
  UI = {} -- flush ui
  text(30,15,0x808080,'DEALER')
  text(30,16,0x50AA50,string.rep(symbols.energy,dealerEnergy))
  text(124,15,0x808080,PLAYERNICKNAME)
  text(124,16,0x50AA50,string.rep(symbols.energy,playerEnergy))
  fadeIn()
end
local function makeCurrentShells(roundNum)
    local shellsCount
    if roundNum == 2 then
        shellsCount = math.random(3,5)
    elseif roundNum == 1 then
        shellsCount = math.random(2,4)
    end
    for i = 1, shellsCount do
        local shell = math.random(0,1)
        table.insert(currentShells,shell)
        local color
        if shell == 1 then
            color = 0xBB1111
        else
            color = 0x1111BB
        end
        text(160/2+1-(i-math.ceil(shellsCount/2)),25,color,symbols.shell)
    end
    tick()
    os.sleep(3)
    UI = {}
    tick()
end
local function addToInventory(what, slot, id)
    slot = slot or 0
    if what[slot] > 0 then
        return false
    else
        what[slot] = id
        return true
    end
end
local function getItemName(itemID)
    if itemID == itemsID.beer then
        return '🥫BEER'
    elseif itemID == itemsID.glass then
        return "🔍MAGNIFIER"
    elseif itemID == itemsID.saw then
        return '🔪HANDSAW'
    elseif itemID == itemsID.vape then
        return "🚬CIGARETTE"
    elseif itemID == itemsID.handcuffs then
        return "🔗HANDCUFFS"
    else
        return "EMPTY"
    end
end
local function makeItems(roundNum)
    local function generateItem()
        return math.random(1,5)
    end
    local queue = {}
    for i = 1, roundNum*2-2 do
        addToInventory(dealerInventory,math.random(1,8),generateItem())
        table.insert(queue,generateItem())
    end
    UI = {}
    local panelIndex = panel(60,30,60,18,0xFFFFFF)
    local panel2Index = panel(62,31,56,16,0xAAAAAA)
    local itemPresentIndex = text(78,39,0xDDDDDD,"")
    local buttonIndexes = {}
    local function foundByIndex(index)
        for i = 1,#buttonIndexes do
            if buttonIndexes[i][1] == index then
                return i
            end
        end
    end
    local function updateCurrentItem()
        if not queue[1] then
            UI = {}
            os.sleep(1)
            tick(true)
            makeCurrentShells(roundNum)
        else
            table.remove(queue,1)
            UI[itemPresentIndex].text = getItemName(queue[1])
        end
    end
    local function anyButtonClick(index,x,y,mb)
        gpu.setBackground(0x0)
        gpu.setForeground(0xFFFFFF)
        if mb == 0 then
            if addToInventory(playerInventory, foundByIndex(index), queue[1]) then
                UI[buttonIndexes[foundByIndex(index)][3]].text = getItemName(queue[1])
                updateCurrentItem()
            end
        end
    end
    buttonIndexes[1] = button(8,30,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[1]),anyButtonClick)
    buttonIndexes[2] = button(20,30,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[2]),anyButtonClick)
    buttonIndexes[3] = button(8,46,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[3]),anyButtonClick)
    buttonIndexes[4] = button(20,46,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[4]),anyButtonClick)
    buttonIndexes[5] = button(100,30,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[5]),anyButtonClick)
    buttonIndexes[6] = button(110,30,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[6]),anyButtonClick)
    buttonIndexes[7] = button(100,46,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[7]),anyButtonClick)
    buttonIndexes[8] = button(110,46,10,5,0xDDDDDD,0xAAAAAA,getItemName(playerInventory[8]),anyButtonClick)
    updateCurrentItem()
    tick(true)
end
local function initRound(roundNum)
  UI = {}
  local roundNums = text(77,25,0xFFFFFF,symbols.rimNumOne.." "..symbols.rimNumTwo..' '..symbols.skull)
  local function makeLine(last)
    local line = ""
    local function getState(num)
      if roundNum == num then
        if last then
          return symbols.emptyDot
        else
          return symbols.fullDot
        end
       elseif roundNum > num then
         return symbols.fullDot
        else
          return symbols.emptyDot
      end
    end
    for i = 1, 3 do
      line = line .. getState(i) .. ' '
    end
    return line
  end
  completedRounds = text(77,26,0xFFFFFF,makeLine())
  tick(true)
  local turn = false
  for i = 1, 6 do
    turn = not turn
    UI[completedRounds].text = makeLine(turn)
    os.sleep(0.3)
    tick()
  end
  os.sleep(1)
  UI = {}
  makeItems(roundNum)
end--[[
local len = math.ceil(uni.len(loc.yourName))
local currentTextIndex = text(160/2-len,25,0xFFFFFF,loc.yourName)
local playerNameTextIndex = text(160/2-len,26,0xFFFFFF,'')
local inputHandle = inputHandler()
local indexOfHandleToText
indexOfHandleToText = getID()
callEverytime[indexOfHandleToText] = function() UI[playerNameTextIndex].text = inputHandle.text end
inputHandle.onInputFinished = function()
  callEverytime[indexOfHandleToText] = nil
  UI[currentTextIndex] = nil
  UI[playerNameTextIndex] = nil
  PLAYERNICKNAME = inputHandle.text
  inputHandle = nil
  os.sleep(1)
  initRound(2)
end
tick()]]
-- Big thanks to fingercomp bc i dont know how is this shi works
local globalEnv = setmetatable({}, {__index = _ENV})
local function runScript(code, privateVars)
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

  assert(load(code, "@UNKNOWNENGINESCRIPT.lua", "t", setmetatable({}, envMeta)))()

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
    table.insert(callEverytime, function(selfIndex)
        if timeWas + time < os.clock() then
            code()
            table.remove(callEverytime,selfIndex)
        end
    end)
end
--Compiling scripts
for i = 1, #scriptsFolderList do
    local nowMethods = methods.deepcopy(methods)
    nowMethods.loc = loc
    nowMethods.UI = UI
    scripts[string.gsub(scriptsFolderList[i],'.lua','')] = runScript(methods.read(scriptsPath..'/'..scriptsFolderList[i]),nowMethods)
end
--Executeing all Scripts
for i, v in pairs(scripts) do
    if v["Start"] then
        v["Start"]()
    end
end
--main loop
while true do
  local name,_,e1,e2,e3 = event.pull(0)
  lastEvent = {name,"",e1,e2,e3}
  if name == 'key_up' then
    if e2 == 14 and not ignoreBackspace then
      require('term').clear()
      gpu.setActiveBuffer(0)
      methods.stopSounds()
      return false
    end
  end
  if name == 'touch' then
    click(e1,e2,e3)
  end
  methods.tick()
end