pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- tetra
-- copyright (c) 2025 thalles maia

-- this program is free software: you can redistribute it and/or modify
-- it under the terms of the gnu general public license as published by
-- the free software foundation, either version 3 of the license, or
-- any later version.

-- this program is distributed in the hope that it will be useful,
-- but without any warranty; without even the implied warranty of
-- merchantability or fitness for a particular purpose.  see the
-- gnu general public license for more details.

-- you should have received a copy of the gnu general public license
-- along with this program.  if not, see <https://www.gnu.org/licenses/>.

function _init()
	gm.new()
end

function _update60()

end

function _draw()
end
-->8
-- game (gm)

gm={}
gm.__index=gm

gm.new=function(level)
	local self=
		setmetatable({},gm)

	self.stg=stg.new()
	self.score=score.new()
	self.t=t.new(4,-2) -- tetra
	self.nxt_t=t.new(4,-2) -- next tetra
	self.spd=1 -- speed
	self.dlt=0 -- delta
	self.lvl=level or 1
	self.n_rows_cleared=0
	self.tmr_mk_new_t=
		tmr.new(1)
	self.ani_clr_row=
		ani.new(12)
	self.ani_cmr_shk=
		ani.new(60)
	self.ani_gameover=
		ani.new(60)
	self.eyes_pos=nil
	self.camera={x=0,y=0}
	self.gameover=false
	
	self:_mk_cmr_shk_ani()
	self:_mk_gameover_ani()
	
	_update60=function()
		self:update()
	end

	_draw=function()
		self:draw()
	end

	return self
end

gm.update=function(self)
	-- update delta
	self.dlt+=1
	if self.dlt>60 then
		self.dlt=1
	end
	
	-- no updates if
	-- game is over
	-- until game is
	--  restarted
	if self.gameover then
		if btnp(❎) then
			self.new()
		end
		
		return
	end
	
	-- wait for gameover
	-- animation if it has
	-- started
	if self.ani_gameover.started
	and not self.ani_gameover.ended
	then
		self.ani_gameover:update()

		return
	end
	
	-- animate camera shake
	self.ani_cmr_shk:update()
			
	-- wait for row clear
	-- animation to end
	if self.ani_clr_row.started
	and not self.ani_clr_row.ended
	then
		self
			.ani_clr_row
			:update()
		return
	end
	
	-- update timer for
	-- creating new tetra
	self
		.tmr_mk_new_t
		:update(function()
				self.t=self.nxt_t
				self.nxt_t=t.new(4,-2)
			end)
	
	-- move tetra
	local t=self.t
	if t then

		local dlt_matches=
			ceil(60/self.lvl)
		if self.dlt%dlt_matches==0 then
			t.y+=1
			self.score:add(1)
		elseif btn(⬇️) and
					self.dlt%4==0 then
			t.y+=1
			self.score:add(10)
			sfx_fast()
		end
		
		if t:collides(self.stg) then
			if t.y<=0 then
				t=nil
				self.ani_gameover:start()
				return
			end
			
			t.y-=1
			self:t2stg()
			self.tmr_mk_new_t
					:start()

			if btn(⬇️) then
				self.ani_cmr_shk
					:start()
				sfx_impact()				
			else
				sfx_pop()
			end
			return
		end
		
		-- reaches bottom
		if t.y+t:h()>15 then
			t.y=15-t:h()
			self:t2stg()
			self.tmr_mk_new_t
				:start()
			
			if btn(⬇️) then
				self.ani_cmr_shk
					:start()
				sfx_impact()	
			else
				sfx_pop()
			end
			return
		end
		
		if btnp(⬅️) then
			t.x-=1
			
			if t.x<0
			or t:collides(self.stg) 
			then
				t.x+=1
				sfx_nope()
			end
		elseif btnp(➡️) then
			t.x+=1
			local rt=t.x+t:w()
			
			if rt>9
				or t:collides(self.stg)
				then
				t.x-=1
				sfx_nope()
			end
		end 

		-- rotate
		if btnp(🅾️) or btnp(⬆️) then
			local original_x=t.x
			local success=true
			t:rotate()
			
			if t.x<0 then
				t.x=0
				success=false
			end
			
			if t.x+t:w() > 9 then
				t.x=9-t:w()
				success=false
			end
			
			if t:collides(self.stg)
			then
				t:rotate(true)
				t.x=original_x
				success=false
			end
			
			if success then
				sfx_rotate()
			else
				sfx_nope()
			end
		end
		
		if btn(⬇️) and btn(❎) then
			local shdw_y=
				t:shadow_y(self.stg)
				
			if shdw_y then
				t.y=shdw_y
				self.score:add(100)
				self:t2stg()
				self.tmr_mk_new_t
					:start()
				self.ani_cmr_shk
					:start()
				sfx_impact()
				return
			end
		end
		
	end -- end of move tetra
