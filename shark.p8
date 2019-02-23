pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--shark wars
--by a2

--cartdata("a2_sharkwars")

function _init()
  add_mode("menu",menu_init,menu_update,menu_draw)
  add_mode("intro",intro_init,intro_update,intro_draw)
  add_mode("game",game_init,game_update,game_draw)
  set_mode("menu")
end

function _update()
  mode:update()
end

function _draw()
  mode:draw()
end

--valid layer indices (update here to allow new z-values)
game_layers={-1,0,1}
-->8
--modes
function add_mode(name,init,update,draw,skip_default)
  local function wrap(default,custom)
    return function(mode)
      if (not skip_default) default(mode)
      custom(mode)
    end
  end

  local new_mode={
    name=name,
    init=wrap(default_init,init),
    update=wrap(default_update,update),
    draw=wrap(default_draw,draw)
  }

  if (all_modes==nil) all_modes={}
  all_modes[name]=new_mode
  return new_mode
end

function set_mode(name)
  mode=all_modes[name]
  assert(mode!=nil,"undefined mode "..name)
  mode:init()
  return mode
end

function default_init(mode)
  --game objects
  local layer
  mode.game_objects={}
  for layer in all(game_layers) do
    mode.game_objects[layer]={}
  end
end

function default_update(mode)
  --update all game objects
  foreach_game_object(function(obj)
    obj:update()
  end)

  --filter out "dead" objects
  filter_out_finished()
end

function default_draw(mode)
  cls(0)--clear the screen

  --draw visible game objects
  foreach_game_object(function(obj)
    if (obj.visible) obj:draw()
  end)
end
-->8
--menu loop
function menu_init(mode)
  music(0)

  mode.index=1
  mode.choice=nil
  mode.options={
    "play",
    "credits",
    "highscores",
  }

  mode.shark=make_menu_shark(36,73)
  make_starfield()
end

function menu_update(mode)
  if (btnp(4)) mode.choice=mode.index

  if mode.choice!=nil then
    mode.shark.x+=4

    if mode.shark.x>140 then
      if mode.choice==1 then
        set_mode("intro")
      else
        set_mode("menu")
      end
    end

    return
  end

  local offset=0
  if btnp(2) then
    offset=-1
  elseif btnp(3) then
    offset=1
  end

  local c=#mode.options
  mode.index=max(1,min(c,mode.index+offset))
  mode.shark.x=hcenter(mode.options[mode.index])-20
  mode.shark.y=63+10*mode.index
end

function menu_draw(mode)
  local function do_draw(y,i,j)
    --shark
    sspr(41,0,16,13,30+i,y+j)--s
    sspr(57,0,12,13,45+i,y+j)--h
    sspr(100,0,28,13,57+i,y+j)--ar
    sspr(65,0,15,13,85+i,y+j)--k

    --wars
    sspr(80,0,20,13,36+i,y+17+j)--w
    sspr(100,0,28,13,54+i,y+17+j)--ar
    sspr(41,0,16,13,77+i,y+17+j)--s
  end

  local i,j
  local y=23

  pal(10,0)
  for i=-1,1 do
    for j=-1,1 do
      do_draw(y,i,j)
    end
  end
  pal()

  do_draw(y,0,0)
  y+=34

  local subtitle="by @a2"
  outline(subtitle,hcenter(subtitle),y,10,0)
  y+=8

  y+=10
  local i
  for i=1,#mode.options do
    local opt=mode.options[i]
    if mode.choice!=i then
      outline(opt,hcenter(opt),y,10,0)
    end
    y+=10
  end
