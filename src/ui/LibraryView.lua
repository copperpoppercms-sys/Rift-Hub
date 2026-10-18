-- Searchable compact library; uses the existing guarded game handoff.
return function(panel, ctx)
	local Kit, state = ctx.Kit, ctx.LibraryState
	local scroller = Kit.Scroller(panel)
	local function text(parent, props)
		local defaults={BackgroundTransparency=1,FontFace=Kit.face("BuilderSans"),TextSize=12,TextColor3=Kit.SUB,TextXAlignment=Enum.TextXAlignment.Left}
		for key,value in pairs(props) do defaults[key]=value end
		return Kit.create("TextLabel",defaults,parent)
	end
	text(scroller,{LayoutOrder=1,Size=UDim2.new(1,0,0,28),FontFace=Kit.face("BuilderSans",Enum.FontWeight.Bold),TextSize=22,TextColor3=Kit.INK,Text="Your library"})
	text(scroller,{LayoutOrder=2,Size=UDim2.new(1,0,0,32),TextWrapped=true,Text="Your games, one place. Pin a favorite or jump into the game you’re playing."})
	if not ctx.GameLibrary or not state then
		text(scroller,{LayoutOrder=3,Size=UDim2.new(1,0,0,40),TextWrapped=true,Text="The library couldn’t load. Reopen Rift to try again."}); return
	end
	local library=ctx.GameLibrary(ctx)
	local query, filter, refresh = "", "All", nil
	local box,input=Kit.SearchBox(scroller,"Search games…",function(value) query=value; if refresh then refresh() end end)
	box.LayoutOrder=3; box.Size=UDim2.new(1,0,0,38)
	local bar=Kit.create("Frame",{LayoutOrder=4,Size=UDim2.new(1,0,0,34),BackgroundTransparency=1},scroller)
	Kit.create("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},bar)
	local filters={}
	for index,label in ipairs({"All","Favorites","This game"}) do
		local btn=Kit.create("TextButton",{LayoutOrder=index,Size=UDim2.fromOffset(label=="All" and 54 or 104,32),BackgroundColor3=Kit.TRACK,AutoButtonColor=false,BorderSizePixel=0,Text=label,FontFace=Kit.face("BuilderSans"),TextSize=12,TextColor3=Kit.SUB},bar)
		Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},btn); filters[label]=btn
		ctx.Janitor.add(btn.Activated:Connect(function() filter=label; refresh() end))
	end
	local count=text(scroller,{LayoutOrder=5,Size=UDim2.new(1,0,0,18),TextSize=11,Text=""})
	local cards=Kit.create("Frame",{Name="GameCards",LayoutOrder=6,Size=UDim2.new(1,0,0,156),BackgroundTransparency=1},scroller)
	local grid=Kit.create("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,CellSize=UDim2.new(1,0,0,156),CellPadding=UDim2.fromOffset(12,12),FillDirectionMaxCells=2},cards)
	local empty=text(scroller,{Name="EmptyLibrary",LayoutOrder=7,Size=UDim2.new(1,0,0,70),TextWrapped=true,Visible=false,Text="No games match. Try another search or choose All."})
	local tiles,visibleCount={},0
	local function resize()
		local width=cards.AbsoluteSize.X/math.max(ctx.Zoom.Scale,.01)
		local columns=state.Columns(width)
		grid.CellSize=UDim2.new(1/columns,columns==2 and -6 or 0,0,156)
		cards.Size=UDim2.new(1,0,0,math.max(0,math.ceil(visibleCount/columns)*168-12))
	end
	for _,item in ipairs(library.Games) do
		local tile=Kit.create("Frame",{Name=item.Id,Size=UDim2.fromOffset(320,156),BackgroundColor3=Kit.PANEL,BorderSizePixel=0},cards)
		Kit.create("UICorner",{CornerRadius=UDim.new(0,12)},tile)
		local rim=Kit.create("UIStroke",{Color=Kit.BORDER,Transparency=.25,Thickness=1},tile)
		Kit.Surface(tile)
		local image=Kit.create("ImageLabel",{Position=UDim2.fromOffset(14,14),Size=UDim2.fromOffset(40,40),BackgroundColor3=Kit.VOID,BorderSizePixel=0,Image=item.Thumbnail,ScaleType=Enum.ScaleType.Fit},tile)
		Kit.create("UICorner",{CornerRadius=UDim.new(0,9)},image); library.LoadIcon(item,image)
		text(tile,{Position=UDim2.fromOffset(66,13),Size=UDim2.new(1,-110,0,22),TextSize=13,TextColor3=Kit.INK,TextTruncate=Enum.TextTruncate.AtEnd,FontFace=Kit.face("BuilderSans",Enum.FontWeight.Medium),Text=item.Name})
		local current=state.IsCurrent(item)
		text(tile,{Position=UDim2.fromOffset(66,38),Size=UDim2.new(1,-114,0,16),TextSize=10,TextColor3=current and Kit.CANDLE or Kit.FAINT,Text=current and "●  YOU’RE PLAYING" or item.ScriptName})
		local favorite=Kit.create("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-8,0,10),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,Text="☆",TextColor3=Kit.SUB,TextSize=24,FontFace=Kit.face("BuilderSans"),AutoButtonColor=false},tile)
		local execute=Kit.create("TextButton",{Position=UDim2.fromOffset(14,68),Size=UDim2.fromOffset(100,34),BackgroundColor3=Kit.ACCENT,Text="Execute",TextColor3=Kit.INK,TextSize=12,FontFace=Kit.face("BuilderSans",Enum.FontWeight.Medium),BorderSizePixel=0,AutoButtonColor=false},tile)
		Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},execute)
		local note=text(tile,{Position=UDim2.fromOffset(14,115),Size=UDim2.new(1,-28,0,28),TextSize=10,TextWrapped=true,Text=item.Handoff})
		tiles[item.Id]={Tile=tile,Favorite=favorite}
		local loading=false
		ctx.Janitor.add(favorite.Activated:Connect(function()
			state.ToggleFavorite(item.Id); Kit.Click(); refresh()
			if not state.Saved then count.Text=count.Text .. " · saved for this session" end
		end))
		ctx.Janitor.add(execute.Activated:Connect(function()
			if loading then return end
			loading=true; execute.Text="Opening…"; Kit.Click()
			task.spawn(function()
				local ok,result=library.Execute(item)
				loading=false
				if tile.Parent then execute.Text="Execute"; if not ok then note.Text=tostring(result); note.TextColor3=Kit.DANGER end end
			end)
		end))
		ctx.Janitor.add(tile.MouseEnter:Connect(function() Kit.tween(rim,{Color=Kit.ACCENT,Transparency=.05},.14) end))
		ctx.Janitor.add(tile.MouseLeave:Connect(function() Kit.tween(rim,{Color=Kit.BORDER,Transparency=.25},.14) end))
	end
	refresh=function()
		local entries=state.Filter(library.Games,query,filter)
		visibleCount=#entries
		for id,entry in pairs(tiles) do
			entry.Tile.Visible=false
			entry.Favorite.Text=state.Favorites[id] and "★" or "☆"
			entry.Favorite.TextColor3=state.Favorites[id] and Kit.CANDLE or Kit.SUB
		end
		for index,item in ipairs(entries) do tiles[item.Id].Tile.Visible=true; tiles[item.Id].Tile.LayoutOrder=index end
		for label,btn in pairs(filters) do
			Kit.tween(btn,{BackgroundColor3=label==filter and Kit.ACCENT or Kit.TRACK,TextColor3=label==filter and Kit.INK or Kit.SUB},.12)
		end
		count.Text=string.format("%d game%s · %s",#entries,#entries==1 and "" or "s",state.LastGame and ("last opened: " .. state.LastGame:gsub("%-"," ")) or "ready when you are")
		empty.Visible=#entries==0; cards.Visible=#entries>0; resize()
	end
	ctx.LibraryFocus=function(id)
		filter="All"
		for _,item in ipairs(library.Games) do if item.Id==id then input.Text=item.ShortName or item.Name; query=input.Text; break end end
		refresh()
	end
	ctx.Janitor.add(cards:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	ctx.Janitor.add(ctx.Zoom:GetPropertyChangedSignal("Scale"):Connect(resize))
	refresh()
end
