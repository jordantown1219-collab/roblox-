-- Lead runs once through Client execute_luau during Play. No persistent objects/settings.
local RunService=game:GetService("RunService")
assert(RunService:IsClient(),"Run this sample on the playing Client, not Edit/Server")
local Stats=game:GetService("Stats")
local HttpService=game:GetService("HttpService")
local function memory()
    local ok,value=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
    return ok and value or nil
end
local function parts()
    local total,unanchored=0,0
    for _,item in ipairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") then
            total=total+1
            if not item.Anchored then unanchored=unanchored+1 end
        end
    end
    return {loaded=total,unanchored=unanchored}
end
local function position(value)
    return {x=value.X,y=value.Y,z=value.Z}
end
local camera=workspace.CurrentCamera
local viewport=camera and {width=camera.ViewportSize.X,height=camera.ViewportSize.Y} or nil
local cameraPosition=camera and position(camera.CFrame.Position) or nil
local startParts,startMemory=parts(),memory()
local intervals,connection={},nil
local frames,started,previous=0,os.clock(),nil
local ok,result=xpcall(function()
    connection=RunService.RenderStepped:Connect(function()
        local stamp=os.clock()
        frames=frames+1
        -- First callback has no preceding observed render; exclude it from percentiles.
        if previous then intervals[#intervals+1]=(stamp-previous)*1000 end
        previous=stamp
    end)
    task.wait(10)
    local elapsed=os.clock()-started
    connection:Disconnect()
    connection=nil
    table.sort(intervals)
    local function percentile(fraction)
        return #intervals>0 and intervals[math.clamp(math.ceil(#intervals*fraction),1,#intervals)] or nil
    end
    return {
        sample="CashCity-client-10s-v1",isStudio=RunService:IsStudio(),
        requestedSeconds=10,elapsedSeconds=elapsed,renderCallbacks=frames,
        averageFPS=frames/elapsed,observedIntervals=#intervals,
        medianFrameMs=percentile(.5),p95FrameMs=percentile(.95),
        worstFrameMs=intervals[#intervals],
        memoryStartMb=startMemory,memoryEndMb=memory(),
        partsStart=startParts,partsEnd=parts(),
        viewportStart=viewport,cameraPositionStart=cameraPosition,
        streamingEnabled=workspace.StreamingEnabled,
        cleanup="RenderStepped listener disconnected; no objects or attributes created",
    }
end,debug.traceback)
if connection then connection:Disconnect() connection=nil end
if not ok then error(result) end
return HttpService:JSONEncode(result)
