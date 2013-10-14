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

	seq = null
	index = 0

	playNoteAt = (time) ->
		osc = audioContext.createOscillator()
		osc.connect(gainNode)

		# For now don't play anything if there is no note, 
		if index < seq.notes.length and (key = seq.notes[index].key) != null
			osc.frequency.value = Theory.pitchForKey(key)

			tickDuration = 1/10
			fadeDuration = 1/1000

			# Fade in and out
			gainNode.gain.setValueAtTime(0, time)
			gainNode.gain.linearRampToValueAtTime(volume, time + fadeDuration)
			gainNode.gain.linearRampToValueAtTime(0.0, time + tickDuration - fadeDuration)

			# Play the sound
			osc.noteOn(time)
			osc.noteOff(time + tickDuration)
		index += seq.beatSize / seq.noteSize

	schedule = ->
		while nextNoteTime <= audioContext.currentTime + lookaheadTime
			playNoteAt nextNoteTime
			nextNoteTime += interval
		if active then timeout = setTimeout schedule, Math.min(interval / 2, 200)

	dispatch.start = (bpm, _seq) ->
		seq = _seq
		interval = 60 / bpm
		lookaheadTime = interval * 2
		nextNoteTime = audioContext.currentTime
		active = true
		schedule()

	dispatch.stop = ->
		active = false
		clearTimeout(timeout) if timeout?

	dispatch