end

gm.draw=function(self)
	cls()
	camera(
		self.camera.x+-1,
		self.camera.y+2
	)

	self:stg_bg_draw()	

	-- clear map
	map()
	for y=0,15 do
		for x=0,9 do
			mset(x,y,nil)
		end
	end
	
	local t=self.t
	
	-- render tetra (shadow)
	local shadow=t and
		t:shadow_y(self.stg)
	if shadow then
		for b in all(t.blks) do
			local x=t.x+b.x
			local y=shadow+b.y
			
			mset(x,y,10)
		end
	end
	
	-- render tetra (player)
	if t then
		for b in all(t.blks) do
			local x=t.x+b.x
			local y=t.y+b.y
	
			mset(x,y,b.clr)
		end
	end
	
	-- render tetra eyes
	if t then
		local sprite=11 -- default
		
		if self.dlt>15 and -- blink
					self.dlt<35 and
					flr(time())%3==0 then
			sprite=12
		end
		
		if btn(⬇️) then
			sprite=13
		end
		
		self.eyes_pos=self:
			_calc_eyes_pos()
		
		spr(
			sprite,
			8*self.eyes_pos.x,
			8*self.eyes_pos.y
		)
	elseif self.eyes_pos then
		spr(
			14,
			8*self.eyes_pos.x,
			8*self.eyes_pos.y
		)
	end
	
	-- render stage
	for y=0,15 do
		for x=0,9 do
			local b = self
				.stg:get(x,y)
			if b then
				mset(x,y,b.clr)
			end
		end
	end
	
	-- render score
	print("score:", 84, 4, 7)
	print(
		self.score:get(),
		84,
		10,
		7
	)
	
	-- render preview
	if not self.gameover then
		print("next:", 84, 20, 7)
		rect(84, 26, 95, 37, 7)
		spr(
			self.nxt_t.preview,
			86,
			28
		)
	end
	
	-- render level
	if not self.gameover then
		print("level:", 84, 44, 7)
		print(self.lvl, 84, 50, 7)
	end
	
	-- render tutorial
	local lh=7 -- line height
	local b=128 -- bottom	
	
	if self.gameover then
		print("❎ restart", 84, b-lh, 7)
	elseif self.t
		and not self.ani_gameover.started
		then
		print("🅾️/⬆️ rot8", 84, b-lh*3, 7)
		print("⬇️    fast", 84, b-lh*2, 7)
		print("⬇️+❎ drop", 84, b-lh, 7)
	end
end

-- tetra to stage
gm.t2stg=function(self)
	self.eyes_pos=self:_calc_eyes_pos()
	self.stg:set_tetra(self.t)
	self.t=nil
	self:check_for_filled_rows()
end

gm.stg_bg_draw=function(self)
		-- render stage gradient
	rectfill(0,0,80,7,1)
	for i=0,9 do
		spr(9,i*8,8,1,1,false,true)
	end
	for i=0,9 do
		spr(8,i*8,16,1,1,false,true)
	end
	for i=0,9 do
		spr(8,i*8,108,1,1)
	end
	for i=0,9 do
		spr(9,i*8,116,1,1)
	end
	rectfill(0,124,80,128,1)

	-- render borders
	rect(-1,-1,80,128,1)
end

gm.check_for_filled_rows=
	function(self)
	local rows=self.stg:
		get_filled_rows_idx()
	
	if #rows>0 then
		self.n_rows_cleared+=#rows
		
		-- level up every
		-- 4 rows cleared
		if self.n_rows_cleared%4==0
		and self.lvl<10 then
			self.lvl+=1
		end
		
		self
			.ani_clr_row
			:clr()

		self
			.ani_clr_row
			:reset()
		
		for i=#rows,1,-1 do
		local y=rows[i]
			for x=0,9 do
				local dir=y%2==0
				 and 9-x
				 or x
				self
					.ani_clr_row
					:add(function()
						self.stg:rm(dir,y)
						self.score:add(100)
						sfx_pop()
				end)
			end
		end
		
		self
				.ani_clr_row
				:add(function()
					self.stg:clr_empty_rows()
				end)
		
		self
			.ani_clr_row
			:start()
	end
