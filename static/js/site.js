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
    return Theory.nameForKey = function(key, number) {
      return notes[key % 12] + (number ? '' + Math.floor(key / 12) - 1 : '');
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
    var height, loadSequence, sequence, start, vis, width, _ref1;
    d('Starting');
    vis = d3.select('#piece');
    _ref1 = vis.node().getBoundingClientRect(), width = _ref1.width, height = _ref1.height;
    height = 200;
    vis.attr({
      width: width,
      height: height + 150
    });
    sequence = {
      notes: _.flatten([Theory.major(60), Theory.major(72), 72 + 12, 72 + 12, Theory.major(72).reverse(), Theory.major(60).reverse()]).map(function(key, index) {
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
          to: 29,
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
      return start(seq, bpm).on('start', function(played) {
        return d('start');
      }).on('update', function(played) {
        return errorVis.played(played);
      }).on('end', function() {
        return d('end');
      });
    };
    _.defer(function() {
      return loadSequence(sequence);
    });
    return start = function(seq, bpm) {
      var alreadyPlayed, dispatch, findCorrespondingIndex, noteIndexToBeatTime, noteIndexToTime, played, startTime;
      dispatch = d3.dispatch('start', 'update', 'end');
      played = [];
      alreadyPlayed = {};
      noteIndexToBeatTime = d3.scale.linear().domain([0, seq.notes.length]).range([0, seq.notes.length * seq.noteSize]);
      noteIndexToTime = d3.scale.linear().domain([0, seq.notes.length]).range([0, (1 / bpm) * 60 * 1000 * seq.notes.length]);
      startTime = null;
      instrument.on('keydown.notes', function(e) {
        var errorBeats, errorMs, expectedBeats, expectedMs, index, note, playedBeats, playedMs, time;
        if (startTime == null) {
          startTime = e.time;
          dispatch.start(played);
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
        var note, timeWindow, _i, _len, _ref2;
        timeWindow = 2000;
        _ref2 = seq.notes;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          note = _ref2[_i];
          if (note.index in alreadyPlayed) {
            continue;
          } else if (note.key === key && Math.abs(noteIndexToTime(note.index) - time) < timeWindow) {
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
        return instrument.on('keydown.notes', null);
      };
      _.defer(function() {
        return dispatch.update(played);
      });
      return dispatch;
    };
  });

  M = {
    noteTop: 60,
    noteHeight: 15,
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
      major = d3.svg.axis().scale(x).orient('bottom').tickSize(14);
      minor = d3.svg.axis().scale(x).orient('bottom').outerTickSize(0).innerTickSize(7);
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
      var color, colorScale, opts, render;
      opts = {
        width: 300,
        pad: 0,
        bpm: 120,
        vis: null,
        seq: null,
        played: null
      };
      colorScale = d3.scale.linear().domain([-50, 0, 50]).range(['#009eff', '#fff', '#ff0000']).interpolate(d3.interpolateLab).clamp(true);
      color = function(d) {
        switch (false) {
          case !(Math.abs(d.errorMs) < 10):
            '#00fa00';
            break;
          case !(d.errorMs < 0):
            '#ff0012';
            break;
          default:
            '#00b6ff';
        }
        return colorScale(d.errorMs);
      };
      render = function() {
        var duration, enter, played, seq, update, x;
        seq = opts.seq;
        played = opts.played;
        duration = seq.beats * seq.beatSize;
        x = d3.scale.linear().domain([0, duration]).range([opts.pad, opts.width - opts.pad]);
        update = opts.vis.selectAll('.note').data(played);
        enter = update.enter().append('g').attr('class', 'note');
        enter.append('line').attr({
          x1: function(d) {
            return x(d.expectedBeats);
          },
          x2: function(d) {
            return x(d.expectedBeats + seq.noteSize);
          },
          y1: function(d) {
            return 30 - d.errorMs / 50;
          },
          y2: function(d) {
            return 30 + d.errorMs / 50;
          },
          stroke: color
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
        var annKeyLabel, duration, enter, keyLabelPadding, notes, seq, update, x, xAnn, y, yAnn;
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
        enter.append('rect').attr({
          width: 4,
          height: M.noteHeight,
          fill: '#fff',
          stroke: '#fff'
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
            }
          }).text(function(d) {
            return Theory.nameForKey(notes[d[type]].key, true);
          }).each(function() {
            return this.parentNode[type + 'Key'] = this;
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
          stroke: '#555'
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
