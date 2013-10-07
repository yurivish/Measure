Metronome = do ->
	dispatch = d3.dispatch 'tick'
	audioContext = new AudioContext()
	active = false
	lookaheadTime = nextNoteTime = interval = null
	timeout = null

	gainNode = audioContext.createGain()
	gainNode.connect(audioContext.destination)
	gainNode.gain.value = 0.05

	playNoteAt = (time) ->
		osc = audioContext.createOscillator()
		osc.connect(gainNode)
		osc.frequency.tick = 660.0

		osc.noteOn(time)
		osc.noteOff(time + 0.1)

	schedule = ->
		while nextNoteTime <= audioContext.currentTime + lookaheadTime
			playNoteAt nextNoteTime
			nextNoteTime += interval
		if active then timeout = setTimeout schedule, Math.min(interval / 2, 200)

	dispatch.start = (bpm) ->
		interval = 60 / bpm
		lookaheadTime = interval * 2
		nextNoteTime = audioContext.currentTime
		active = true
		schedule()

	dispatch.stop = ->
		active = false
		clearTimeout(timeout) if timeout?

	dispatch