end

-- calc eyes position
gm._calc_eyes_pos=function(self)
	local t=self.t
	
	if not t then
		return self.eyes_pos or nil
	end
	
	local fst_blk_x=nil
	local fst_blk_y=nil

	for b in all(t.blks)	do 
		if not fst_blk_y
		and not fst_blk_x then
				fst_blk_x=b.x
				fst_blk_y=b.y
		end
	end
	
	return {
		x=t.x+fst_blk_x,
		y=t.y+fst_blk_y
	}
end

-- make camera shake
-- animation frames
gm._mk_cmr_shk_ani=
	function(self)
	
	for i=15,1,-1 do
		self.ani_cmr_shk:add(
			function()
				local x=i%3==0 and -1 or 1
				local y=flr(i/3)*-1
				
				
				self.camera={x=x,y=y}
			end
		)
	end

	self.ani_cmr_shk.on_end=
	function()
		self.camera.x=0
		self.camera.y=0
		self.ani_cmr_shk:reset()
	end
end

-- gameover animation
gm._mk_gameover_ani=function(self)
	for y=15,0,-1 do
		for x=9,0,-1 do
			self.ani_gameover:add(
				function()
					local x=y%2==0
						and 9-x
						or x
					local b=self.stg:get(x,y)
					local l={} -- lettering
					l[7]={}
					l[7][3]=35 -- g
					l[7][4]=36 -- a
					l[7][5]=37 -- m
					l[7][6]=38 -- e
					l[8]={}
					l[8][3]=39 -- o
					l[8][4]=40 -- v
					l[8][5]=38 -- e
					l[8][6]=41 -- r
					local bb={ -- black block
						y={6,7},
						x={3,4,5,6}
					}
					local is_bb=
						l[y]
						and l[y][x]
					
					if is_bb then
						self.stg:set(
							blk.new(
								x,
								y,
								is_bb
							)
						)
					elseif not b then
						self.stg:set(
							blk.new(
								x,
								y,
								1
							)
						)
					end
					
					sfx_pop()
				end
			)

		end -- eox
	end -- eoy
	
	self.ani_gameover.on_end=
		function()
			self.t=nil
			self.eyes_pos=nil
			self.gameover=true
	end
end
-->8
-- stage (stg)

stg={}
stg.__index=stg

stg.new=function()
	local self=
		setmetatable({},stg)
	
	stg.map=stg:_mk_map()
		
	return self
end

stg.set=function(self, b)
	self.map[b.y+1][b.x+1]=b
end

stg.set_tetra=function(self,t)
	for b in all(t.blks) do
		local x=b.x+t.x+1
		local y=b.y+t.y+1
		
		if x>=1 and x<=10
		and y>=1 and y<=16
		then
			self.map[y][x]=blk.new(
				x,
				y,
				b.clr
			)
		end
	end
end

stg.rm=function(self,x,y)
	self.map[y+1][x+1]=false
end

stg.get=function(self,x,y)
	 local row=self.map[y+1]
	 
	 if not row then
	 	return nil
	 end
	 
	 return row[x+1]
end

-- make map
stg._mk_map=function(self)
	local m={}
	
	for y=1,16 do
		local row={}
		for x=1,10 do
			add(row, false)
		end
		add(m, row)
	end
	
	return m
end

stg.get_filled_rows_idx=
				function(self)
	local idx={}
	
	for y=0,15 do
		local filled=true
		for x=0,9 do
			if not self:get(x,y) then
				filled=false
				break
			end
		end
		if filled then
			add(idx,y)
		end
	end
	
	return idx
end

stg._is_row_empty=
	function(self,y)
	
	for col in all(self.map[y]) do
		if col then
			return false
		end
	end
	
	return true
end

stg._mk_empty_row=function(self)
	local r={}
	for i=1,16 do
		add(r, false)
	end
	return r
end

stg.clr_empty_rows=
	function(self)
	local rows_to_be_deleted={}
	local after_first_dirty=false
	
	for y=1,16 do
		if not after_first_dirty
		and not self:_is_row_empty(y)
		then
			after_first_dirty=true	
		end
		
		if after_first_dirty
		and self:_is_row_empty(y)
		then
			add(rows_to_be_deleted,y)
		end
	end
	
	for r
	in all(rows_to_be_deleted) do
		deli(self.map, r)
		add(
			self.map,
			self:_mk_empty_row(),
			1
		)
	end
