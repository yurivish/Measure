// Generated by CoffeeScript 1.6.3
(function() {
  var ascending, descending, exercise, indicate, major, noteIndicator, notes, sel, visExercise, visSection, _ref;

  window._d = window.d = (_ref = typeof console !== "undefined" && console !== null ? console.log.bind(console) : void 0) != null ? _ref : function() {};

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

  ascending = _.flatten([major(60), major(72), 72 + 12]);

  descending = _.flatten([major(72).reverse(), major(60).reverse()]);

  exercise = [
    {
      direction: 'ascending',
      notes: ascending.map(function(key, index) {
        return {
          key: key,
          index: index
        };
      })
    }, {
      direction: 'descending',
      notes: descending.map(function(key, index) {
        return {
          key: key,
          index: index
        };
      })
    }
  ];

  exercise.forEach(function(section, i) {
    if (i) {
      return section.notesBefore = exercise[i - 1].notesBefore + section.notes.length;
    } else {
      return section.notesBefore = 0;
    }
  });

  d(exercise);

  sel = d3.select('#notes').append('g').attr('transform', 'translate(25, 25)');

  noteIndicator = sel.append('g');

  noteIndicator.append('circle').attr({
    fill: '#333',
    stroke: '#333',
    cx: 900,
    cy: 100
  });

  noteIndicator.append('text').attr({
    'text-anchor': 'middle',
    dy: '.35em',
    fill: '#fff',
    x: 900,
    y: 100
  }).text('y0');

  indicate = function(note) {
    noteIndicator.select('text').text(note);
    return noteIndicator.select('circle').attr({
      r: 60,
      stroke: '#ccc'
    }).interrupt().transition().duration(300).ease('cubic-out').attr({
      r: 50,
      stroke: '#333'
    });
  };

  visExercise = function(exercise) {
    var enter, heightSoFar, i, rect, update;
    update = sel.selectAll('.section').data(exercise);
    enter = update.enter().append('g').attr({
      "class": 'section'
    });
    heightSoFar = 0;
    update.each(visSection).attr({
      transform: function(d, i) {
        var offset, padding, rect;
        padding = 25;
        offset = heightSoFar;
        rect = this.getBoundingClientRect();
        heightSoFar += rect.height + padding;
        return "translate(0, " + offset + ")";
      }
    });
    sel.selectAll('.note').attr({
      opacity: 1e-6
    }).transition().duration(600).delay(function(d, i) {
      return i * 20;
    }).attr({
      opacity: 1
    });
    rect = sel.node().getBoundingClientRect();
    d3.select('#notes').attr({
      height: rect.top + rect.height
    });
    i = 1;
    return d3.select('body').on('keypress', function() {
      var note, p, s, w;
      w = 800;
      p = 1;
      s = w / 8 - p;
      note = d3.select('.note:nth-child(' + i++ + ')');
      indicate(note.select('text').text());
      note.select('.after').transition().duration(300).ease('cubic-out').attr({
        height: s,
        y: 0
      });
      return note.select('text').transition().duration(300).ease('cubic-out').attr('fill', '#000');
    });
  };

  visSection = function(section, i) {
    var enter, p, s, update, w;
    w = 800;
    p = 1;
    s = w / 8 - p;
    update = d3.select(this).selectAll('.note').data(section.notes);
    enter = update.enter().append('g').attr({
      "class": 'note'
    });
    enter.append('rect').attr({
      height: s,
      width: s,
      "class": 'before',
      fill: '#343434'
    });
    enter.append('rect').attr({
      height: 0,
      width: s,
      "class": 'after',
      y: s,
      fill: '#ccc'
    });
    enter.append('text').attr({
      'text-anchor': 'middle',
      x: s / 2,
      y: s / 2,
      dy: '.35em',
      fill: '#ddd'
    }).text(function() {
      return ['C', 'D', 'E', 'F#'][~~(Math.random() * 4)];
    });
    return update.attr({
      transform: function(d, i) {
        var x, y;
        x = i * (s + p) % w;
        y = (s + p) * (~~((i / w) * (s + p)));
        return "translate(" + x + ", " + y + ")";
      }
    }).on('mouseenter', function() {});
  };

  visExercise(exercise);

}).call(this);
