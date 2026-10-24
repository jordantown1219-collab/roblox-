-- Pure server-side IDs/state only. Integration supplies authenticated IDs and time.
local Controller={}
Controller.__index=Controller
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function time(n) return finite(n) and n>=0 end
local function user(id) return finite(id) and id~=0 and id%1==0 and math.abs(id)<=9007199254740991 end
local function copy(value)
 if type(value)~="table" then return value end
 local result={} for k,v in pairs(value) do result[k]=copy(v) end return result
end
local function identity(id) return type(id)=="string" and id:match("^[%w_%-]+$") end
local function sortedIds(records)
 local result={} for id in pairs(records) do result[#result+1]=id end table.sort(result) return result
end
function Controller.new(config)
 assert(type(config)=="table","Missing lobby configuration")
 local self=setmetatable({config=copy(config),members={},epoch=1,phase="Queue",vote=nil},Controller)
 local c=self.config
 assert(finite(c.waitSeconds) and c.waitSeconds>=0 and finite(c.voteSeconds) and c.voteSeconds>0,"Invalid lobby durations")
 self.sizes={} self.maps={} self.modes={}
 assert(type(c.teamSizes)=="table" and #c.teamSizes>0,"Missing team sizes")
 for _,size in ipairs(c.teamSizes) do
  assert((size==3 or size==4 or size==5) and not self.sizes[size],"Invalid/duplicate team size") self.sizes[size]=true
 end
 table.sort(c.teamSizes)
 local function catalog(items,target)
  assert(type(items)=="table","Missing catalog")
  local available=0 local seen={}
  for _,item in ipairs(items) do
   assert(type(item)=="table" and identity(item.id) and not seen[item.id],"Invalid/duplicate catalog id")
   seen[item.id]=true
   if item.available==true then target[item.id]=item available=available+1 end
  end
  assert(available>0,"At least one available catalog item required")
 end
 catalog(c.maps,self.maps) catalog(c.modes,self.modes)
 self.modeIds={} for id in pairs(self.modes) do self.modeIds[#self.modeIds+1]=id end table.sort(self.modeIds)
 return self
end
function Controller:_group(mode,size)
 local group={} local earliest
 for id,member in pairs(self.members) do
  if not member.reserved and member.mode==mode and member.size==size then
   group[id]=member earliest=math.min(earliest or member.joined,member.joined)
  end
 end
 return group,earliest
end
local function startCount(group)
 local count,votes=0,0
 for _,member in pairs(group) do count=count+1 if member.startVote then votes=votes+1 end end
 return count,votes,math.floor(count/2)+1
end
function Controller:join(id,mode,size,now)
 if not user(id) or not time(now) or not self.modes[mode] or not self.sizes[size] or self.members[id] then return false end
 self.members[id]={mode=mode,size=size,joined=now,startVote=false,reserved=false}
 return true
end
function Controller:leave(id)
 if not self.members[id] then return false end
 self.members[id]=nil
 local vote=self.vote
 if vote and vote.players[id] then
  vote.players[id]=nil vote.votes[id]=nil
  local ids=sortedIds(vote.players)
  -- Keep teams balanced and return the highest unmatched ID to its original queue.
  if #ids%2==1 then
   local highest=ids[#ids] vote.players[highest]=nil vote.votes[highest]=nil
   self.members[highest].reserved=false self.members[highest].startVote=false
   ids[#ids]=nil
  end
  if #ids<2 then
   self.vote=nil self.phase="Queue" self.epoch=self.epoch+1
  end
 end
 return true
end
function Controller:voteStart(id,epoch,now)
 local member=self.members[id]
 if not time(now) or epoch~=self.epoch or self.phase~="Queue" or not member or member.reserved then return false end
 local group,earliest=self:_group(member.mode,member.size)
 local count=startCount(group)
 if count<2 or now<earliest+self.config.waitSeconds then return false end
 member.startVote=true return true
end
function Controller:voteMap(id,mapId,epoch,now)
 local vote=self.vote
 if not time(now) or epoch~=self.epoch or not vote or not vote.players[id] or now<vote.started or now>=vote.deadline or not self.maps[mapId] then return false end
 vote.votes[id]=mapId return true
end
function Controller:_begin(group,mode,size,now,limit)
 local ids=sortedIds(group) local count=math.min(#ids,limit)
 count=count-count%2
 local players={}
 for index=1,count do local id=ids[index] players[id]=true self.members[id].reserved=true self.members[id].startVote=false end
 self.epoch=self.epoch+1 self.phase="MapVote"
 self.vote={players=players,votes={},mode=mode,size=size,started=now,deadline=now+self.config.voteSeconds}
end
function Controller:tick(now)
 if not time(now) then return nil end
 local vote=self.vote
 if vote then
  if now<vote.deadline then return nil end
  local counts={} for id in pairs(self.maps) do counts[id]=0 end
  for id,map in pairs(vote.votes) do if vote.players[id] then counts[map]=counts[map]+1 end end
  local choices={} for id in pairs(self.maps) do choices[#choices+1]=id end table.sort(choices)
  local selected=choices[1]
  for _,id in ipairs(choices) do if counts[id]>counts[selected] then selected=id end end
  local ids=sortedIds(vote.players)
  for _,id in ipairs(ids) do self.members[id]=nil end
  self.vote=nil self.phase="Queue" self.epoch=self.epoch+1
  return {players=ids,mode=vote.mode,mapId=selected,teamSize=#ids/2,requestedTeamSize=vote.size}
 end
 -- Full rosters take priority, then any waited group with a strict majority.
 for _,size in ipairs(self.config.teamSizes) do for _,mode in ipairs(self.modeIds) do
  local group=self:_group(mode,size) local count=startCount(group)
  if count>=size*2 then self:_begin(group,mode,size,now,size*2) return nil end
 end end
 for _,size in ipairs(self.config.teamSizes) do for _,mode in ipairs(self.modeIds) do
  local group,earliest=self:_group(mode,size) local count,votes,needed=startCount(group)
  if count>=2 and now>=earliest+self.config.waitSeconds and votes>=needed then
   self:_begin(group,mode,size,now,count) return nil
  end
 end end
 return nil
end
function Controller:snapshot(id,now)
 now=time(now) and now or 0
 local member=self.members[id] local group,earliest={},nil
 if member then group,earliest=self:_group(member.mode,member.size) end
 local count,votes,needed=startCount(group)
 local queues={} for _,size in ipairs(self.config.teamSizes) do queues[size]=0 end
 for _,m in pairs(self.members) do if not m.reserved then queues[m.size]=queues[m.size]+1 end end
 local mapVotes={} for map in pairs(self.maps) do mapVotes[map]=0 end
 if self.vote then for who,map in pairs(self.vote.votes) do if self.vote.players[who] then mapVotes[map]=mapVotes[map]+1 end end end
 return {phase=self.phase,epoch=self.epoch,deadline=self.vote and self.vote.deadline or (earliest and earliest+self.config.waitSeconds or nil),
         queues=queues,ready=member~=nil,teamSize=member and member.size or nil,mode=member and member.mode or nil,
         canStartSmall=self.phase=="Queue" and member~=nil and count>=2 and now>=(earliest or now)+self.config.waitSeconds,
         startVotes=votes,startNeeded=needed,mapVotes=mapVotes,maps=copy(self.config.maps),modes=copy(self.config.modes),
         votedMap=self.vote and self.vote.votes[id] or nil}
end
return Controller