end
-->8
-- block (blk)
blk={}
blk.__index=blk

blk.new=function(
	x,
	y,
	clr  -- color
)
	local self=
		setmetatable({},blk)
	
	self.x=x or 0
	self.y=y or 0
	self.clr=clr or 1
	
	return self
end
-->8
-- tetra (t)

t={}
t.__index=t

t.new=function(x,y)
	local self=
		setmetatable({},t)

	self.x=x or 0
	self.y=y or 0
	self.preview=0 -- spr for "next"
	self.clr=self:_mk_clr()
	self.shape=self:_mk_shape()
	self.dir=self:_mk_dir()
	self.dir_row_offset=0
	self.blks=self:_mk_blks()
	
	return self
end

-- make shake
-- returns random shape
-- 1 - square
-- 2 - line
-- 3 - z shape
-- 4 - s shape
-- 5 - l shape
-- 6 - reverse l
-- 7 - triangle
t._mk_shape=function() 
	return 1+flr(rnd(7))
end

-- make direction
-- returns random
-- orientation:
-- 1 - upright
-- 2 - right
-- 3 - upsidedown
-- 4 - left
t._mk_dir=function()
	return 1+flr(rnd(4))
end

-- make color
-- returns random
-- block color
-- 1 gray - exclusive for death screen
-- 2 pink
-- 3 green
-- 4 orange
-- 5 blue
-- 6 red
-- 7 maroon 
t._mk_clr=function()
	return 2+flr(rnd(6))
end

-- make blocks
-- returns array of
-- blocks
t._mk_blks=function(self)
	local blks={}
	
	-- square
	if self.shape == 1 then
		self.preview=16
		add(blks,blk.new(0,0,self.clr))
		add(blks,blk.new(0,1,self.clr))
		add(blks,blk.new(1,0,self.clr))
		add(blks,blk.new(1,1,self.clr))
	elseif self.shape == 2 then
		-- line
		local dir_x=0
		local dir_y=0
		
		if self.dir%2==0 then
			-- horizontal
			dir_x=1
			self.dir_row_offset=1
			self.preview=18
		else
			-- vertical
			dir_y=1
			self.dir_row_offset=-1
			self.preview=17
		end
		
		for i=0,3 do
			add(
				blks,
				blk.new(
					i*dir_x,
					i*dir_y,
					self.clr
				)
			)
		end
	elseif self.shape==3 then
		-- z shape
		if self.dir%2==0 then
			--  x
			-- xx
			-- x
			self.preview=20
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				0,2,self.clr
			))
		else
			-- xx
			--  xx
			self.preview=19
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				2,1,self.clr
			))
		end
	elseif self.shape==4 then
		-- s shape
		if self.dir%2==0 then
			-- x
			-- xx
			--  x
		self.preview=22
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				1,2,self.clr
			))
		else
			--  xx
			-- xx 
			self.preview=21
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				2,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
		end
	elseif self.shape==5 then
		-- l shape
		if self.dir == 1 then
			self.preview=23
			-- x
			-- x
			-- xx
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				0,2,self.clr
			))
			add(blks,blk.new(
				1,2,self.clr
			))
		elseif self.dir == 2 then
			--   x
			-- xxx
			self.preview=24
			add(blks,blk.new(
				2,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				2,1,self.clr
			))
		elseif self.dir == 3 then
			-- xx
			--  x
			--  x
		self.preview=25
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				1,2,self.clr
			))
		else
			-- xxx
			-- x
		self.preview=26
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				2,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
		end
	elseif self.shape==6 then
		-- reverse l
		if self.dir == 1 then
			--  x
			--  x
			-- xx
			self.preview=27
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				0,2,self.clr
			))
			add(blks,blk.new(
				1,2,self.clr
			))
		elseif self.dir == 2 then
			-- x
			-- xxx
			self.preview=28
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				2,1,self.clr
			))
		elseif self.dir == 3 then
			-- xx
			-- x
			-- x
			self.preview=29
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				0,2,self.clr
			))
		else
			-- xxx
			--   x
			self.preview=30
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				2,0,self.clr
			))
			add(blks,blk.new(
				2,1,self.clr
			))
		end
	else
	-- triangle
		if self.dir == 1 then
			--  x
			-- xxx
			self.preview=31
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				2,1,self.clr
			))
		elseif self.dir == 2 then
			-- x
			-- xx
			-- x
			self.preview=32
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				0,2,self.clr
			))
		elseif self.dir == 3 then
			-- xxx
			--  x
			self.preview=33
			add(blks,blk.new(
				0,0,self.clr
			))
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				2,0,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
		else
			--  x
			-- xx
			--  x
			self.preview=34
			add(blks,blk.new(
				1,0,self.clr
			))
			add(blks,blk.new(
				0,1,self.clr
			))
			add(blks,blk.new(
				1,1,self.clr
			))
			add(blks,blk.new(
				1,2,self.clr
			))
		end
	end
	
	return blks