end
-->8
--intro loop
function intro_init(mode)
  music(-1)

  mode.colors={
    {5,5},--inactive
    {10,7},--active
  }
  mode.index=1
  mode.messages={
    {
      {1,"[nasa says]"},
      {2,"we have received a message"},
      {2,"from the aliens on enceladus"},
      {2,"the moon of saturn."},
      {1,""},
      {1,"⬆️⬇️ navigate - ❎ skip intro"},
    },
    {
      {1,"[the message reads]"},
      {2,"there is a threat!"},
      {2,"it comes from a faraway galaxy!"},
      {2,"please save us!!"},
    },
    {
      {1,"[meanwhile]"},
      {2,"to protect the solar system"},
      {2,"and earth, nasa decides to help"},
      {2,"the aliens fight by sending"},
      {2,"very advanced weapons."},
    },
    {
      {2,"but alas, nasa accidentally sent"},
      {2,"their top-secret experiment:"},
      {2,"shark x... duh duh duhhhh"},
    },
    {
      {1,"[nasa says]"},
      {2,"oh no! shark x should never have"},
      {2,"left the laboratory."},
    },
    {
      {2,"no one knows how it will perform"},
      {2,"but it is too late to abort"},
      {2,"the mission."},
    },
    {
      {2,"the threat is already at"},
      {2,"our gates!"},
    },
    {
      {2,"your mission, should you choose"},
      {2,"to accept it:"},
    },
    {
      {2,"remote control the shark and"},
      {2,"make sure the threat does not"},
      {2,"get past saturn."},
    },
    {
      {2,"the future of humanity,"},
      {2,"and all alien-kind,"},
      {2,"rests between your fins."},
    },
    {
      {2,"good luck, shark x."},
    },
    {
      {1,"press 🅾️ to start"},
    },
  }
end

function intro_update(mode)
  if btnp(4) and mode.index==#mode.messages then
    set_mode("game")
  elseif btnp(5) then
    mode.index=#mode.messages
  elseif btnp(2) and mode.index>1 then
    mode.index-=1
  elseif btnp(3) and mode.index<#mode.messages then
    mode.index+=1
  end
end

