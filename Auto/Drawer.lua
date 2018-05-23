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
