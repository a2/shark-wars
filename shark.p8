pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--shark
--by a2

function _init()
  add_mode("intro",intro_init,intro_update,intro_draw)
  add_mode("game",game_init,game_update,game_draw)
  set_mode("intro")
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
  function wrap(default,custom)
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
  foreach_game_object(function(obj,layer)
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
--intro loop
function intro_init(mode)
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
  function draw_back(message,y,palette)
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
  --gameplay view constraints
  mode.min_y=9
  mode.max_y=127

  --start score counter at zero
  mode.score=0

  --store current time
  mode.start=time()

  --create initial objects
  make_starfield()
  mode.shark=make_shark(8,60)

  make_enemy_generator()
end

function game_update(mode)
  foreach_game_object_named("enemy",function(enemy)
    if enemy.x+enemy.width<0 then
      mode.shark.health-=1
      enemy.finished=true
    end
  end)

  if mode.shark.health<0 then
    --game over
    set_mode("game")
  end
end

function game_draw(mode)
  local shark=mode.shark

  --top gray bar
  rectfill(0,0,128,6,5)

  --health hearts (right)
  local i
  for i=1,shark.health_max do
    print("♥",128-7*i,1,ternary(shark.health>=i,8,2))
  end

  --score (left)
  print("score:"..mode.score,1,1,7)
  --print("fps:"..stat(7),104,122,7)
  --print("cs:"..shark:charge_speed(),0,122,7)

  --laser bar
  local colors={9,10,11}
  local percent=shark.charge/shark.charge_max
  line(-1,7,flr(percent*129)-1,7,colors[ceil(percent*#colors)])
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

function make_shark(x,y)
  return make_game_object("shark",x,y,0,{
    width=8,
    height=8,
    charge=10,
    charge_max=10,
    health=3,
    health_max=3,
    charge_speed=function(self)
      local duration=time()-mode.start
      return 0.1-0.05*min(1,duration/60)
    end,
    update=function(self)
      --shoot on 🅾️
      if btn(4) then
        if self.charge>0 and self.last_laser==nil then
          sfx(1)
          self.last_laser=make_laser(self.x+6,self.y)
          self.charge-=1
        end
      else
        self.last_laser=nil
      end

      self.charge=min(self.charge_max,self.charge+self:charge_speed())
      if (btn(2) and self.y>mode.min_y) self.y-=1
      if (btn(3) and self.y+self.height<mode.max_y) self.y+=1
    end,
    draw=function(self)
      spr(0,self.x,self.y)
    end,
  })
end

function make_laser(x,y)
  return make_game_object("laser",x,y,1,{
    width=1,
    height=1,
    update=function(self)
      self.x+=1
      if (self.x>128) self.finished=true
    end,
    draw=function(self)
      pset(self.x,self.y,8)
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

function make_enemy(x,y,c)
  make_game_object("enemy",x,y,0,{
    width=8,
    height=8,
    damage=0,
    max_damage=5,
    color=c,
    update=function(self)
      self.x-=0.5

      foreach_game_object_named("laser",function(obj)
        if self:overlaps(obj) then
          self.damage+=1
          obj.finished=true
        end
      end)

      if self.damage>=self.max_damage then
        self.finished=true
        mode.score+=1
      end
    end,
    draw=function(self)
      pal(14,self.color)
      spr(1,self.x,self.y)
      pal()
    end
  })
end

function make_enemy_generator()
  return make_game_object("enemy_generator",0,0,-1,{
    visible=false,
    last_spawn=0,
    update=function(self)
      local now=time()
      local duration=now-self.last_spawn
      if duration>3 then
        local colors={10,11,12,14,15}
        make_enemy(128,rndb(mode.min_y,mode.max_y-11),colors[rndb(1,#colors)])
        self.last_spawn=now
      end
    end
  })
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

--increment a counter, wrapping to 20000 if it risks overflowing
function increment_counter(n)
  return n+ternary(n>32000,-12000,1)
end

--decrement a counter but not below 0
function decrement_counter(n)
  return max(0,n-1)
end

function filter_out_finished()
  foreach_game_object(function(obj,layer,list)
    if (obj.finished) del(list,obj)
  end)
end
__gfx__
000055e0000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00056000005555590000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60066600055e55580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666666665ee55500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666166055e55580000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60766770005555590000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111611111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111661155110000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111155555e11000000005550055a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61111166666611110000055555555589000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61116666666666110005555555555589000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6616666666666661055555ee5555555a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666006665555eeee55555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666006665555eeee55555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6666666666666666055555ee5555555a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
661776666666fff10005555555555589000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61117766667777110000055555555589000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6111176661111111000000005550055a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111166111111110000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200000c6100c6100c6100c6100c6100c6100c6100c6100d6000d6000d6000d6000d60016600026000160016600166001660005600076000860008600086000860000600006000060000600006000060000600
010100002b020240202b00019000120000b0000800005000040000300002000020000100005000040000300002000010000100010000070001000010000110001300014000100000000000000000000000000000
