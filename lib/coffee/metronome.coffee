Metronome = do ->
	dispatch = d3.dispatch 'tick'
	audioContext = new AudioContext()
	active = false
	lookaheadTime = nextNoteTime = interval = null
	timeout = null

	volume = 0.05
	gainNode = audioContext.createGain()
	gainNode.connect(audioContext.destination)
	gainNode.gain.value = volume

	start = 0
	notes = Theory.major(60)

	playNoteAt = (time) ->
		osc = audioContext.createOscillator()
		osc.connect(gainNode)
		# TODO:
		# osc.frequency.value = 660.0
		osc.frequency.value = Theory.pitchForKey(notes[start++ % notes.length])

		tickDuration = 1/10
		fadeDuration = 1/1000

		# Fade in and out
		gainNode.gain.setValueAtTime(0, time)
		gainNode.gain.linearRampToValueAtTime(volume, time + fadeDuration)
		gainNode.gain.linearRampToValueAtTime(0.0, time + tickDuration - fadeDuration)

		# Play the sound
		osc.noteOn(time)
		osc.noteOff(time + tickDuration)

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