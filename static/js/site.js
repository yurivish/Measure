// Generated by CoffeeScript 1.6.3
(function() {
  var Metronome, Theory, URL, Visualizer, audioContext, cancelAnimationFrame, d, initInstrument, instrument, major, makePromise, notes, requestAnimationFrame, start, _d, _ref,
    __slice = [].slice;

  _d = d = (_ref = typeof console !== "undefined" && console !== null ? console.log.bind(console) : void 0) != null ? _ref : function() {};

  d3.selection.prototype.moveToFront = function() {
    return this.each(function() {
      return this.parentNode.appendChild(this);
    });
  };

  d3.selection.prototype.moveToBack = function() {
    return this.each(function() {
      return this.parentNode.insertBefore(this, this.parentNode.firstChild);
    });
  };

  requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(cb) {
    return setTimeout(cb, 16);
  };

  cancelAnimationFrame = window.cancelAnimationFrame || window.webkitCancelAnimationFrame || window.mozCancelAnimationFrame || window.oCancelAnimationFrame || window.msCancelAnimationFrame || function(num) {
    return clearTimeout(num);
  };

  URL = window.URL || window.webkitURL || window.mozURL || window.oURL || window.msURL;

  audioContext = window.audioContext || window.webkitAudioContext || window.mozAudioContext || window.oAudioContext || window.msAudioContext;

  Theory = function() {};

  notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  major = function(start) {
    var incs, offsets;
    incs = [0, 2, 2, 1, 2, 2, 2];
    offsets = (function(note) {
      var inc, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = incs.length; _i < _len; _i++) {
        inc = incs[_i];
        _results.push(note += inc);
      }
      return _results;
    })(0);
    return offsets.map(function(offset) {
      return start + offset;
    });
  };

  makePromise = function(fn) {
    var defer;
    defer = Q.defer();
    fn(defer);
    return defer.promise;
  };

  initInstrument = function() {
    var dispatch, fulfillWhen, tag;
    dispatch = d3.dispatch('ready', 'keydown', 'keyup', 'error');
    navigator.requestMIDIAccess().then(function(midi) {
      var inputs;
      inputs = midi.inputs();
      if (inputs.length) {
        inputs[0].onmidimessage = function(e) {
          var cmd, key, velocity, _ref1;
          _ref1 = e.data, cmd = _ref1[0], key = _ref1[1], velocity = _ref1[2];
          if (cmd === 144 && velocity > 0) {
            d('Key down:', key);
            return dispatch.keydown({
              key: key,
              velocity: velocity,
              time: e.receivedTime,
              event: e
            });
          } else if (cmd === 128 || (cmd === 144 && velocity === 0)) {
            return dispatch.keyup({
              key: key,
              time: e.receivedTime,
              event: e
            });
          }
        };
        d('Ready:', inputs[0]);
        return dispatch.ready(dispatch, inputs[0]);
      } else {
        return dispatch.error(true, null);
      }
    }, function(err) {
      return dispatch.error(false, err);
    });
    tag = (function() {
      var next;
      next = 0;
      return function(type) {
        return type + '.internal_' + next++;
      };
    })();
    fulfillWhen = function(defer, type, condition) {
      type = tag(type);
      return dispatch.on(type, function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (condition.apply(null, args)) {
          defer.resolve();
          return dispatch.on(type, null);
        }
      });
    };
    dispatch.emulateKeysWithKeyboard = function(keys) {
      var down, up;
      up = down = 0;
      return d3.select(document).on('keydown.internal', function() {
        var _ref1;
        return dispatch.keydown({
          key: (_ref1 = keys[down++]) != null ? _ref1 : 72,
          velocity: 50,
          time: performance.now(),
          event: null
        });
      }).on('keyup.internal', function() {
        var _ref1;
        return dispatch.keyup({
          key: (_ref1 = keys[up++]) != null ? _ref1 : 72,
          time: performance.now(),
          event: null
        });
      });
    };
    dispatch.stopEmulatingKeys = function() {
      return d3.select(document).on('keydown.internal', null).on('keyup.internal', null);
    };
    dispatch.watch = function(name, listener) {
      var id;
      id = tag(name);
      dispatch.on(id, listener);
      return id;
    };
    dispatch.unwatch = function(id) {
      return dispatch.on(id, null);
    };
    dispatch.watchOnce = function(name, listener) {
      var id;
      id = instrument.watch(name, function(e) {
        listener(e);
        return dispatch.unwatch(id);
      });
      return id;
    };
    dispatch.waitForPress = function(key) {
      d('waiting for', key);
      return makePromise(function(defer) {
        return fulfillWhen(defer, 'keydown', function(e) {
          return e.key === key;
        });
      });
    };
    return dispatch;
  };

  Metronome = (function() {
    var active, dispatch, gainNode, interval, lookaheadTime, nextNoteTime, playNoteAt, schedule, timeout;
    dispatch = d3.dispatch('tick');
    audioContext = new AudioContext();
    active = false;
    lookaheadTime = nextNoteTime = interval = null;
    timeout = null;
    gainNode = audioContext.createGain();
    gainNode.connect(audioContext.destination);
    gainNode.gain.value = 0.05;
    playNoteAt = function(time) {
      var osc;
      osc = audioContext.createOscillator();
      osc.connect(gainNode);
      osc.frequency.tick = 660.0;
      osc.noteOn(time);
      return osc.noteOff(time + 0.1);
    };
    schedule = function() {
      while (nextNoteTime <= audioContext.currentTime + lookaheadTime) {
        playNoteAt(nextNoteTime);
        nextNoteTime += interval;
      }
      if (active) {
        return timeout = setTimeout(schedule, Math.min(interval / 2, 200));
      }
    };
    dispatch.start = function(bpm) {
      interval = 60 / bpm;
      lookaheadTime = interval * 2;
      nextNoteTime = audioContext.currentTime;
      active = true;
      return schedule();
    };
    dispatch.stop = function() {
      active = false;
      if (timeout != null) {
        return clearTimeout(timeout);
      }
    };
    return dispatch;
  })();

  instrument = initInstrument();

  _.defer(function() {
    var exercise, opts, visualizer;
    d('Starting');
    exercise = _.flatten([major(60), major(72), 72 + 12, major(72).reverse(), major(60).reverse()]).map(function(key, index) {
      return {
        key: key,
        time: index,
        hand: 'left'
      };
    });
    opts = (function(bpm) {
      return {
        bpm: bpm,
        noteInterval: 1000 / (bpm / 60)
      };
    })(120);
    (function() {
      var beatRadius, beats, bpm, height, nome, num, numBeats, pad, pos, update, vis, width, _ref1;
      vis = d3.select('#exercise');
      _ref1 = vis.node().getBoundingClientRect(), width = _ref1.width, height = _ref1.height;
      vis.attr({
        width: width,
        height: height
      });
      nome = vis.append('g').attr({
        "class": 'metronome'
      });
      bpm = 120;
      numBeats = 49;
      beats = (function() {
        var _i, _results;
        _results = [];
        for (num = _i = 0; 0 <= numBeats ? _i < numBeats : _i > numBeats; num = 0 <= numBeats ? ++_i : --_i) {
          _results.push({
            num: num
          });
        }
        return _results;
      })();
      pad = 40 + 6;
      pos = d3.scale.linear().domain([0, 35]).range([pad, width - pad]);
      update = nome.selectAll('.beat').data(beats);
      beatRadius = function(d, i) {
        if (i % 4) {
          return 2;
        } else {
          return 6;
        }
      };
      update.enter().append('circle').attr({
        "class": 'beat',
        cx: function(d) {
          return pos(d.num);
        },
        r: beatRadius,
        cy: 25,
        fill: '#999',
        opacity: 1e-6
      });
      update.transition().delay(function(d, i) {
        return i * 20;
      }).duration(500).ease('ease-out-expo').attr({
        r: beatRadius,
        opacity: 1
      });
      return update.exit().remove();
    })();
    /*
    */

    visualizer = Visualizer(d3.select('#notes').append('g').attr('transform', 'translate(50, 50)'), {
      width: 900,
      height: 400
    });
    return start(exercise, opts).on('start', function(data) {
      return visualizer.playTimeline(data[data.length - 1].expectedAt);
    }).on('update', function(data) {
      return visualizer(data);
    }).on('complete', function(data) {
      return d('Complete.');
    });
  });

  start = function(exercise, opts) {
    var data, dispatch, duration, endTimeout, findCorrespondingIndex, startTime;
    dispatch = d3.dispatch('start', 'update', 'complete');
    data = exercise.map(function(note) {
      return {
        key: note.key,
        expectedAt: note.time * opts.noteInterval,
        playedAt: null
      };
    });
    startTime = null;
    instrument.on('keydown.exercise', function(e) {
      var index, note, time;
      if (startTime == null) {
        startTime = e.time;
        dispatch.start(data);
      }
      time = e.time - startTime;
      index = findCorrespondingIndex(e.key, time);
      if (index != null) {
        note = data[index];
        note.playedAt = time;
        note.error = note.playedAt - note.expectedAt;
      } else {
        data.push({
          key: e.key,
          expectedAt: null,
          playedAt: time
        });
      }
      d(index);
      return dispatch.update(data);
    });
    findCorrespondingIndex = function(key, time) {
      var index, note, timeWindow, _i, _len;
      timeWindow = 2000;
      for (index = _i = 0, _len = data.length; _i < _len; index = ++_i) {
        note = data[index];
        if (note.key === key && (note.expectedAt != null) && (note.playedAt == null) && Math.abs(note.expectedAt - time) < timeWindow) {
          return index;
        }
      }
      return null;
    };
    instrument.emulateKeysWithKeyboard(exercise.map(function(_arg) {
      var key;
      key = _arg.key;
      return key;
    }));
    duration = (exercise[exercise.length - 1].time + 1) * opts.noteInterval;
    endTimeout = setTimeout(function() {
      return dispatch.complete(data);
    }, duration);
    dispatch.abort = function() {
      instrument.stopEmulatingKeys();
      instrument.on('keydown.exercise', null);
      return clearTimeout(endTimeout);
    };
    _.defer(function() {
      return dispatch.update(data);
    });
    return dispatch;
  };

  Visualizer = function(parent, opts) {
    var abs, defaultNoteRadius, height, max, min, timeline, visualize, width, _ref1;
    parent.append('g').attr({
      "class": 'notes'
    });
    timeline = parent.append('line').attr({
      "class": 'timeline',
      x1: 0,
      y1: -9999,
      x2: 0,
      y2: 9999,
      stroke: 'transparent'
    });
    _ref1 = _.extend(opts, {
      defaultNoteRadius: 3
    }), width = _ref1.width, height = _ref1.height, defaultNoteRadius = _ref1.defaultNoteRadius;
    max = Math.max, min = Math.min, abs = Math.abs;
    visualize = function(data) {
      var colorScale, enter, errorScale, update, x, y;
      x = d3.scale.linear().domain(d3.extent(data, function(d) {
        return d.expectedAt;
      })).range([0, width]);
      y = d3.scale.linear().domain(d3.extent(data, function(d) {
        return d.key;
      })).range([height, 0]);
      update = parent.select('.notes').selectAll('.note').data(data);
      enter = update.enter().append('g').attr({
        "class": 'note',
        transform: function(d) {
          var _ref2;
          return "translate(" + (x((_ref2 = d.expectedAt) != null ? _ref2 : d.playedAt)) + ", " + (y(d.key)) + ")";
        }
      });
      enter.append('circle').attr({
        "class": 'indicator',
        r: defaultNoteRadius,
        fill: '#fff'
      });
      colorScale = d3.scale.linear().domain([-1000, 0, 1000]).range(['#ff0000', '#fff', '#009eff']).interpolate(d3.interpolateLab).clamp(true);
      errorScale = function(error) {
        return max(abs(x(error)), 3);
      };
      return update.select('circle').transition().ease('cubic-out').duration(200).attr({
        r: function(d) {
          _d(d.error);
          if (d.error != null) {
            return errorScale(d.error);
          } else {
            return defaultNoteRadius;
          }
        },
        fill: function(d) {
          if (d.error != null) {
            return colorScale(d.error);
          } else {
            return '#fff';
          }
        }
      });
    };
    visualize.playTimeline = function(duration) {
      timeline.attr({
        transform: '',
        stroke: '#fff'
      });
      return timeline.transition().duration(duration).ease('linear').attr({
        transform: "translate(" + width + ", 0)"
      });
    };
    visualize.stopTimeline = function() {
      return timeline.attr({
        stroke: 'transparent'
      });
    };
    return visualize;
  };

}).call(this);
