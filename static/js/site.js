// Generated by CoffeeScript 1.6.3
(function() {
  var M, Metronome, Theory, URL, audioContext, cancelAnimationFrame, d, initInstrument, instrument, makePromise, requestAnimationFrame, _d, _ref,
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
    var notes, pitches;
    notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    pitches = [16.352, 17.324, 18.354, 19.445, 20.602, 21.827, 23.125, 24.500, 25.957, 27.500, 29.135, 30.868, 32.703, 34.648, 36.708, 38.891, 41.203, 43.654, 46.249, 48.999, 51.913, 55.000, 58.270, 61.735, 65.406, 69.296, 73.416, 77.782, 82.407, 87.307, 92.499, 97.999, 103.83, 110.00, 116.54, 123.47, 130.81, 138.59, 146.83, 155.56, 164.81, 174.61, 185.00, 196.00, 207.65, 220.00, 233.08, 246.94, 261.63, 277.18, 293.66, 311.13, 329.63, 349.23, 369.99, 392.00, 415.30, 440.00, 466.16, 493.88, 523.25, 554.37, 587.33, 622.25, 659.26, 698.46, 739.99, 783.99, 830.61, 880.00, 932.33, 987.77, 1046.5, 1108.7, 1174.7, 1244.5, 1318.5, 1396.9, 1480.0, 1568.0, 1661.2, 1760.0, 1864.7, 1975.5, 2093.0, 2217.5, 2349.3, 2489.0, 2637.0, 2793.8, 2960.0, 3136.0, 3322.4, 3520.0, 3729.3, 3951.1, 4186.0, 4434.9, 4698.6, 4978.0, 5274.0, 5587.7, 5919.9, 6271.9, 6644.9, 7040.0, 7458.6, 7902.1];
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
    Theory.pitchForKey = function(key) {
      return pitches[key - 12];
    };
    Theory.nameForKey = function(key, withNumber) {
      return notes[key % 12] + (withNumber ? '' + Math.floor(key / 12) - 1 : '');
    };
    return Theory.notes = notes;
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
      d(inputs);
      if (inputs.length) {
        inputs[0].onmidimessage = function(e) {
          var cmd, key, velocity, _ref1;
          _ref1 = e.data, cmd = _ref1[0], key = _ref1[1], velocity = _ref1[2];
          if (cmd === 144 && velocity > 0) {
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
      return makePromise(function(defer) {
        return fulfillWhen(defer, 'keydown', function(e) {
          return e.key === key;
        });
      });
    };
    return dispatch;
  };

  Metronome = (function() {
    var active, dispatch, gainNode, index, interval, lookaheadTime, nextNoteTime, pitch, schedule, timeout, volume;
    dispatch = d3.dispatch('tick');
    audioContext = new AudioContext();
    active = false;
    lookaheadTime = nextNoteTime = interval = null;
    timeout = null;
    volume = 0.2;
    gainNode = audioContext.createGain();
    gainNode.connect(audioContext.destination);
    gainNode.gain.value = volume;
    pitch = 440;
    index = 0;
    dispatch.playNoteAt = function(pitch, time) {
      var fadeDuration, osc, tickDuration;
      osc = audioContext.createOscillator();
      osc.connect(gainNode);
      osc.frequency.value = pitch;
      tickDuration = 1 / 10;
      fadeDuration = 1 / 1000;
      gainNode.gain.setValueAtTime(0, time);
      gainNode.gain.linearRampToValueAtTime(volume, time + fadeDuration);
      gainNode.gain.linearRampToValueAtTime(0.0, time + tickDuration - fadeDuration);
      osc.noteOn(time);
      return osc.noteOff(time + tickDuration);
    };
    schedule = function() {
      var nextNotePitch;
      while (nextNoteTime <= audioContext.currentTime + lookaheadTime) {
        nextNotePitch = (function() {
          switch (false) {
            case !_.isNumber(pitch):
              return pitch;
            case !(index < pitch.length):
              return pitch[index++];
            default:
              return null;
          }
        })();
        if (nextNotePitch) {
          dispatch.playNoteAt(nextNotePitch, nextNoteTime);
        }
        nextNoteTime += interval;
      }
      if (active) {
        return timeout = setTimeout(schedule, Math.min(interval / 2, 200));
      }
    };
    dispatch.start = function(bpm, pitches) {
      pitch = pitches != null ? pitches : 440;
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
    var go, rnote, rseq;
    d('Initializing key exercise.');
    rnote = function() {
      return Theory.notes[~~(12 * Math.random())];
    };
    rseq = function(n) {
      var note, seq;
      seq = [rnote()];
      while (seq.length < n) {
        note = rnote();
        if (note !== seq[seq.length - 1]) {
          seq.push(note);
        }
      }
      return seq;
    };
    go = function() {
      var key, play, waitForKey;
      d('waiting for', name);
      key = 60 + _.indexOf(Theory.notes, name);
      Metronome.playNoteAt(Theory.pitchForKey(key), 0);
      waitForKey = function(expected) {
        return makePromise(function(defer) {
          return instrument.watchOnce('keydown', function(e) {
            var pressed;
            pressed = Theory.nameForKey(e.key);
            if (pressed === expected) {
              return defer.resolve(pressed);
            } else {
              d('Rejecting');
              return defer.reject([expected, pressed]);
            }
          });
        });
      };
      play = function(seq) {
        var name, p, _fn, _i, _len, _ref1;
        d.apply(null, ['Play'].concat(__slice.call(seq)));
        p = waitForKey(seq[0]);
        _ref1 = seq.slice(1);
        _fn = function(name) {
          return p = p.then(function(pressed) {
            d(pressed + '...');
            return waitForKey(name);
          });
        };
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          name = _ref1[_i];
          _fn(name);
        }
        return p.then(function(pressed) {
          d('%cSUCCESS!', 'color: #00b600; font-weight: bold;');
          return play(rseq(seq.length));
        }, function(_arg) {
          var expected, pressed;
          pressed = _arg[0], expected = _arg[1];
          d("%cWRONG! " + pressed + " != " + expected + ".", 'font-weight: bold; color: #ff0012');
          return play(seq);
        });
      };
      return play(rseq(3));
    };
    return go();
  });

  (function() {
    var loadSequence, sequence, start, vis, width;
    d('Starting');
    vis = d3.select('#piece');
    width = window.innerWidth;
    vis.attr({
      width: width,
      height: 200
    });
    sequence = {
      notes: _.flatten([Theory.major(60), Theory.major(72), 72 + 12, null, 72 + 12, Theory.major(72).reverse(), Theory.major(60).reverse()]).map(function(key, index) {
        return {
          key: key,
          index: index
        };
      }),
      annotations: [
        {
          from: 0,
          to: 14,
          text: 'Ascend'
        }, {
          from: 15,
          to: 15,
          rest: true
        }, {
          from: 16,
          to: 30,
          text: 'Descend'
        }
      ],
      beatsPerMeasure: 4,
      beatSize: 0.25,
      noteSize: 0.125
    };
    sequence.beats = Math.ceil(sequence.notes.length * (sequence.noteSize / sequence.beatSize));
    loadSequence = function(seq) {
      var bpm, errorVis, pad, sequenceVis, timeVis;
      pad = 40;
      bpm = 120;
      timeVis = M.time().beats(seq.beats).beatSize(seq.beatSize).noteSize(seq.noteSize).bpm(bpm).width(width).pad(pad).vis(vis.append('g').attr('class', 'time-vis'));
      timeVis();
      errorVis = M.error().width(width).pad(pad).bpm(bpm).vis(vis.append('g').attr('class', 'error-vis')).seq(seq);
      sequenceVis = M.sequence().width(width).pad(pad).bpm(bpm).vis(vis.append('g').attr('class', 'seq-vis')).seq(seq);
      sequenceVis();
      return start(seq, bpm).on('start', function() {
        var note, pitches;
        pitches = (function() {
          var _i, _len, _ref1, _ref2, _results;
          _ref2 = seq.notes;
          _ref1 = seq.beatSize / seq.noteSize;
          _results = [];
          for ((_ref1 > 0 ? (_i = 0, _len = _ref2.length) : _i = _ref2.length - 1); _ref1 > 0 ? _i < _len : _i >= 0; _i += _ref1) {
            note = _ref2[_i];
            _results.push(Theory.pitchForKey(note.key));
          }
          return _results;
        })();
        return Metronome.start(120, pitches);
      }).on('update', function(played) {
        return errorVis.played(played);
      }).on('end', function() {
        return Metronome.stop();
      });
    };
    _.defer(function() {
      return loadSequence(sequence);
    });
    return start = function(seq, bpm) {
      var alreadyPlayed, checkForEnd, dispatch, findCorrespondingIndex, noteIndexToBeatTime, noteIndexToTime, played, startTime;
      dispatch = d3.dispatch('start', 'update', 'end');
      played = [];
      alreadyPlayed = {};
      noteIndexToBeatTime = d3.scale.linear().domain([0, seq.notes.length]).range([0, seq.notes.length * seq.noteSize]);
      noteIndexToTime = d3.scale.linear().domain([0, seq.notes.length]).range([0, (1 / bpm) * 60 * 1000 * seq.notes.length * seq.noteSize / seq.beatSize]);
      startTime = null;
      checkForEnd = null;
      instrument.on('keydown.notes', function(e) {
        var errorBeats, errorMs, expectedBeats, expectedMs, index, note, playedBeats, playedMs, startDateTime, time;
        if (startTime == null) {
          dispatch.start();
          startTime = e.time;
          startDateTime = Date.now();
          checkForEnd = setInterval(function() {
            if (noteIndexToTime.invert(Date.now() - startDateTime) > seq.notes.length - 1) {
              dispatch.abort();
              return dispatch.end();
            }
          }, 250);
        }
        time = e.time - startTime;
        index = findCorrespondingIndex(e.key, time);
        if (index != null) {
          alreadyPlayed[index] = true;
          note = seq.notes[index];
          expectedMs = noteIndexToTime(note.index);
          expectedBeats = noteIndexToBeatTime(note.index);
          playedMs = time;
          playedBeats = noteIndexToBeatTime(noteIndexToTime.invert(time));
          errorMs = playedMs - expectedMs;
          errorBeats = playedBeats - expectedBeats;
          d(errorMs);
          played.push({
            key: e.key,
            expectedMs: expectedMs,
            expectedBeats: expectedBeats,
            playedMs: playedMs,
            playedBeats: playedBeats,
            errorMs: errorMs,
            errorBeats: errorBeats
          });
        } else {
          0;
        }
        return dispatch.update(played);
      });
      findCorrespondingIndex = function(key, time) {
        var note, timeWindow, _i, _len, _ref1;
        timeWindow = 2000;
        _ref1 = seq.notes;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          note = _ref1[_i];
          if (note.index in alreadyPlayed) {
            continue;
          } else if (note.key === key && Math.abs(noteIndexToTime(note.index) - time) < timeWindow) {
            d(noteIndexToTime(note.index));
            return note.index;
          }
        }
        return null;
      };
      instrument.emulateKeysWithKeyboard(seq.notes.map(function(_arg) {
        var key;
        key = _arg.key;
        return key;
      }));
      dispatch.abort = function() {
        instrument.stopEmulatingKeys();
        instrument.on('keydown.notes', null);
        return clearInterval(checkForEnd);
      };
      _.defer(function() {
        return dispatch.update(played);
      });
      return dispatch;
    };
  });

  M = {
    noteTop: 45,
    noteHeight: 15,
    minorTickSize: 7,
    majorTickSize: 14,
    time: function() {
      var major, minor, opts, render, x;
      opts = {
        width: 300,
        pad: 0,
        beats: 11,
        beatSize: 0.25,
        noteSize: 0.25,
        bpm: 120,
        vis: null
      };
      x = d3.scale.linear();
      major = d3.svg.axis().scale(x).orient('bottom').tickSize(M.majorTickSize);
      minor = d3.svg.axis().scale(x).orient('bottom').outerTickSize(0).innerTickSize(M.minorTickSize);
      render = function() {
        var duration, n, vis;
        duration = opts.beats * opts.beatSize;
        x.domain([0, duration]).range([opts.pad, opts.width - opts.pad]);
        vis = opts.vis;
        if (vis.select('.axis.major').empty()) {
          vis.append('g').attr({
            "class": 'axis major'
          });
          vis.append('g').attr({
            "class": 'axis minor'
          });
        }
        vis.select('.axis.major').call(major.tickValues((function() {
          var _i, _ref1, _ref2, _results;
          _results = [];
          for (n = _i = 0, _ref1 = duration / opts.beatSize, _ref2 = opts.beatSize; _ref2 > 0 ? _i <= _ref1 : _i >= _ref1; n = _i += _ref2) {
            _results.push(n);
          }
          return _results;
        })()));
        return vis.select('.axis.minor').call(minor.tickValues((function() {
          var _i, _ref1, _ref2, _results;
          _results = [];
          for (n = _i = 0, _ref1 = duration / opts.noteSize, _ref2 = opts.noteSize; _ref2 > 0 ? _i <= _ref1 : _i >= _ref1; n = _i += _ref2) {
            _results.push(n);
          }
          return _results;
        })()));
      };
      return _.accessors(render, opts).addAll().done();
    },
    error: function() {
      var gradColor, opts, render, solidColor, x;
      opts = {
        width: 300,
        pad: 0,
        bpm: 120,
        vis: null,
        seq: null,
        played: null
      };
      solidColor = (function() {
        var colorScale;
        colorScale = d3.scale.threshold().domain([-10, 10]).range(['#00b6ff', '#00fa00', '#ff0012']);
        return function(d) {
          return colorScale(d.errorMs);
        };
      })();
      gradColor = (function() {
        var colorScale;
        colorScale = d3.scale.linear().domain([-50, 0, 50]).range(['#009eff', '#fff', '#ff0000']).interpolate(d3.interpolateLab).clamp(true);
        return function(d) {
          return colorScale(d.errorMs);
        };
      })();
      x = d3.scale.linear();
      render = function() {
        var duration, enter, max, mid, min, played, seq, update;
        seq = opts.seq;
        played = opts.played;
        duration = seq.beats * seq.beatSize;
        x.domain([0, duration]).range([opts.pad, opts.width - opts.pad]);
        update = opts.vis.selectAll('.note').data(played);
        enter = update.enter().append('g').attr('class', 'note');
        enter.append('rect').attr({
          x: function(d) {
            return Math.round(x(d.expectedBeats + d.errorBeats) + (d.errorBeats > 0 ? -(x(d.errorBeats) - x(0)) : 0));
          },
          y: 0,
          height: M.majorTickSize,
          width: function(d) {
            return Math.max(1, Math.abs(x(d.errorBeats) - x(0)));
          },
          stroke: solidColor,
          fill: solidColor
        });
        min = Math.min, max = Math.max;
        mid = (M.majorTickSize + M.noteTop) / 2;
        enter.append('line').attr({
          x1: function(d) {
            return x(d.expectedBeats);
          },
          x2: function(d) {
            return x(d.expectedBeats + seq.noteSize);
          },
          y1: function(d) {
            return mid - min(max(-10, d.errorMs / 5), 10);
          },
          y2: function(d) {
            return mid + min(max(-10, d.errorMs / 5), 10);
          },
          stroke: gradColor
        });
        return update.exit().remove();
      };
      return _.accessors(render, opts).addAll().add('played', render).done();
    },
    sequence: function() {
      var opts, render;
      opts = {
        width: 300,
        pad: 0,
        bpm: 120,
        vis: null,
        seq: null
      };
      render = function() {
        var annKeyLabel, duration, enter, keyLabelPadding, notes, restColor, seq, update, x, xAnn, y, yAnn;
        seq = opts.seq;
        notes = seq.notes;
        duration = seq.beats * seq.beatSize;
        x = d3.scale.linear().domain([0, duration]).range([opts.pad, opts.width - opts.pad]);
        y = function() {
          return M.noteTop;
        };
        update = opts.vis.selectAll('.note').data(notes);
        enter = update.enter().append('g').attr({
          "class": 'note',
          transform: function(d) {
            return "translate(" + (Math.round(x(d.index * seq.noteSize))) + ", " + (y()) + ")";
          }
        });
        update.exit().remove();
        restColor = '#777';
        enter.append('rect').attr({
          width: 4,
          height: M.noteHeight,
          fill: function(d) {
            if (d.key) {
              return '#fff';
            } else {
              return restColor;
            }
          },
          stroke: function(d) {
            if (d.key) {
              return '#fff';
            } else {
              return restColor;
            }
          }
        });
        update = opts.vis.selectAll('.annotation').data(seq.annotations);
        enter = update.enter().append('g').attr({
          "class": 'annotation'
        });
        xAnn = function(d, type) {
          return x(notes[d[type]].index * seq.noteSize) - 2;
        };
        yAnn = function() {
          return y() + 40;
        };
        annKeyLabel = function(type) {
          return enter.append('text').attr({
            "class": type + '-key',
            transform: function(d) {
              return "translate(" + (xAnn(d, type)) + ", " + (yAnn()) + ")";
            },
            fill: function(d) {
              if (d.rest) {
                return restColor;
              } else {
                return '#fff';
              }
            }
          }).each(function() {
            return this.parentNode[type + 'Key'] = this;
          }).text(function(d) {
            var key;
            key = notes[d[type]].key;
            if (key) {
              return Theory.nameForKey(key, true);
            } else {
              return 'Rest';
            }
          });
        };
        annKeyLabel('to');
        annKeyLabel('from');
        keyLabelPadding = 10;
        enter.append('line').attr({
          x1: function(d) {
            return xAnn(d, 'from') + this.parentNode.fromKey.getComputedTextLength() + keyLabelPadding;
          },
          x2: function(d) {
            return xAnn(d, 'to') - keyLabelPadding;
          },
          y1: function(d) {
            return yAnn() - 4;
          },
          y2: function(d) {
            return yAnn() - 4;
          },
          stroke: function(d) {
            if (d.from === d.to) {
              return 'transparent';
            } else {
              return '#555';
            }
          }
        });
        return enter.append('text').attr({
          transform: function(d) {
            return "translate(" + (xAnn(d, 'from')) + ", " + (yAnn() + 20) + ")";
          }
        }).text(function(d) {
          return d.text;
        });
      };
      return _.accessors(render, opts).addAll().add('seq', render).done();
    }
  };

}).call(this);
