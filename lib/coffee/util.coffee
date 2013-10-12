_d = d = console?.log.bind(console) ? ->

d3.selection.prototype.moveToFront = -> this.each -> this.parentNode.appendChild(this)
d3.selection.prototype.moveToBack = -> this.each -> this.parentNode.insertBefore this, this.parentNode.firstChild

_.mixin {
	accessors: (obj, opts, preprocessCallback) ->
		# Acceptable invocation patterns:
		# (opts)
		# (obj, opts)
		# (opts, preprocessCallback)
		# (obj, opts, preprocessCallback)
		switch arguments.length
			when 1
				[obj, opts, preprocessCallback] = [{ }, obj, (val) -> val]
			when 2
				if _.isFunction opts
					[obj, opts, preprocessCallback] = [{ }, obj, opts]
				else
					preprocessCallback = (val) -> val

		gen = {
			add: (props, onChange) ->
				props = [props] if _.isString props
				props.forEach (opt) ->
					if preprocessCallback? then opts[opt] = preprocessCallback opts[opt]
					obj[opt] = (val) ->
						return opts[opt] unless arguments.length
						opts[opt] = preprocessCallback val
						onChange?()
						obj
				gen
			addAll: (onChange) -> gen.add _.keys(opts), onChange
			done: -> obj
		}
}
# We use MIDI receivedTime instead; it's as precise as performance time but in seconds fom 1970.
# performance ?= { }
# performance.now = 
# 	performance.now or
# 	performance.webkitNow or
# 	performance.msNow or
# 	performance.oNow or
# 	performance.mozNow or
# 	Date.now
	
requestAnimationFrame = window.requestAnimationFrame or
	window.webkitRequestAnimationFrame or
	window.mozRequestAnimationFrame or
	window.oRequestAnimationFrame or
	window.msRequestAnimationFrame or
	(cb) -> setTimeout(cb, 16)

cancelAnimationFrame = window.cancelAnimationFrame or
	window.webkitCancelAnimationFrame or
	window.mozCancelAnimationFrame or
	window.oCancelAnimationFrame or
	window.msCancelAnimationFrame or
	(num) -> clearTimeout(num)

URL = window.URL or
	window.webkitURL or
	window.mozURL or
	window.oURL or
	window.msURL

audioContext = window.audioContext or
	window.webkitAudioContext or
	window.mozAudioContext or
	window.oAudioContext or
	window.msAudioContext

