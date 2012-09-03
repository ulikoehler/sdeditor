@LSC ?= {}

class @LSC.Message
	constructor: (@name, @source, @target, @location, @lsc) ->
		@selected = false
		@rect = @lsc.paper.rect(0, 0, 0, 0, 5)
		@rect.attr
			stroke: 			"none"
			fill: 				"#999"
			opacity: 			0
			cursor:				"pointer"
		@arrow = @lsc.paper.path("")
		@arrow.attr
			"stroke-width": 	2
			stroke: 			"black"
			cursor: 			"pointer"
		@arrow.hover(@hoverIn, @hoverOut)
		@text = []
		@rect.hover(@hoverIn, @hoverOut)
		@arrow.drag(@move, @drag, @drop)
		@rect.drag(@move, @drag, @drop)
		@rect.mousedown(@select)
		@arrow.mousedown(@select)
		# Add context menu to raphael
		$(@rect.node).contextMenu({menu: "messageMenu"}, @contextMenuHandler)
	contextMenuHandler: (action, el, pos) =>
		if action == "edit"
			@edit()
		else if action == "delete"
			@remove()
	clearText: () =>
		#Clear all previous texts
		for text in @text
			text.remove()
	hoverIn: =>
		unless @selected
			@rect.update
				opacity: cfg.opacity.hover
	hoverOut: =>
		unless @selected
			@rect.update
				opacity: 0
	select: (event) =>
		event?.stopPropagation?()
		unless @selected
			@lsc.clearSelection()
			@selected = true
			@rect.update
				opacity: cfg.opacity.selected
	unselect: =>
		@selected = false
		@rect.update
			opacity: 0
	update: =>
		y = @lsc.locationY(@location)
		xs = @lsc.numberX(@source.number)
		xt = @lsc.numberX(@target.number)
		arrowWidth = cfg.arrow.width
		arrowHeight = cfg.arrow.height
		width = Math.abs(xs - xt)
		#Calculate the coordinates of the path
		selfLoop = false
		if xs < xt
			p = "M #{xs},#{y} h #{xt - xs - arrowWidth} l 0,#{arrowHeight} #{arrowWidth},-#{arrowHeight} -#{arrowWidth},-#{arrowHeight} 0,#{arrowHeight}"
			tx = xs + cfg.instance.width / 2
		else if xs == xt # self-looping message
			selfLoop = true
			p = "M #{xs},#{y} h #{cfg.instance.padding} v #{cfg.instance.selfLoopHeight} h #{-cfg.instance.padding+arrowWidth} l 0,#{arrowHeight} -#{arrowWidth},-#{arrowHeight} #{arrowWidth},-#{arrowHeight} 0,#{arrowHeight}"
			tx = xs + 2*cfg.margin
			width = cfg.instance.padding
		else
			p = "M #{xs},#{y} h -#{xs - xt - arrowWidth} l 0,#{arrowHeight} -#{arrowWidth},-#{arrowHeight} #{arrowWidth},-#{arrowHeight} 0,#{arrowHeight}"
			tx = xs - cfg.instance.width / 2
			
		
		@arrow.update
				path: p
				
		#Hide previous texts
		@clearText()
		#
		# Render the text lines
		#
		lines = @name.match(/^.*([\n\r]+|$)/gm);
		# Calculate the height per line
		lineHeight = 18
		textAreaHeight = lineHeight * lines.length
		yOffset = y - 10
		#Leave more space for self loops
		#Render self loop texts on the right side
		if selfLoop
			lineHeight -= 4
			tx += 22
			yOffset = y + cfg.instance.selfLoopHeight / 2 - 1
		for i in [0..lines.length-1]
			curY = yOffset + i * lineHeight
			curText = @lsc.paper.text(tx, curY, lines[i])
			curText.hover(@hoverIn, @hoverOut)
			curText.drag(@move, @drag, @drop)
			curText.mousedown(@select)
			curText.dblclick(@edit)
			@text.push(curText)
		
		@rect.update
			x: Math.min(xs, xt) - cfg.margin
			y: y - (cfg.location.height - cfg.margin) / 2 - 10 / 2
			width: width + 2 * cfg.margin
			height: cfg.location.height - cfg.margin
	drag: (x, y, event) => 			#Start drag
	move: (dx, dy, x, y, event) => 	#Move (during drag)
		dst = @lsc.GetLocation(LSC.pageY2RaphaelY(y))
		if dst != @location
			@lsc.moveMessage(@, dst)
	drop: (event) => 				#End drag
		@clearText()
		@lsc.update()
	edit: (event) => #Edit name
		unless @editor?
			xs = @lsc.numberX(@source.number)
			xt = @lsc.numberX(@target.number)
			if xs < xt
				x = xs + cfg.arrow.width
			# if self-looping message
			if xs == xt
				x = xs - cfg.instance.width/2 + 3*cfg.margin
			if xs > xt
				x = xs - cfg.instance.width + cfg.arrow.width
			@editor = $("<textarea />").autosize()
			@editor.css
				left:			x
				top:			@lsc.locationY(@location) - cfg.margin - 10
				width:			cfg.instance.width - cfg.arrow.width * 2
				height:			12
			@editor.addClass("editor centered")
			@editor.appendTo("#workspace")
			#Clear all previous texts
			@clearText()
			
			@editor.mousedown (e) -> e.stopPropagation()
			@editor.val(@name).focus().select().blur(@unedit)
			# Old code to stop editing on enter
			# keypress (event) => @unedit() if event.keyCode == 13
	unedit: (event) =>				#End edit
		if @editor?
			#Trim the text
			val = @editor.val().trim()
			#Hide previous texts
			@clearText()
			
			@name = val
			
			@editor.remove()
			@editor = null
			#Re-render
			@lsc.update()
	toJSON: => name: @name, location: @location, source: @source.name, target: @target.name
	remove: =>
		@clearText()
		@rect.remove()
		@arrow.remove()

