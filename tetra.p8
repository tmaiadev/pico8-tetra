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
	gm:new()
end

function _update60()

end

function _draw()
end
-->8
-- game (gm)

gm={}
gm.__index=gm

gm.new=function()
	local self=
		setmetatable({},gm)

	self.stg=stg.new()
	self.score=score.new()
	self.t=t.new(0,0) -- tetra
	self.spd=1 -- speed
	self.dlt=0 -- delta
	self.tmr_mk_new_t=
		tmr.new(1)
	self.ani_clr_row=
		ani.new(12)

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
	
	-- create new tetra
	-- when tetra is moved
	self
		.tmr_mk_new_t
		:update(function()
				self.t=t.new()
			end)
	
	-- move tetra
	local t=self.t
	if t then

		if self.dlt==60 then
			t.col+=1
			self.score:add(1)
		elseif btn(⬇️) and
					self.dlt%4==0 then
			t.col+=1
			self.score:add(10)
		end
		
		if t:collides(self.stg) then
			t.col-=1
			self:t2stg()
			self.tmr_mk_new_t
				:start()
			return
		end
		
		-- reaches bottom
		if t.col+t:h()>15 then
			t.col=15-t:h()
			self:t2stg()
			self.tmr_mk_new_t
				:start()
			return
		end
		
		if btnp(⬅️) then
			if t.row>0 then
				t.row-=1
			end
			
			if t:collides(self.stg) then
				t.row+=1
			end
		elseif btnp(➡️) then
			t.row+=1
			local rt=t.row+t:w()
			
			if rt>9
				or t:collides(self.stg)
				then
				t.row-=1
			end
		end 

		-- rotate
		if btnp(🅾️) or btnp(⬆️) then
			local original_row=t.row
			t:rotate()
			
			if t.row<0 then
				t.row=0
			end
			
			if t.row+t:w() > 9 then
				t.row=9-t:w()
			end
			
			if t:collides(self.stg)
			then
				t:rotate(true)
				t.row=original_row
			end
		end
		
		if btn(⬇️) and btn(❎) then
			local shdw_y=
				t:shadow_col(self.stg)
				
			if shdw_y then
				t.col=shdw_y
				self.score:add(100)
				self:t2stg()
				self.tmr_mk_new_t
					:start()
				return
			end
		end
		
	end -- end of move tetra
end

gm.draw=function(self)
	cls()
	camera(-1,2)

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
		t:shadow_col(self.stg)
	if shadow then
		for b in all(t.blks) do
			local x=t.row+b.row
			local y=shadow+b.col
			
			mset(x,y,10)
		end
	end
	
	-- render tetra (player)
	if t then
		for b in all(t.blks) do
			local x=t.row+b.row
			local y=t.col+b.col
	
			mset(x,y,b.clr)
		end
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
end

-- tetra to stage
gm.t2stg=function(self)
	for b in all(self.t.blks) do
		b.row+=self.t.row
		b.col+=self.t.col
		
		stg:set(b)
	end
	
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
		self
			.ani_clr_row
			:clr()

		self
			.ani_clr_row
			:reset()
		
		for i=#rows,1,-1 do
		local row=rows[i]
			for col=0,9 do
				local dir=row%2==0
				 and 9-col
				 or col
				self
					.ani_clr_row
					:add(function()
						self.stg:rm(row,dir)
						self.score:add(100)
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

stg.set=function(self,blk)
	local m=self.map
	local row=blk.row+1
	local col=blk.col+1
	
	m[col][row]=blk
end

stg.rm=function(self,row,col)
	self.map[row+1][col+1]=false
end

stg.get=function(self,row,col)
		local m=self.map
	 local c=m[col+1]
	 
	 if not c then	return nil end
	 return c[row+1]
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
	row,
	col, -- column
	clr  -- color
)
	local self=
		setmetatable({},blk)
	
	self.row=row or 0
	self.col=col or 0
	self.clr=clr or 1
	
	return self
end
-->8
-- tetra (t)

t={}
t.__index=t

t.new=function(row,col)
	local self=
		setmetatable({},t)

	self.row=row or 0
	self.col=col or 0
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
-- 1 gray
-- 2 pink
-- 3 green
-- 4 orange
-- 5 blue
-- 6 red
-- 7 maroon 
t._mk_clr=function()
	return 1+flr(rnd(7))
