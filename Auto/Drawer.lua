if _G.Drawer then return end
class "__Drawer"

local LocalGameHeroCount 			= Game.HeroCount
local LocalGameHero 				= Game.Hero
local myHero                              = myHero
local Menu                                = {
                                                drawer = nil
                                          }

function __Drawer:__init()
      print("Loaded Auto3.0: Drawer")
      self.spellDraw = {
            q = true, qr = myHero:GetSpellData(_Q).range,
            w = true, wr = myHero:GetSpellData(_W).range,
            e = true, er = myHero:GetSpellData(_E).range,
            r = true, rr = myHero:GetSpellData(_R).range
      }
      if myHero.charName == "Aatrox" then
            self.spellDraw = { q = true, qr = 650, e = true, er = 1000, r = true, rr = 550 }
      elseif myHero.charName == "Ahri" then
            self.spellDraw = { q = true, qr = 880, w = true, wr = 700, e = true, er = 975, r = true, rr = 450 }
      elseif myHero.charName == "Akali" then
            self.spellDraw = { q = true, qr = 600 + 120, w = true, wr = 475, e = true, er = 300, r = true, rr = 700 + 120 }
      elseif myHero.charName == "Alistar" then
            self.spellDraw = { q = true, qr = 365, w = true, wr = 650 + 120, e = true, er = 350 }
      elseif myHero.charName == "Amumu" then
            self.spellDraw = { q = true, qr = 1100, w = true, wr = 300, e = true, er = 350, r = true, rr = 550 }
      elseif myHero.charName == "Anivia" then
            self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 650 + 120, r = true, rr = 750 }
      elseif myHero.charName == "Annie" then
            self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 625, r = true, rr = 600 }
      elseif myHero.charName == "Ashe" then
            self.spellDraw = { w = true, wr = 1200 }
      elseif myHero.charName == "AurelionSol" then
            self.spellDraw = { q = true, qr = 1075, w = true, wr = 600, e = true, ef = function() local eLvl = myHero:GetSpellData(_E).level; if eLvl == 0 then return 3000 else return 2000 + 1000 * eLvl end end, r = true, rr = 1500 }
      elseif myHero.charName == "Azir" then
            self.spellDraw = { q = true, qr = 740, w = true, wr = 500, e = true, er = 1100, r = true, rr = 250 }
      elseif myHero.charName == "Bard" then
            self.spellDraw = { q = true, qr = 950, w = true, wr = 800, e = true, er = 900, r = true, rr = 3400 }
      elseif myHero.charName == "Blitzcrank" then
            self.spellDraw = { q = true, qr = 925, e = true, er = 300, r = true, rr = 600 }
      elseif myHero.charName == "Brand" then
            self.spellDraw = { q = true, qr = 1050, w = true, wr = 900, e = true, er = 625, r = true, rr = 750 }
      elseif myHero.charName == "Braum" then
            self.spellDraw = { q = true, qr = 1000, w = true, wr = 650 + 120, r = true, rr = 1250 }
      elseif myHero.charName == "Caitlyn" then
            self.spellDraw = { q = true, qr = 1250, w = true, wr = 800, e = true, er = 750, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 2000 else return 1500 + 500 * rLvl end end }
      elseif myHero.charName == "Camille" then
            self.spellDraw = { q = true, qr = 325, w = true, wr = 610, e = true, er = 800, r = true, rr = 475 }
      elseif myHero.charName == "Cassiopeia" then
            self.spellDraw = { q = true, qr = 850, w = true, wr = 800, e = true, er = 700, r = true, rr = 825 }
      elseif myHero.charName == "Chogath" then
            self.spellDraw = { q = true, qr = 950, w = true, wr = 650, e = true, er = 500, r = true, rr = 175 + 120 }
      elseif myHero.charName == "Corki" then
            self.spellDraw = { q = true, qr = 825, w = true, wr = 600, r = true, rr = 1225 }
      elseif myHero.charName == "Darius" then
            self.spellDraw = { q = true, qr = 425, w = true, wr = 300, e = true, er = 535, r = true, rr = 460 + 120 }
      elseif myHero.charName == "Diana" then
            self.spellDraw = { q = true, qr = 900, w = true, wr = 200, e = true, er = 450, r = true, rr = 825 }
      elseif myHero.charName == "DrMundo" then
            self.spellDraw = { q = true, qr = 975, w = true, wr = 325 }
      elseif myHero.charName == "Draven" then
            self.spellDraw = { e = true, er = 1050 }
      elseif myHero.charName == "Ekko" then
            self.spellDraw = { q = true, qr = 1075, w = true, wr = 1600, e = true, er = 325 }
      elseif myHero.charName == "Elise" then
            -- self.spellDraw = { need check form buff qHuman = 625, qSpider = 475, wHuman = 950, wSpider = math.huge(none), eHuman = 1075, eSpider = 750 }
      elseif myHero.charName == "Evelynn" then
            self.spellDraw = { q = true, qr = 800, w = true, wf = function() local wLvl = myHero:GetSpellData(_W).level; if wLvl == 0 then return 1200 else return 1100 + 100 * wLvl end end, e = true, er = 210, r = true, rr = 450 }
      elseif myHero.charName == "Ezreal" then
            self.spellDraw = { q = true, qr = 1150, w = true, wr = 1000, e = true, er = 475 }
      elseif myHero.charName == "Fiddlesticks" then
            self.spellDraw = { q = true, qr = 575 + 120, w = true, wr = 650, e = true, er = 750 + 120, r = true, rr = 800 }
      elseif myHero.charName == "Fiora" then
            self.spellDraw = { q = true, qr = 400, w = true, wr = 750, r = true, rr = 500 + 120 }
      elseif myHero.charName == "Fizz" then
            self.spellDraw = { q = true, qr = 550 + 120, e = true, er = 400, r = true, rr = 1300 }
      elseif myHero.charName == "Galio" then
            self.spellDraw = { q = true, qr = 825, w = true, wr = 350, e = true, er = 650, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 4000 else return 3250 + 750 * rLvl end end }
      elseif myHero.charName == "Gangplank" then
            self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 650, e = true, er = 1000 }
      elseif myHero.charName == "Garen" then
            self.spellDraw = { e = true, er = 325, r = true, rr = 400 + 120 }
      elseif myHero.charName == "Gnar" then
            self.spellDraw = { q = true, qr = 1100, r = true, rr = 475, w = false, e = false } -- wr (mega gnar) = 550, er (mini gnar) = 475, er (mega gnar) = 600
      elseif myHero.charName == "Gragas" then
            self.spellDraw = { q = true, qr = 850, e = true, er = 600, r = true, rr = 1000 }
      elseif myHero.charName == "Graves" then
            self.spellDraw = { q = true, qr = 925, w = true, wr = 950, e = true, er = 475, r = true, rr = 1000 }
      elseif myHero.charName == "Hecarim" then
            self.spellDraw = { q = true, qr = 350, w = true, wr = 575 + 120, r = true, rr = 1000 }
      elseif myHero.charName == "Heimerdinger" then
            self.spellDraw = { q = false, w = true, wr = 1325, e = true, er = 970 } --  qr (noR) = 350, wr (R) = 450
      elseif myHero.charName == "Illaoi" then
            self.spellDraw = { q = true, qr = 850, w = true, wr = 350 + 120, e = true, er = 900, r = true, rr = 450 }
      elseif myHero.charName == "Irelia" then
            self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 825, e = true, er = 900, r = true, rr = 1000 }
      elseif myHero.charName == "Ivern" then
            self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 750 + 120 }
      elseif myHero.charName == "Janna" then
            self.spellDraw = { q = true, qf = function() local qt = GameTimer() - self.LastQk;if qt > 3 then return 1000 end local qrange = qt * 250;if qrange > 1750 then return 1750 end return qrange end, w = true, wr = 550 + 120, e = true, er = 800 + 120, r = true, rr = 725 }
      elseif myHero.charName == "JarvanIV" then
            self.spellDraw = { q = true, qr = 770, w = true, wr = 625, e = true, er = 860, r = true, rr = 650 + 120 }
      elseif myHero.charName == "Jax" then
            self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300 }
      elseif myHero.charName == "Jayce" then
            --self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300, r = true }  (Mercury Hammer: q=600+120, w=285, e=240+120; Mercury Cannon: q=1050/1470, w=active, e=650
      elseif myHero.charName == "Jhin" then
            self.spellDraw = { q = true, qr = 550 + 120, w = true, wr = 3000, e = true, er = 750, r = true, rr = 3500 }
      elseif myHero.charName == "Jinx" then
            self.spellDraw = { q = true, qf = function() if self:HasBuff(myHero, "jinxq") then return 525 + myHero.boundingRadius + 35 else local qExtra = 25 * myHero:GetSpellData(_Q).level; return 575 + qExtra + myHero.boundingRadius + 35 end end, w = true, wr = 1450, e = true, er = 900 }
      elseif myHero.charName == "KogMaw" then
            self.spellDraw = { q = true, qr = 1175, e = true, er = 1280, r = true, rf = function() local rlvl = myHero:GetSpellData(_R).level; if rlvl == 0 then return 1200 else return 900 + 300 * rlvl end end }
      elseif myHero.charName == "Lucian" then
            self.spellDraw = { q = true, qr = 500+120, w = true, wr = 900+350, e = true, er = 425, r = true, rr = 1200 }
            elseif myHero.charName == "Morgana" then
            self.spellDraw = { q = true, qr = 1175, w = true, wr = 900, e = true, er = 800, r = true, rr = 625 }
      elseif myHero.charName == "Nami" then
            self.spellDraw = { q = true, qr = 875, w = true, wr = 725, e = true, er = 800, r = true, rr = 2750 }
      elseif myHero.charName == "Sivir" then
            self.spellDraw = { q = true, qr = 1250, r = true, rr = 1000 }
      elseif myHero.charName == "Teemo" then
            self.spellDraw = { q = true, qr = 680, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then rLvl = 1 end return 150 + ( 250 * rLvl ) end }
      elseif myHero.charName == "Twitch" then
            self.spellDraw = { w = true, wr = 950, e = true, er = 1200, r = true, rf = function() return myHero.range + 300 + ( myHero.boundingRadius * 2 ) end }
      elseif myHero.charName == "Tristana" then
            self.spellDraw = { w = true, wr = 900 }
      elseif myHero.charName == "Varus" then
            self.spellDraw = { q = true, qr = 1650, e = true, er = 950, r = true, rr = 1075 }
      elseif myHero.charName == "Vayne" then
            self.spellDraw = { q = true, qr = 300, e = true, er = 550 }
      elseif myHero.charName == "Viktor" then
            self.spellDraw = { q = true, qr = 600 + 2 * myHero.boundingRadius, w = true, wr = 700, e = true, er = 550 }
      elseif myHero.charName == "Xayah" then
            self.spellDraw = { q = true, qr = 1100 }
      end
      Menu.drawer = MenuElement({name = "[Drawer]", id = "drawer", type = MENU })
      self:Menu()
      Callback.Add('Draw', function()
            self:Draw()
      end)
end

function __Drawer:Menu()
      Menu.drawer:MenuElement({name = "Enabled",  id = "enabled", value = true})
      self:MenuCursor()
      self:MenuSpell()
end

function __Drawer:MenuCursor()
      Menu.drawer:MenuElement({name = "Cursor", id = "cursor", type = MENU})
      Menu.drawer.cursor:MenuElement({id = "enabled", name = "Enabled", value = true})
      Menu.drawer.cursor:MenuElement({id = "color", name = "Color", color = Draw.Color(255, 66, 134, 244)})
      Menu.drawer.cursor:MenuElement({id = "width", name = "Width", value = 1, min = 1, max = 10})
      Menu.drawer.cursor:MenuElement({id = "radius", name = "Radius", value = 50, min = 1, max = 300})
end

function __Drawer:MenuSpell()
      Menu.drawer:MenuElement({name = "Spell Ranges", id = "circle", type = MENU,
            onclick = function()
                  if self.spellDraw.q then
                        Menu.drawer.circle.qrange:Hide(true)
                        Menu.drawer.circle.qrangecolor:Hide(true)
                        Menu.drawer.circle.qrangewidth:Hide(true)
                  end
                  if self.spellDraw.w then
                        Menu.drawer.circle.wrange:Hide(true)
                        Menu.drawer.circle.wrangecolor:Hide(true)
                        Menu.drawer.circle.wrangewidth:Hide(true)
                  end
                  if self.spellDraw.e then
                        Menu.drawer.circle.erange:Hide(true)
                        Menu.drawer.circle.erangecolor:Hide(true)
                        Menu.drawer.circle.erangewidth:Hide(true)
                  end
                  if self.spellDraw.r then
                        Menu.drawer.circle.rrange:Hide(true)
                        Menu.drawer.circle.rrangecolor:Hide(true)
                        Menu.drawer.circle.rrangewidth:Hide(true)
                  end
            end
      })
      if self.spellDraw.q then
            Menu.drawer.circle:MenuElement({name = "[Q] Range", id = "note5", type = SPACE,
                  onclick = function()
                        Menu.drawer.circle.qrange:Hide()
                        Menu.drawer.circle.qrangecolor:Hide()
                        Menu.drawer.circle.qrangewidth:Hide()
                  end
            })
            Menu.drawer.circle:MenuElement({id = "qrange", name = "        Enabled", value = true})
            Menu.drawer.circle:MenuElement({id = "qrangecolor", name = "        Color", color = Draw.Color(255, 66, 134, 244)})
            Menu.drawer.circle:MenuElement({id = "qrangewidth", name = "        Width", value = 1, min = 1, max = 10})
      end
      if self.spellDraw.w then
            Menu.drawer.circle:MenuElement({name = "[W] Range", id = "note6", type = SPACE,
                  onclick = function()
                        Menu.drawer.circle.wrange:Hide()
                        Menu.drawer.circle.wrangecolor:Hide()
                        Menu.drawer.circle.wrangewidth:Hide()
                  end
            })
            Menu.drawer.circle:MenuElement({id = "wrange", name = "        Enabled", value = true})
            Menu.drawer.circle:MenuElement({id = "wrangecolor", name = "        Color", color = Draw.Color(255, 92, 66, 244)})
            Menu.drawer.circle:MenuElement({id = "wrangewidth", name = "        Width", value = 1, min = 1, max = 10})
      end
      if self.spellDraw.e then
            Menu.drawer.circle:MenuElement({name = "[E] Range", id = "note7", type = SPACE,
                  onclick = function()
                        Menu.drawer.circle.erange:Hide()
                        Menu.drawer.circle.erangecolor:Hide()
                        Menu.drawer.circle.erangewidth:Hide()
                  end
            })
            Menu.drawer.circle:MenuElement({id = "erange", name = "        Enabled", value = true})
            Menu.drawer.circle:MenuElement({id = "erangecolor", name = "        Color", color = Draw.Color(255, 66, 244, 149)})
            Menu.drawer.circle:MenuElement({id = "erangewidth", name = "        Width", value = 1, min = 1, max = 10})
      end
      if self.spellDraw.r then
            Menu.drawer.circle:MenuElement({name = "[R] Range", id = "note8", type = SPACE,
                  onclick = function()
                        Menu.drawer.circle.rrange:Hide()
                        Menu.drawer.circle.rrangecolor:Hide()
                        Menu.drawer.circle.rrangewidth:Hide()
                  end
            })
            Menu.drawer.circle:MenuElement({id = "rrange", name = "        Enabled", value = true})
            Menu.drawer.circle:MenuElement({id = "rrangecolor", name = "        Color", color = Draw.Color(255, 244, 182, 66)})
            Menu.drawer.circle:MenuElement({id = "rrangewidth", name = "        Width", value = 1, min = 1, max = 10})
      end
end

function __Drawer:Draw()
      -- Enable
      if not Menu.drawer.enabled:Value() then
            return
      end
      -- Cursor
      if Menu.drawer.cursor.enabled:Value() then
            Draw.Circle(mousePos, Menu.drawer.cursor.radius:Value(), Menu.drawer.cursor.width:Value(), Menu.drawer.cursor.color:Value())
      end
      -- Spell
      local drawMenu = Menu.drawer.circle
      if self.spellDraw.q and drawMenu.qrange:Value() then
            local qrange = self.spellDraw.qf and self.spellDraw.qf() or self.spellDraw.qr
            Draw.Circle(myHero.pos, qrange, drawMenu.qrangewidth:Value(), drawMenu.qrangecolor:Value())
      end
      if self.spellDraw.w and drawMenu.wrange:Value() then
            local wrange = self.spellDraw.wf and self.spellDraw.wf() or self.spellDraw.wr
            Draw.Circle(myHero.pos, wrange, drawMenu.wrangewidth:Value(), drawMenu.wrangecolor:Value())
      end
      if self.spellDraw.e and drawMenu.erange:Value() then
            local erange = self.spellDraw.ef and self.spellDraw.ef() or self.spellDraw.er
            Draw.Circle(myHero.pos, erange, drawMenu.erangewidth:Value(), drawMenu.erangecolor:Value())
      end
      if self.spellDraw.r and drawMenu.rrange:Value() then
            local rrange = self.spellDraw.rf and self.spellDraw.rf() or self.spellDraw.rr
            Draw.Circle(myHero.pos, rrange, drawMenu.rrangewidth:Value(), drawMenu.rrangecolor:Value())
      end
end

Drawer = __Drawer()
_G.Drawer = Drawer