function intro_draw(mode)
  --each text line is 6px
  local line_height=6

  --draw message backwards, starting at y
  local function draw_back(message,y,palette)
    local i
    for i=#message,1,-1 do
      print(message[i][2],0,y,mode.colors[palette][message[i][1]])
      y-=line_height
      if (y<0) break
    end
    return y-line_height
  end

  local index=mode.index

  --count lines until index
  local i
  local lines=0
  for i=1,index-1 do
    lines+=#mode.messages[i]+1--extra for inter-message spacing
  end

  --find correct starting y
  local y=line_height*min(20,lines-1+#mode.messages[index])

  --start at message[index] and go backwards
  y=draw_back(mode.messages[index],y,2)
  for i=index-1,1,-1 do
    y=draw_back(mode.messages[i],y,1)
    if (y<0) break
  end
end
-->8
--game loop
function game_init(mode)
  music(-1)

  --gameplay view constraints
  mode.min_y=9
  mode.max_y=127

  --start score counter at zero
  mode.score=0

  --store current time
  mode.tick=0
  mode.sec=0

  --create initial objects
  make_starfield()
  make_enemy_generator()
  mode.shark=make_shark(0,60)
end

function game_update(mode)
  mode.tick+=1
  if mode.tick>30 then
    mode.tick-=30
    mode.sec+=1
  end

  local shark=mode.shark
  foreach_game_object_named("enemy",function(enemy)
    if shark:overlaps(enemy) then
      if shark.powerup=="fish" then
        sfx(4)
        mode.score+=10
      else
        sfx(3)
        shark.damage_timer+=10
        shark.health-=1
      end

      enemy.finished=true
    end

    if enemy.x+enemy.width<0 then
      sfx(3)
      shark.damage_timer+=10
      mode.score-=10
      enemy.finished=true
    end
  end)

  if shark.health<0 or mode.score<0 then
    sfx(2)
    set_mode("game")
  end
end

function game_draw(mode)
  local shark=mode.shark

  --top bar, dark blue
  rectfill(0,0,128,6,1)

  --shark lives
  spr(41,0,-1)
  print(shark.health,9,1,7)

  --score
  local score=mode.score.."PT"
  print(score,127-4*#score,1,7)

  --powerup
  if shark.powerup_timer>0 then
    local p=shark.powerup
    if p=="clock" then
      spr(17,15,1)
    elseif p=="fish" then
      spr(18,15,1)
    elseif p=="jetpack" then
      spr(19,15,1)
    end

    line(0,7,128*(shark.powerup_timer/shark.powerup_duration),7,14)
  end
end
-->8
--makers
function noop()
end

function make_game_object(name,x,y,z,props)
  local obj={
    name=name,
    x=x,
    y=y,
    visible=true,
    update=noop,
    draw=noop,
    draw_bounding_box=function(self,color)
      rect(self.x,self.y,self.x+self.width,self.y+self.height,color)
    end,
    center=function(self)
      return self.x+self.width/2,self.y+self.height/2
    end,
    overlaps=function(self,other)
      return bounding_boxes_overlapping(self,other)
    end
  }
  --add additional properties
  local key,value
  for key,value in pairs(props) do
    obj[key]=value
  end
  --add it to layer `z` in game objects
  assert(mode.game_objects[z]!=nil,"update game_layers to use z="..z)
  add(mode.game_objects[z],obj)
  --return the game object
  return obj
end

function make_menu_shark(x,y)
  return make_game_object("small_shark",x,y,0,{
    width=16,
    height=8,
    frame=0,
    update=function(self)
      self.frame=(self.frame+0.5)%8
    end,
    draw=function(self)
      spr(32+2*flr(self.frame),self.x,self.y,2,1)
    end,
  })
end

function make_shark(x,y)
  return make_game_object("shark",x,y,0,{
    width=16,
    height=8,
    health=3,
    frame=0,
    chomping=0,
    damage_timer=0,
    powerup_timer=0,
    mouth_position=function(self)
      if self.powerup=="fish" then
        return self.x+30,self.y+9
      else
        return self.x+14,self.y+5
      end
    end,
    update=function(self)
      if self.powerup=="fish" then
        self.width=32
        self.height=16
      else
        self.width=16
        self.height=8

        --shoot on 🅾️
        if btn(4) then
          if self.last_laser==nil then
            sfx(1)

            local mx,my=self:mouth_position()
            self.last_laser=make_laser(mx,my)
          end
        else
          self.last_laser=nil
        end
      end

      local speed=ternary(self.powerup=="jetpack",2,1)
      if (btn(2) and self.y>mode.min_y) self.y-=speed
      if (btn(3) and self.y+self.height<mode.max_y) self.y+=speed

      self.frame=(self.frame+0.5)%8

      if self.damage_timer>0 then
        self.damage_timer-=0.25
        self.visible=flr(self.damage_timer)%2==0
      end

      if self.powerup_timer>0 then
        self.powerup_timer-=1
      else
        self.powerup=nil
      end
    end,
    draw=function(self)
      if self.powerup=="fish" then
        local s=48+4*flr(self.frame)
        if (s>=64) s+=16
        spr(s,self.x,self.y,4,2)
      else
        spr(32+2*flr(self.frame),self.x,self.y,2,1)
      end
    end,
  })
end

function make_laser(x,y)
  return make_game_object("laser",x,y,1,{
    width=3,
    height=1,
    update=function(self)
      self.x+=1
      if (self.x>128) self.finished=true
    end,
    draw=function(self)
      pset(self.x,self.y,4)
      pset(self.x+1,self.y,9)
      pset(self.x+2,self.y,10)
    end
  })
end

function make_starfield()
  local colors={1,2,5,6,7}
  local warp_factor=3

  local i,j
  local stars={}
  for i=1,#colors do
    for j=1,10 do
      add(stars,{
        x=rnd(128),
        y=rnd(128),
        z=i,
        c=colors[i]
      })
    end
  end

  return make_game_object("starfield",0,0,-1,{
    width=128,
    height=128,
    stars=stars,
    update=function(self)
      local s
      for s in all(self.stars) do
        s.x-=s.z*warp_factor/10
        if s.x<0 then
          s.x=128
          s.y=rnd(128)
        end
      end
    end,
    draw=function(self)
      local s
      for s in all(self.stars) do
        pset(s.x,s.y,s.c)
      end
    end
  })
end

function make_enemy(x,y)
  make_game_object("enemy",x,y,0,{
    width=8,
    height=8,
    damage=0,
    max_damage=5,
    fire={},
    update=function(self)
      --add "flame"
      add(self.fire,{x=self.x+7,y=self.y+4})
      local i
      for i=1,#self.fire do
        --spray
        local fire=self.fire[i]
        fire.x+=rnd(2)-1
        fire.y+=rnd(2)-1
      end
      --prune
      if #self.fire>10 then
        del(self.fire,self.fire[1])
      end

      --move to the left
      local speed=ternary(mode.shark.powerup=="clock",0.1,0.5)
      self.x-=speed

      foreach_game_object_named("laser",function(obj)
        if self:overlaps(obj) then
          self.damage+=1
          obj.finished=true
        end
      end)

      if self.damage>=self.max_damage then
        self.finished=true
        mode.score+=1

        if mode.shark.powerup==nil and rndb(1,6)==1 then
          make_powerup_random(self.x,self.y)
        end
      end
    end,
    draw=function(self)
      local colors,i={10,9,8,2}
      for i=1,#self.fire do
        local fire=self.fire[i]
        local c=colors[flr(4*(1-i/#self.fire))+1]
        pset(fire.x,fire.y,c)
      end

      spr(0,self.x,self.y)
    end
  })
end

function make_enemy_generator()
  return make_game_object("enemy_generator",0,0,-1,{
    visible=false,
    last_spawn=0,
    update=function(self)
      local now=mode.sec
      local spawn_interval=4-min(3,now/60)
      local duration=now-self.last_spawn
      if duration>spawn_interval then
        make_enemy(128,rndb(mode.min_y,mode.max_y-11))
        self.last_spawn=now
      end
    end
  })
end

function make_powerup_random(x,y)
  local makers={
    make_powerup_jetpack,
    make_powerup_fish,
    make_powerup_clock,
  }
  return makers[rndb(1,#makers)](x,y)
end

function make_powerup(type,x,y,w,h,sprite,duration)
  return make_game_object("powerup",x,y,0,{
    width=w,
    height=h,
    type=type,
    duration=duration,
    update=function(self)
      self.x-=1

      if self.x+self.width<0 then
        self.finished=true
      elseif self:overlaps(mode.shark) then
        mode.shark.powerup=type
        mode.shark.powerup_timer=30*duration
        mode.shark.powerup_duration=30*duration

        foreach_game_object_named("powerup",function(obj)
          obj.finished=true
        end)
      end
    end,
    draw=function(self)
      spr(sprite,self.x,self.y)
    end
  })
end

function make_powerup_jetpack(x,y)
  return make_powerup("jetpack",x,y,8,8,3,5)
end

function make_powerup_fish(x,y)
  return make_powerup("fish",x,y,7,7,2,5)
end

function make_powerup_clock(x,y)
  return make_powerup("clock",x,y,8,8,1,5)
end
-->8
--helpers
--hit detection helper functions
function rects_overlapping(left1,top1,right1,bottom1,left2,top2,right2,bottom2)
  return right1>left2 and right2>left1 and bottom1>top2 and bottom2>top1
end

function bounding_boxes_overlapping(obj1,obj2)
  return rects_overlapping(obj1.x,obj1.y,obj1.x+obj1.width,obj1.y+obj1.height,obj2.x,obj2.y,obj2.x+obj2.width,obj2.y+obj2.height)
end

function foreach_game_object(callback)
  local layer,obj
  for layer in all(game_layers) do
    local list=mode.game_objects[layer]
    for obj in all(list) do
      callback(obj,layer,list)
    end
  end
end

function foreach_game_object_named(name,callback)
  foreach_game_object(function(obj,layer,list)
    if (obj.name==name) callback(obj,layer,list)
  end)
end

function rndb(low,high)
  return flr(rnd(high-low+1)+low)
end

function ternary(condition,if_true,if_false)
  return condition and if_true or if_false
end

function filter_out_finished()
  foreach_game_object(function(obj,layer,list)
    if (obj.finished) del(list,obj)
  end)
end

function hcenter(str)
  return 64-#str*2
end

function outline(txt,x,y,col1,col2)
  local i,j
  for i=-1,1 do
    for j=-1,1 do
      print(txt,x+j,y+i,col2)
    end
  end

  print(txt,x,y,col1)
end
__gfx__
00cccc0007d7700000009590000880000800bbb00000000aaaaaaaaaaaaaa0000aaaa000aaaa0000aaaaa0000aaa0000aaaa0000aaaaaaa0000aaaaaaaaaa000
0c7cccc077d777000007999000778000878ccbbc000000aaaaaaaaaaaaaaa0000aaaa00aaaaa0000aaaaaa00aaaaa00aaaaa0000aaaaaaa0000aaaaaaaaaaa00
0cccccc077d7d7000099799007770000777ccbcc000000aaaaaaaaaaaaaaa0000aaaa0aaaaa00000aaaaaa00aaaaa00aaaa00000aaaaaaaa000aaaaaaaaaaaa0
1cccccc177dd77000079970067700088777bccbb000000aaaaaaaaaaaaaaa0000aaaaaaaaa000000aaaaaaa0aaaaaa0aaaa0000aaaa0aaaa000aaaa0000aaaa0
611111167777770099979000060007787770ccb0000000aaaaa000000aaaa0000aaaaaaaa0000000000aaaaaaaaaaa0aaaa0000aaaa0aaaa000aaaa0000aaaa0
0666666007777000099000000000777057500000000000aaaaaa00000aaaaaaaaaaaaaaa00000000000aaaaaaaaaaaaaaa00000aaaa0aaaaa00aaaaaaaaaaaa0
00cccc00000000000090000000067700555000000000000aaaaaa0000aaaaaaaaaaaaaa000000000000aaaaaaaaaaaaaaa0000aaaa000aaaa00aaaaaaaaaaa00
000000000000000000000000000060000000000000000000aaaaaa000aaaaaaaaaaaaaaa000000000000aaaaaaaaaaaaaa0000aaaa000aaaa00aaaaaaaa00000
0000000007d70000000990000008800000000000000000000aaaaaa00aaaaaaaaaaaaaaaa00000000000aaaaaaaaaaaaaa0000aaaaaaaaaaaa0aaaaaaaaa0000
0099990077d770000099900000778000000000000aaaaaaaaaaaaaa00aaaa0000aaaaaaaaaaaaaaa0000aaaaaa0aaaaaa0000aaaaaaaaaaaaa0aaaa0aaaaaaaa
0999999077dd70000799000007770000000000000aaaaaaaaaaaaaa00aaaa0000aaaa0aaaaaaaaaa00000aaaaa00aaaaa0000aaaaaaaaaaaaa0aaaa00aaaaaaa
a999999a777770009970000067700000000000000aaaaaaaaaaaaa000aaaa0000aaaa00aaaaaaaaa00000aaaaa00aaaaa000aaaaa00000aaaaaaaaa000aaaaaa
aaaaaaaa077700000900000006000000000000000aaaaaaaaaaaa0000aaaa0000aaaa000aaaaaaaa00000aaaaa00aaaaa000aaaaa00000aaaaaaaaa0000aaaaa
09999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006000000000000000600000000000000060000000000000000600000000660000060000000060000006000000000000000600000000000000600000000
06000006600000000600000660000000060000066000000006000000660000000066000066000000066000006600000006000000660000000060000660000000
00606066666000000660606666600000066060666660000000606006666600000066060666660000006060066666000006606006666600000060606666600000
00666666666660000066666666666000006666666666600000666666666666000066666666666600006666666666660000666666666666000066666666666000
00607776666166000660777666616600006077766661660000607777666616600066077766661660006007776666166000607776666616600060777666616600
00000076677770000000007667777000060000066777700006600007667777000060000076677700006000006677770000600007667777000060000667777000
00000006000000000000000600000000000000060000000000000000600000000000000006000000000000006000000000000000600000000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000006600000000000000000000000000000066000000000000000000000000000000066000000000000000000000000000000066000000000000000
00000000000006660000000000000000000000000000066600000000000000000000000000000066600000000000000006600000000000066600000000006600
00060000000006666000000000000000006600000000066660000000000000000660000000000066660000000000000006660000000000066660000000066600
00066000000006666600000000000000006660060000066666000000000000000666000600000066666000000000666000666000600000066666000000666f00
0006600600006666666666660000000000666006000066666666666600000000066660066000066666666666666666f00006600066000066666666666616f700
000066066666666666666666666000000006660666666666666666666666660000666006666666666666666666166ff0000666066666666666666666666f7000
00006666666666666666666666666000000666666666666666666666616666000006666666666666666666666666f70000066666666666666666666666f70000
000666666666666666666666166660000006666666666666666666666fffff00000666666666666666666666666f700000066666666666666666666666f00000
00066077777776666666677777777000006660777777766666666677f707070000066007777777666666666777f7000000066600777777766666666677f00000
00060000077777666677777fffff0000006600000777766667777777f0707000006660000077776666777777777f070000066600000777776666777777f70000
000000000000776667777777700000000000000000007666777777777ffff0000066000000000766677777777777ff00006660000000007766677777777f7000
0000000000000066000000000000000000000000000006600000000000000000000000000000006600000000000000000066000000000000660000000007f000
00000000000000600000000000000000000000000000060000000000000000000000000000000060000000000000000000000000000000006000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000066000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000000000066600000000066000006600000000000666000000006000000000000000000006600000000000000000000000000000660000000000000000
00666600000000066660000000666f00006600000000000666600000066f70000066000000000006660000000060000000006000000000666000000000000000
00066660060000066666000000666f00006660000000000666660000066f0000006600000000000666600000066f700000066000000000666600000000000000
00006660066000066666600006666f00006660006000000666666000666f7000006600060000000666660000666f000000066006000000666660000000000000
00006666066600666666666666661f00000660006600006666666666661f0000006660066000006666666666666f700000066006000006666666666600000000
0000666666666666666666666666f700000666066666666666666666666f700000066006666666666666666661f0000000066606666666666666666666000000
000066666666666666666666666f700000066666666666666666666666f0000000066666666666666666666666f7000000066666666666666666666666660000
000066666666666666666666666f000000066666666666666666666666f700000006666666666666666666666f00000000066666666666666666666666666000
000066600777777766666666677f000000066600077777766666666667f000000006660077777766666666667f70000000066007777776666666666666616660
000066600000777776666777777f700000066600000077776666677777f7000000066000000777766666777777f00000000660000077776666677777fffffff0
0006660000000007766677777777f70000066600000000076666777777f0000000066000000000766667777777f7000000006000000007666677777f77777700
00066000000000000666000000007f0000066000000000006660000007f70000000660000000000666000000007f000000000000000000666000000000000000
0000000000000000066000000000000000066000000000006600000007f000000000000000000006600000000000000000000000000000660000000000000000
00000000000000000600000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200000c6100c6100c6100c6100c6100c6100c6100c610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001f020180202b00019000120000b0000800005000040000300002000020000100005000040000300002000010000100010000070001000010000110001300014000100000000000000000000000000000
00080000306202d6202a6202862024620206201c62017620136200f6200b6200862005620016000160005600036002960027600226001d6001b60010600006001560015600126000060015600156001560015600
01100000105501a550235502b5502f5502e5502b550255501e5501955014550115500f55000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
01010000105501a550235502b5502f5502e5502b550255501e5501955014550115500f55000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c0008217221d722247221d722297221d722237221d722007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702
01f0000c0554505545055450554505545045450554505545055450454505545055450050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
01f00410055050550505505055050c5450b5450c5450c5450c5450b5450c5450c5450c5450c5450c5450c54500505005050050500505005050050500505005050050500505005050050500505005050050500505
013c00300c0501505015050150551405010050100501005511050130501505015050150501505015050150550c050150501505018050170501405014050140551505017050180501805018050180501805018055
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0178000816750167551d7501b75014750147551d7501b750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
01f0000808750087500d7500d75008750087500675006750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0a0b0c0d
00 14154344

