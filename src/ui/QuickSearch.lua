-- A native command palette: touch button or Ctrl+K, no simulated input.
local UserInputService=game:GetService("UserInputService")
return function(ctx)
	local Kit=ctx.Kit
	local commands={
		{Title="Home",Hint="Session overview and cinema",Words="dashboard welcome fps ping",Tab="home"},
		{Title="Game library",Hint="Your games and favorites",Words="hub execute launch scripts favorite",Tab="hub"},
		{Title="Combat",Hint="Universal targeting controls",Words="aim assist trigger",Tab="combat"},
		{Title="Visuals",Hint="Player overlays and visibility",Words="esp chams name fullbright highlight",Tab="visuals"},
		{Title="Movement",Hint="Movement and camera tools",Words="fly speed jump noclip freecam waypoint",Tab="movement"},
		{Title="Players",Hint="Find and inspect a player",Words="avatar portrait spectate username",Tab="players"},
		{Title="Server",Hint="Server details and travel",Words="rejoin hop region",Tab="server"},
		{Title="Settings",Hint="Appearance, reduced motion and controls",Words="theme scale config sound credits",Tab="settings"},
		{Title="Murder Mystery 2",Hint="Find MM2 in your library",Words="mm2 sheriff murder",Tab="hub",Game="mm2"},
		{Title="Superhero Arena",Hint="Find Superhero Arena in your library",Words="heroes superhero",Tab="hub",Game="superhero-arena"},
		{Title="Survive The Hulk",Hint="Find Survive The Hulk in your library",Words="hulk survive",Tab="hub",Game="survive-the-hulk"},
	}
	local overlay=Kit.create("TextButton",{Name="QuickSearchOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=Kit.VOID,BackgroundTransparency=.22,BorderSizePixel=0,Text="",AutoButtonColor=false,Visible=false,ZIndex=30},ctx.Card)
	local panel=Kit.create("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,64),Size=UDim2.new(1,-40,1,-90),BackgroundColor3=Kit.BASE,BorderSizePixel=0,ZIndex=31,Active=true},overlay)
	Kit.create("UISizeConstraint",{MaxSize=Vector2.new(500,440)},panel)
	Kit.create("UICorner",{CornerRadius=UDim.new(0,12)},panel)
	Kit.create("UIStroke",{Color=Kit.BORDER,Thickness=1},panel)
	Kit.create("TextLabel",{Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-66,0,22),BackgroundTransparency=1,FontFace=Kit.face("BuilderSans",Enum.FontWeight.Bold),Text="Find your next move",TextSize=16,TextColor3=Kit.INK,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=32},panel)
	local close=Kit.create("TextButton",{Position=UDim2.new(1,-44,0,8),Size=UDim2.fromOffset(32,30),BackgroundTransparency=1,Text="×",TextSize=24,TextColor3=Kit.SUB,ZIndex=32},panel)
	local input=Kit.create("TextBox",{Position=UDim2.fromOffset(14,42),Size=UDim2.new(1,-28,0,38),BackgroundColor3=Kit.TRACK,BorderSizePixel=0,ClearTextOnFocus=false,Text="",PlaceholderText="Try fly, ESP, MM2, settings…",PlaceholderColor3=Kit.FAINT,FontFace=Kit.face("BuilderSans"),TextSize=13,TextColor3=Kit.INK,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=32},panel)
	Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},input)
	Kit.create("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,10)},input)
	local results=Kit.create("ScrollingFrame",{Position=UDim2.fromOffset(14,92),Size=UDim2.new(1,-28,1,-126),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=Kit.ACCENT,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=32},panel)
	Kit.create("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},results)
	Kit.create("TextLabel",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,16,1,-8),Size=UDim2.new(1,-32,0,18),BackgroundTransparency=1,Text="Enter opens the first result · Esc closes",TextSize=10,TextColor3=Kit.FAINT,FontFace=Kit.face("BuilderSans"),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=32},panel)
	local M,rows,first={}, {}, nil
	function M.Close() overlay.Visible=false; input:ReleaseFocus() end
	local function choose(command)
		M.Close(); Kit.Click(); ctx.SelectTab(command.Tab)
		if command.Game and ctx.LibraryFocus then ctx.LibraryFocus(command.Game) end
	end
	for index,command in ipairs(commands) do
		local btn=Kit.create("TextButton",{LayoutOrder=index,Size=UDim2.new(1,-4,0,46),BackgroundColor3=Kit.PANEL,AutoButtonColor=false,BorderSizePixel=0,Text="",ZIndex=33},results)
		Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},btn)
		Kit.create("TextLabel",{Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-24,0,18),BackgroundTransparency=1,Text=command.Title,TextSize=13,TextColor3=Kit.INK,FontFace=Kit.face("BuilderSans",Enum.FontWeight.Medium),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=34},btn)
		Kit.create("TextLabel",{Position=UDim2.fromOffset(12,25),Size=UDim2.new(1,-24,0,15),BackgroundTransparency=1,Text=command.Hint,TextSize=10,TextColor3=Kit.FAINT,FontFace=Kit.face("BuilderSans"),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=34},btn)
		rows[index]=btn
		ctx.Janitor.add(btn.Activated:Connect(function() choose(command) end))
		ctx.Janitor.add(btn.MouseEnter:Connect(function() Kit.tween(btn,{BackgroundColor3=Kit.TRACK},.1) end))
		ctx.Janitor.add(btn.MouseLeave:Connect(function() Kit.tween(btn,{BackgroundColor3=Kit.PANEL},.1) end))
	end
	local empty=Kit.create("TextLabel",{LayoutOrder=100,Size=UDim2.new(1,-4,0,50),BackgroundTransparency=1,Text="No matches. Try a section or game name.",TextWrapped=true,TextSize=12,TextColor3=Kit.SUB,FontFace=Kit.face("BuilderSans"),Visible=false,ZIndex=33},results)
	local function update()
		first=nil
		for index,command in ipairs(commands) do
			local haystack=(command.Title .. " " .. command.Hint .. " " .. command.Words):lower()
			local matches=true
			for word in input.Text:lower():gmatch("%S+") do if not haystack:find(word,1,true) then matches=false; break end end
			rows[index].Visible=matches
			if matches and not first then first=command end
		end
		empty.Visible=first==nil; results.CanvasPosition=Vector2.new(0,0)
	end
	function M.Open()
		if not ctx.IsVisible() then return end
		overlay.Visible=true; input.Text=""; update()
		-- Mobile keyboard is opened only when the user taps the search field.
		if not UserInputService.TouchEnabled then input:CaptureFocus() end
	end
	ctx.Janitor.add(close.Activated:Connect(M.Close))
	ctx.Janitor.add(overlay.Activated:Connect(M.Close))
	ctx.Janitor.add(input:GetPropertyChangedSignal("Text"):Connect(update))
	ctx.Janitor.add(input.FocusLost:Connect(function(enter) if overlay.Visible and enter and first then choose(first) end end))
	ctx.Janitor.add(UserInputService.InputBegan:Connect(function(key,processed)
		if overlay.Visible and key.KeyCode==Enum.KeyCode.Escape then M.Close(); return end
		if processed or UserInputService:GetFocusedTextBox() then return end
		if key.KeyCode==Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			if overlay.Visible then M.Close() else M.Open() end
		end
	end))
	return M
end
