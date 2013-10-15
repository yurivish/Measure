Metronome = do ->
	dispatch = d3.dispatch 'tick'
	audioContext = new AudioContext()
	active = false
	lookaheadTime = nextNoteTime = interval = null
	timeout = null

	volume = 0.2 # 05
	gainNode = audioContext.createGain()
	gainNode.connect(audioContext.destination)
	gainNode.gain.value = volume

	pitch = 440 # Can be an umber or a list of pitches
	index = 0

	dispatch.playNoteAt = (pitch, time) ->
		osc = audioContext.createOscillator()
		osc.connect(gainNode)
		
		osc.frequency.value = pitch

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
			nextNotePitch = switch
				when _.isNumber(pitch)
					pitch
				when index < pitch.length
					pitch[index++]
				else
					null
					
			if nextNotePitch
				dispatch.playNoteAt nextNotePitch, nextNoteTime
			nextNoteTime += interval
		if active then timeout = setTimeout schedule, Math.min(interval / 2, 200)

	dispatch.start = (bpm, pitches) ->
		pitch = pitches ? 440
		interval = 60 / bpm
		lookaheadTime = interval * 2
		nextNoteTime = audioContext.currentTime
		active = true
		schedule()

	dispatch.stop = ->
		active = false
		clearTimeout(timeout) if timeout?

	dispatch