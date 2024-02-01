local roundNum = 1
local currentShells = {}
local itemsID = {
    "beer",
    "glass",
    "handcuffs",
    "vape",
    "saw"
}
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
PLAYERNICKNAME = "TEST"
function ShowRound()

end
function ShowEnergy()
  fadeOut(2)
  invoke(function()
    flushUI()
    text(30,15,0x808080,loc.dealer)
    text(30,16,0x50AA50,string.rep(symbols.energy,dealerEnergy))
    text(124,15,0x808080,PLAYERNICKNAME)
    text(124,16,0x50AA50,string.rep(symbols.energy,playerEnergy))
    fadeIn()
  end, 2.2)
end
function StartRound()

end