end

-- make blocks
-- returns array of
-- blocks
t._mk_blks=function(self)
	local blks={}
	
	-- square
	if self.shape == 1 then
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
		else
			-- vertical
			dir_y=1
			self.dir_row_offset=-1
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
			-- xxx
			-- x
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
		elseif self.dir == 3 then
			-- xx
			--  x
			--  x
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
			--   x
			-- xxx
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
		end
	elseif self.shape==6 then
		-- reverse l
		if self.dir == 1 then
			--  x
			--  x
			-- xx
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
	local r=0
	
	for b in all(self.blks) do
		r=max(r,b.row)
	end
	
	return r
end

-- height
-- return height
t.h=function(self)
	local r=0
	
	for b in all(self.blks) do
		r=max(r,b.col)
	end
	
	return r
end

t.collides=function(self,stg)
	for b in all(self.blks) do
		local x=b.row+self.row
		local y=b.col+self.col
		
		if stg:get(x,y) then
			return true
		end
	end
	return false
end

t.rotate=function(self, undo)
	local dir=undo and -1 or 1
	self.dir+=dir
	self.row+=
		self.dir_row_offset*dir
	
	if self.dir<1 then
		self.dir=4
	end
	
	if self.dir>4 then
		self.dir=1
	end
	
	self.blks=self:_mk_blks()
end

t.shadow_col=function(self,stg)
	local original_col=self.col
	local shadow_col=nil
	
	for y=self.col+1,15-self:h() do
		self.col=y
		local collided = self:
			collides(stg)
		if collided then
			break
		else
			shadow_col=y
		end
	end
	
	self.col=original_col
	return shadow_col
end
-->8
-- utils

function debug(str)
	cls()
	print(str,5,5,7)
	stop()
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
	self.frame=1
	self.started=false
	self.ended=false
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
__gfx__
00000000d6d6d667efefeff7bababaa7a9a9aaa7c7c7c7778ee8e8e72ee2e2e71010101010101010202020200000000000000000000000000000000000000000
000000001dddddd62eeeeeef3bbbbbba4999999a1cccccc72888888e1222222e0000000001010101020202020000000000000000000000000000000000000000
00000000ddddddd6eeeeeeefbbbbbbba9999999accccccc788888888222222221010101010101010202020200000000000000000000000000000000000000000
000000001ddddddd2eeeeeee3bbbbbbb499999991ccccccc2888888e1222222e0000000001010101020202020000000000000000000000000000000000000000
00000000ddddddd6eeeeeeefbbbbbbba9999999accccccc788888888222222221010101011111111202020200000000000000000000000000000000000000000
000000001ddddddd2eeeeeee3bbbbbbb499999991ccccccc2888888e1222222e0101010101010101020202020000000000000000000000000000000000000000
000000001dddddd62eeeeeef3bbbbbba4999999a1cccccc72888888e1222222e1010101011111111202020200000000000000000000000000000000000000000
00000000111d1d1d222e2e2e333b3b3b44494949111c1c1c22282828111212120101010101010101020202020000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000066000000000000770000000000000000000000000000000000000000000000000000000000000000000000000000
00667700000660000000000007766000000066000006677000770000000000000000000000000000000000000000000000000000000000000000000000000000
00667700000660006677667707766000006677000006677000667700000000000000000000000000000000000000000000000000000000000000000000000000
00776600000770006677667700077660006677000667700000667700000000000000000000000000000000000000000000000000000000000000000000000000
00776600000770000000000000077660007700000667700000006600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000007700000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000000000202004020080200d020150201a0201e020200201d020190201402010020180201f020250202b0202b02027020220201b02015020110200d0200b010080500605005050030500205001050000500f000
000100002862026620246200c6200c6201a6201b6201c6201a620156200f62006620066200d6200f62010620116200f6200b6200a620036200862008620096200962008620066200362001620016200062000620
0001000800050020000200002000030000300026000030000900000000060000500000000120000f0000c0000a00009000070000900005000040000400002000020000200001000010000100001000000000a000
000700000b050000000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001605016050160501505013050100500c05007050000500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0012000028050003002305024050260500c000240502305021050080002105024050280501a000260502405023050220002305024050260502900028050240002405023000210501700021050020000000010000
__music__
00 05424344

