// Generated by CoffeeScript 1.6.3
(function() {
  var M, Metronome, Theory, URL, audioContext, cancelAnimationFrame, d, initInstrument, instrument, makePromise, requestAnimationFrame, start, _d, _ref,
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

  _.mixin({
    accessors: function(obj, opts, preprocessCallback) {
      var gen, _ref1, _ref2;
      switch (arguments.length) {
        case 1:
          _ref1 = [
            {}, obj, function(val) {
              return val;
            }
          ], obj = _ref1[0], opts = _ref1[1], preprocessCallback = _ref1[2];
          break;
        case 2:
          if (_.isFunction(opts)) {
            _ref2 = [{}, obj, opts], obj = _ref2[0], opts = _ref2[1], preprocessCallback = _ref2[2];
          } else {
            preprocessCallback = function(val) {
              return val;
            };
          }
      }
      return gen = {
        add: function(props, onChange) {
          if (_.isString(props)) {
            props = [props];
          }
          props.forEach(function(opt) {
            if (preprocessCallback != null) {
              opts[opt] = preprocessCallback(opts[opt]);
            }
            return obj[opt] = function(val) {
              if (!arguments.length) {
                return opts[opt];
              }
              opts[opt] = preprocessCallback(val);
              if (typeof onChange === "function") {
                onChange();
              }
              return obj;
            };
          });
          return gen;
        },
        addAll: function(onChange) {
          return gen.add(_.keys(opts), onChange);
        },
        done: function() {
          return obj;
        }
      };
    }
  });

  requestAnimationFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(cb) {
    return setTimeout(cb, 16);
  };

  cancelAnimationFrame = window.cancelAnimationFrame || window.webkitCancelAnimationFrame || window.mozCancelAnimationFrame || window.oCancelAnimationFrame || window.msCancelAnimationFrame || function(num) {
    return clearTimeout(num);
  };

  URL = window.URL || window.webkitURL || window.mozURL || window.oURL || window.msURL;

  audioContext = window.audioContext || window.webkitAudioContext || window.mozAudioContext || window.oAudioContext || window.msAudioContext;

  Theory = {};

  (function() {
    var notes;
    notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    Theory.major = function(start) {
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
    Theory.noteNameForKey = function(key, number) {
      return notes[key % 12] + (number ? '' + Math.floor(key / 12) - 1 : '');
    };
    return Theory.timeBetweenNotes = function(bpm, noteSize) {
      return noteSize * 1000 / (bpm / 60);
    };
  })();

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
        if (d3.event.keyCode === 32) {
          return dispatch.keydown({
            key: (_ref1 = keys[down++]) != null ? _ref1 : 72,
            velocity: 50,
            time: performance.now(),
            event: null
          });
        }
      }).on('keyup.internal', function() {
        var _ref1;
        if (d3.event.keyCode === 32) {
          return dispatch.keyup({
            key: (_ref1 = keys[up++]) != null ? _ref1 : 72,
            time: performance.now(),
            event: null
          });
        }
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
    var arm, bpm, ex, exercise, exerciseVis, height, metronomeVis, noteDuration, pad, stop, vis, width, _ref1;
    d('Starting');
    exercise = _.flatten([Theory.major(60), Theory.major(72), 72 + 12, 72 + 12, Theory.major(72).reverse(), Theory.major(60).reverse()]).map(function(key, index, arr) {
      return {
        key: key,
        time: index,
        degree: index < arr.length / 2 ? index : (arr.length - index) - 1,
        hand: 'left'
      };
    });
    bpm = 120;
    noteDuration = 1;
    vis = d3.select('#exercise');
    _ref1 = vis.node().getBoundingClientRect(), width = _ref1.width, height = _ref1.height;
    height = 200;
    vis.attr({
      width: width,
      height: height + 150
    });
    pad = 40;
    metronomeVis = M.metronome().width(width).pad(pad).beats(exercise.length).bpm(bpm).vis(vis);
    metronomeVis();
    exerciseVis = M.exercise().width(width).height(height).pad(pad).bpm(bpm).noteDuration(noteDuration).vis(vis.append('g').attr('transform', 'translate(0, 100)'));
    ex = null;
    stop = function() {
      Metronome.stop();
      exerciseVis.stopTimeline();
      return ex.abort();
    };
    arm = function() {
      return ex = start(exercise, bpm, noteDuration).on('start', function(notes) {
        exerciseVis.startTimeline(notes[notes.length - 1].expectedAt);
        return Metronome.start(bpm);
      }).on('update', function(notes) {
        return exerciseVis.notes(notes);
      }).on('complete', function(notes) {
        stop();
        return d('Complete.');
      });
    };
    arm();
    key('a', function() {
      return stop();
    });
    return key('r', function() {
      stop();
      return arm();
    });
  });

  start = function(notes, bpm, noteDuration) {
    var data, dispatch, duration, endTimeout, findCorrespondingIndex, startTime;
    dispatch = d3.dispatch('start', 'update', 'complete');
    data = notes.map(function(note) {
      return {
        key: note.key,
        degree: note.degree,
        expectedAt: note.time * Theory.timeBetweenNotes(bpm, noteDuration),
        playedAt: null,
        name: Theory.noteNameForKey(note.key, true)
      };
    });
    startTime = null;
    instrument.on('keydown.notes', function(e) {
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
      d(note);
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
    instrument.emulateKeysWithKeyboard(notes.map(function(_arg) {
      var key;
      key = _arg.key;
      return key;
    }));
    duration = notes[notes.length - 1].time * Theory.timeBetweenNotes(bpm, noteDuration);
    endTimeout = setTimeout(function() {
      return dispatch.complete(data);
    }, duration * 2);
    dispatch.abort = function() {
      instrument.stopEmulatingKeys();
      instrument.on('keydown.notes', null);
      return clearTimeout(endTimeout);
    };
    _.defer(function() {
      return dispatch.update(data);
    });
    return dispatch;
  };

  M = {
    metronome: function() {
      var createElements, opts, render;
      opts = {
        beats: 50,
        width: 300,
        pad: 0,
        bpm: 120,
        vis: null
      };
      createElements = function() {
        var nome;
        if (opts.vis.select('.metronome').empty()) {
          nome = opts.vis.append('g').attr({
            "class": 'metronome'
          });
          nome.append('g').attr({
            "class": 'axis major'
          });
          return nome.append('g').attr({
            "class": 'axis minor'
          });
        }
      };
      render = function() {
        var beatRadius, beats, major, majors, minor, minors, nome, num, x, _i, _ref1;
        beats = [];
        majors = [];
        minors = [];
        for (num = _i = 0, _ref1 = opts.beats; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; num = 0 <= _ref1 ? ++_i : --_i) {
          beats.push({
            num: num
          });
          majors.push(num);
          if (num !== opts.beats - 1) {
            minors.push(num + 0.25);
            minors.push(num + 0.5);
            minors.push(num + 0.75);
          }
        }
        beatRadius = function(d, i) {
          if (i % 4) {
            return 2;
          } else {
            return 6;
          }
        };
        x = d3.scale.linear().domain([0, opts.beats - 1]).range([opts.pad, opts.width - opts.pad]);
        major = d3.svg.axis().scale(x).orient('bottom').tickValues(majors).tickSize(14);
        minor = d3.svg.axis().scale(x).orient('bottom').tickValues(minors).outerTickSize(0).innerTickSize(7);
        nome = opts.vis.select('.metronome');
        nome.select('.axis.major').call(major);
        return nome.select('.axis.minor').call(minor);
      };
      return _.accessors(render, opts).addAll().add('vis', createElements).done();
    },
    exercise: function() {
      var abs, createElements, max, min, opts, render;
      opts = {
        width: 500,
        height: 300,
        pad: 0,
        bpm: 120,
        noteDuration: 1,
        notes: [],
        vis: null
      };
      max = Math.max, min = Math.min, abs = Math.abs;
      createElements = function() {
        var notes, timeline, vis;
        vis = opts.vis;
        notes = vis.select('.notes');
        if (notes.empty()) {
          notes = vis.append('g').attr('class', 'notes');
          notes.append('g').attr('class', 'contours');
          return timeline = vis.append('line').attr({
            "class": 'timeline',
            x1: 0,
            y1: -9999,
            x2: 0,
            y2: 9999,
            stroke: 'transparent'
          });
        }
      };
      render = function() {
        var colorScale, data, enter, errorScale, noteHeight, noteWidth, notes, textY, update, x, y;
        data = opts.notes;
        data[0].instruction = 'Ascend 2 octaves';
        data[15].instruction = 'Descend 2 octaves';
        x = d3.scale.linear().domain(d3.extent(data, function(d) {
          return d.expectedAt;
        })).range([opts.pad, opts.width - opts.pad]);
        y = function() {
          return -75;
        };
        notes = opts.vis.select('.notes');
        update = notes.selectAll('.note').data(data);
        enter = update.enter().append('g').attr({
          "class": 'note',
          transform: function(d) {
            var _ref1;
            return "translate(" + (x((_ref1 = d.expectedAt) != null ? _ref1 : d.playedAt)) + ", " + (y(d.degree)) + ")";
          }
        });
        enter.append('rect').attr({
          "class": 'indicator',
          fill: '#fff',
          stroke: '#fff',
          x: 0
        });
        textY = 30;
        enter.append('text').attr({
          "class": 'name',
          y: textY,
          x: -1,
          fill: function(d) {
            if (d.instruction) {
              return '#fff';
            } else {
              return '#999';
            }
          }
        }).text(function(d) {
          if (d.name[0] === 'C') {
            return d.name;
          } else {
            return '';
          }
        });
        enter.append('text').attr({
          "class": 'instruction',
          y: textY + 20,
          x: -1,
          fill: '#fff'
        }).text(function(d) {
          var _ref1;
          return (_ref1 = d.instruction) != null ? _ref1 : '';
        });
        colorScale = d3.scale.linear().domain([-1000, 0, 1000]).range(['#ff0000', '#fff', '#009eff']).interpolate(d3.interpolateLab).clamp(true);
        noteHeight = 10;
        noteWidth = 3;
        errorScale = function(error) {
          return x(error) - x(0);
        };
        return update.select('.indicator').transition().ease('cubic-out').duration(0).attr({
          width: function(d) {
            if (d.error != null) {
              return abs(errorScale(d.error));
            } else {
              return noteWidth;
            }
          },
          height: noteHeight,
          x: function(d) {
            if (d.error != null) {
              return min(0, errorScale(d.error));
            } else {
              return 0;
            }
          },
          fill: function(d) {
            if (d.error != null) {
              return colorScale(d.error);
            } else {
              return '#fff';
            }
          },
          stroke: function(d) {
            if (d.error != null) {
              return colorScale(d.error);
            } else {
              return '#fff';
            }
          }
        });
      };
      render.startTimeline = function(duration) {
        var i, t, timeline, _i, _results;
        timeline = opts.vis.select('.timeline');
        timeline.attr({
          transform: "translate(" + opts.pad + ", 0)",
          stroke: '#fff'
        });
        t = timeline;
        _results = [];
        for (i = _i = 0; _i < 30; i = ++_i) {
          _results.push(t = t.transition().duration(500).delay(i * 500 - 25).ease('cubic-out').attr({
            transform: "translate(" + (opts.pad + (opts.width - opts.pad) / 30 * i) + ", 0)"
          }));
        }
        return _results;
      };
      render.stopTimeline = function() {
        var timeline;
        timeline = opts.vis.select('.timeline');
        return timeline.interrupt().attr({
          stroke: 'transparent'
        }).transition();
      };
      return _.accessors(render, opts).addAll().add('notes', render).add('vis', createElements).done();
    }
  };

}).call(this);
