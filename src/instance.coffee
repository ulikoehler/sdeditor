@LSC ?= {}

class @LSC.Instance
	constructor: (@initialName, @number, @env, @paper, @lsc) ->
		@name = initialName
		@selected = false
		@head = @paper.rect(0,0,0,0,5)
		@head.attr
			cursor:			"pointer"
			fill: 			"#999"
			"fill-opacity": 0
		@head.drag(@move, @drag, @drop)
		@head.hover(@hoverIn, @hoverOut)
		@head.dblclick(@edit)
		@head.mousedown(@select)
		@text = []
		@line = @paper.path("")
		@line.attr
			"stroke-dasharray":	"-"
		@foot = @paper.rect(0,0,0,0)
		@foot.attr
			"fill":	"black"
		@width = cfg.instance.width
	clearText: () =>
		#Clear all previous texts
		for text in @text
			text.remove()
	update: (@y, height) =>
		x = @lsc.numberX(@number)
		pad = cfg.instance.padding

		# draw as env or system object
		if @env
			@head.attr
				"stroke-dasharray":"--"
		else
			@head.attr
				"stroke-dasharray":""
		
		@head.update
			x: 			x - cfg.instance.head.width / 2
			y: 			y
			width: 		cfg.instance.head.width
			height: 	cfg.instance.head.height
		#Remove all previous texts
		@clearText()
		#
		# Render the text lines
		#
		lines = @name.match(/^.*([\n\r]+|$)/gm);
		# Calculate the height per line
		lineHeight = 10
		textAreaHeight = lineHeight * lines.length
		yOffset = y + 10
		for i in [0..lines.length-1]
			curY = yOffset + i * lineHeight
			curText = @paper.text(x, curY, lines[i])
			curText.dblclick(@edit)
			curText.mousedown(@select)
			@text.push(curText)
			
		lh = height - cfg.instance.foot.height - cfg.instance.head.height
		@line.update
			path: "M #{x},#{y + cfg.instance.head.height} v #{lh}"
		@foot.update
			x: 	x - cfg.instance.foot.width / 2
			y: 	y + cfg.instance.head.height + lh
			width: 		cfg.instance.foot.width
			height: 	cfg.instance.foot.height
	drag: (x, y, event) => #Start drag
		@clearText()
		#Remove the editor, if any
		if @editor
			@unedit()
	move: (dx, dy, x, y, event) => #Move (during drag)
		dst = @lsc.xNumber(LSC.pageX2RaphaelX(x))
		if dst != @number
			@lsc.moveInstance(@, dst)
	drop: (event) => 				#End drag
		# Clear old text and rerender
		@lsc.update()
	edit: (event) =>				#Edit name
		unless @editor?
			@editor = $("<textarea />").autosize()
			@editor.css
				left:			@lsc.numberX(@number) - cfg.instance.head.width / 2 + cfg.margin / 2
				top:			@y + cfg.margin / 2
				width:			cfg.instance.head.width - cfg.margin
				height:			cfg.instance.head.height - cfg.margin
			@editor.addClass("editor centered")
			@editor.appendTo("#workspace")
			
			@clearText()
			
			@editor.mousedown (e) -> e.stopPropagation()
			@editor.val(@name).focus().select().blur(@unedit)
			#Old code to exit editor if return pressed
			#.keypress (event) => @unedit() if event.keyCode == 13 and !event.ctrlKey
	unedit: (event) =>				# End name edit
		if @editor?
			return if @editor.val() == ""
			return if !cfg.regex.namepattern.test(@editor.val())
			
			#Trim the text
			val = @editor.val().trim()
			#val = val.replace(/\n/g, " xnl ")
			
			# Check if the name conflicts with another instance
			inst = @lsc.getInstanceByName(val)

			if inst? and inst.number != @number
				@editor.val(@name)
				@editor.css("background","yellow").focus()
				return
			@name = val
			
			@editor.remove()
			@editor = null
			@lsc.change()
			#Re-render
			@lsc.update()
	hoverIn: =>
		unless @selected
			@head.update
				"fill-opacity":	cfg.opacity.hover
	hoverOut: =>
		unless @selected
			@head.update
				"fill-opacity":	0
	select: (event) =>
		event?.stopPropagation?()
		unless @selected
			@lsc.clearSelection()
			@selected = true
			@head.update
				"fill-opacity":	cfg.opacity.selected
	unselect: =>
		@selected = false
		@head.update
			"fill-opacity":	0
	toJSON: => name: @name, number: @number, env: @env
	remove: =>
		@head.remove()
		@line.remove()
		@foot.remove()
		@clearText()