end

-- width
-- return width
t.w=function(self)
	local x=0
	
	for b in all(self.blks) do
		x=max(x,b.x)
	end
	
	return x
end

-- height
-- return height
t.h=function(self)
	local y=0
	
	for b in all(self.blks) do
		y=max(y,b.y)
	end
	
	return y
end

t.collides=function(self,stg)
	for b in all(self.blks) do
		local x=b.x+self.x
		local y=b.y+self.y
		
		if stg:get(x,y) then
			return true
		end
	end
	return false
end

t.rotate=function(self, undo)
	local dir=undo and -1 or 1
	self.dir+=dir
	self.x+=
		self.dir_row_offset*dir
	
	if self.dir<1 then
		self.dir=4
	end
	
	if self.dir>4 then
		self.dir=1
	end
	
	self.blks=self:_mk_blks()
end

t.shadow_y=function(self,stg)
	local original_y=self.y
	local shadow_y=nil
	
	for y=self.y+1,15-self:h() do
		self.y=y
		local collided = self:
			collides(stg)
		if collided then
			break
		else
			shadow_y=y
		end
	end
	
	self.y=original_y
	return shadow_y
end
-->8
-- utils

function debug(str)
	cls()
	print(str,5,5,7)
	stop()
end

function contains(val, tbl)
	for k, v in ipairs(tbl) do
 	if v==val	then
  	return true
  end
 end
	return false
end

-- timer (tmr)

tmr={}
tmr.__index=tmr

tmr.new=function(
	timeout -- in seconds
)
	local self=
		setmetatable({}, tmr)
		
	self.started_at=time()
	self.timeout=timeout or 1
	self.started=false
	self.ended=false
		
	return self
end

tmr.start=function(self)
	self.started_at=time()
	self.started=true
	self.ended=false
end

tmr.update=function(self,cb)
	if self.ended or
				not self.started then
			return
	end
	
	local diff=
		time()-self.started_at
	
	if diff>self.timeout then
		cb()
		self.ended=true
	end
end

-- ani

ani={}
ani.__index=ani

ani.new=function(fps,loop)
	local self=
		setmetatable({},ani)
	
	self.fps=fps or 60
	self.loop=loop or false
	self.frames={}
	self.frame=1 -- current frame
	self.dlt=0   -- delta
	self.started=false
	self.ended=false
	self.on_end=nil
	
	return self
end

ani.start=function(self)
	self.started=true
end

ani.update=function(self)
	if not self.started
	or self.ended
	then
		return
	end
	
	local mod=ceil(60/self.fps)
	local matches_fps=
		self.dlt%mod==0
	
	if matches_fps then
		local frame=
			self.frames[self.frame]
		
		if frame then
			if not frame.fired then
				frame.fn()
				self.
					frames[self.frame]
					.fired=true
			end
		elseif self.loop then
			self.frame=1
		else
			self.ended=true
			if self.on_end then
				self.on_end()
			end
		end
		self.frame+=1
	end
	self.dlt+=1
end

ani.add=function(self, fn)
	add(self.frames, {
		fired=false,
		fn=fn
	})
end

ani.clr=function(self)
	self.frames={}
end

ani.reset=function(self)
	self.dlt=0
	self.frame=1
	self.started=false
	self.ended=false
	
	for f in all(self.frames) do
		f.fired=false
	end
end
-->8
-- score

score={}
score.__index=score

score.new=function()
	local self=
		setmetatable({}, score)
	
	self.d={0,0,0}
	
	return self
end

score.add=function(self, value)
	self.d[1]+=value
	
	for i=1, #self.d-1 do
		if self.d[i]>9999 then
			local carry=flr(self.d[i]/10000)
			self.d[i+1]+=carry
			self.d[i]%=10000
		else
			break
		end
	end
end

score.get=function(self)
	if self.d[3]>99 then
		self.d[3]=99
		self.d[2]=9999
		self.d[1]=9999
	end
	
	local s3=tostr(self.d[3])
	while #s3<2 do s3="0"..s3 end
	
	local s2=tostr(self.d[2])
	while #s2<4 do s2="0"..s2 end
	
	local s1=tostr(self.d[1])
	while #s1<4 do s1="0"..s1 end
	
	return s3..s2..s1
end
-->8
-- sounds

function sfx_rotate()
	sfx(0)
end

function sfx_impact()
	sfx(1)
end

function sfx_fast()
	sfx(2)
end

function sfx_nope()
	sfx(3)
end

function sfx_pop()
	sfx(4)
end
__gfx__
00000000d6d6d667efefeff7bababaa7a9a9aaa7c7c7c7778ee8e8e72ee2e2e71010101010101010202020200000000000000000000000000000000000000000
000000001dddddd62eeeeeef3bbbbbba4999999a1cccccc72888888e1222222e0000000001010101020202020010010000000000000000000110011000000000
00000000ddddddd6eeeeeeefbbbbbbba9999999accccccc788888888222222221010101010101010202020200100001001100110010000100000000000000000
000000001ddddddd2eeeeeee3bbbbbbb499999991ccccccc2888888e1222222e0000000001010101020202020070007000000000001001000010001000000000
00000000ddddddd6eeeeeeefbbbbbbba9999999accccccc788888888222222221010101011111111202020200770077000000000070000700111011100000000
000000001ddddddd2eeeeeee3bbbbbbb499999991ccccccc2888888e1222222e0101010101010101020202020710071010001000077007700010001000000000
000000001dddddd62eeeeeef3bbbbbba4999999a1cccccc72888888e1222222e1010101011111111202020200710071001100110078007800000000000000000
00000000111d1d1d222e2e2e333b3b3b44494949111c1c1c22282828111212120101010101010101020202020000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000066000000000000770000007700000000000000667700000000000000660000000000006677000000000000000000
00667700000660000000000007766000000066000006677000770000007700000000066000667700077667700000660007700000006677000667766000077000
00667700000660006677667707766000006677000006677000667700006600000000066000006600077667700000770007700000007700000667766000077000
00776600000770006677667700077660006677000667700000667700006600000776677000006600066000000000770006677660007700000000077007766770
00776600000770000000000000077660007700000667700000006600007766000776677000007700066000000077660006677660006600000000077007766770
00000000000660000000000000000000007700000000000000006600007766000000000000007700000000000077660000000000006600000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770000000000000000770000077000000700000077700000777000000770000070700000777000000000000000000000000000000000000000000000000000
00770000077667700000770000755000007570000077700000755000007570000070700000757000000000000000000000000000000000000000000000000000
00667700077667700077660000700000007770000075700000770000007070000070700000775000000000000000000000000000000000000000000000000000
00667700000770000077660000707000007570000070700000750000007070000070700000757000000000000000000000000000000000000000000000000000
00770000000770000000770000777000007070000070700000777000007750000057500000707000000000000000000000000000000000000000000000000000
00770000000000000000770000555000005050000050500000555000005500000005000000505000000000000000000000000000000000000000000000000000
__sfx__
000000000202004020080200d020150201a0201e020200201d020190201402010020180201f020250202b0202b02027020220201b02015020110200d0200b010080500605005050030500205001050000500f000
000100002862026620246200c6200c6201a6201b6201c6201a620156200f62006620066200d6200f62010620116200f6200b6200a620036200862008620096200962008620066200362001620016200062000620
0001000000530001000010000100001000300026000030000900000000060000500000000120000f0000c0000a00009000070000900005000040000400002000020000200001000010000100001000000000a000
000700000b0500b0000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000005500155003550075500c55011550165501a5501e5501e55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002d4002d4003740037400344003440030400230002f400304003240034400354003440032400304002f4002d4002c4002d400260002900028000240002400023000210001700021000020000000010000
000f000015300103001530010300153001030015300103000e300153000e300153001030017300103001730010300173001430017300103001030010300103001030010300103001030010300103001030010300
001000002d7002d7002d7002d7002d7002d7002d7002d700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 05060708

