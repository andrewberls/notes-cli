// Change underscore templates to {{}} and {{= }} to play nice with ERB
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};

// Global namespace object
window.Notes = {}

Notes.escapeHtml = function(text) {
  return $('<div>').text(text).html();
}

Notes.leadingWhitespaceCount = function(str) {
  var count = 0;
  while(str.charAt(0) === " " || str.charAt(0) === "\t") {
    str = str.substr(1);
    count++;
  }
  return count;
}

// Take an array of lines and return the smallest number of leading whitespaces
// (tabs or spaces) from among them
Notes.min_ltrim = function(lines) {
  var counts = lines.map(function(line) { return Notes.leadingWhitespaceCount(line); })
  return Math.min.apply(null, counts);
}

Notes.allTasks = []

// Filled in by the server
Notes.distinctFlags = []

Notes.defaultFlags = ['TODO', 'OPTIMIZE', 'FIXME']

// Color classes to be paired against distinct flags (for consistency)
Notes.colors = [
  'lightblue','purple','fuschia','lightgreen','orange','green','blue',
  'pink','turquoise','deepred',
]

Notes.colorFor = function(flagName) {
  return _.find(Notes.colorMap, function(map) { return map[0] == flagName })[1];
}

// Filtering criteria
Notes.selectedFlags = Notes.defaultFlags;












Notes.Task = Backbone.Model.extend({
  escapedLine: function() {
    return Notes.escapeHtml(this.get('line'));
  },

  escapedContextLines: function() {
    return this.get('context').split("\n")
               .map(function(e) { return Notes.escapeHtml(e); });
  },

  allLines: function() {
    return [this.escapedLine()].concat(this.escapedContextLines());
  },

  highlightedLine: function() {
    var regex = new RegExp(this.get('flags').join('|'), 'gi');
    return this.get('line').replace(regex, function(flag) {
      return "<strong>"+flag+"</strong>";
    });
  },

  formattedSha: function() {
    var sha = this.get('sha');
    return sha ? "@ " + sha.slice(0,7) : '';
  },

  formattedDate: function() {
    var date  = new Date(this.get('date')),
        month = date.getMonth() + 1,
        day   = date.getDate(),
        year  = date.getFullYear().toString().slice(2);

    return month + '/' + day + '/' + year;
  }
});


// A view for a single task item
Notes.TaskView = Backbone.View.extend({
  tagName: 'div',
  className: 'task',
  tmpl: $('#tmpl-task').html(),

  render: function() {
    $(this.el).html(_.template(this.tmpl, { task: this.model }));
    return this;
  },

  events: {
    'click .task-toggle': 'toggleContext'
  },

  toggleContext: function() {
    var $el = $(this.el),
        $toggle = $el.find('.task-toggle'),
        $ctx    = $el.find('.task-context');

    if ($ctx.is(':visible')) {
      $toggle.removeClass('fa-angle-up').addClass('fa-angle-down');
      $ctx.slideUp();
    } else {
      $toggle.removeClass('fa-angle-down').addClass('fa-angle-up');
      $ctx.slideDown();
    }
  }
});


Notes.TasksCollection = Backbone.Collection.extend({
  model: Notes.Task,

  initialize: function() {
    this.filename = '';
  }
});


// A view for a collection of tasks grouped under a common filenam
Notes.TaskCollectionView = Backbone.View.extend({
  tagName: 'div',
  classname: 'tasks-container',

  render: function() {
    var $el = $(this.el);
    $el.append("<h2 class='task-filename'>"+this.collection.filename+":</h2>");

    this.collection.each(function(task) {
      $el.append(new Notes.TaskView({ model: task }).render().el);
    });
    return this;
  }
});


Notes.SidebarFlag = Backbone.Model.extend({
  defaults: { checked: true },

  checkedClass: function() {
    return this.get('checked') ? 'checked' : '';
  }
});

Notes.SidebarFlagView = Backbone.View.extend({
  tagName: 'div',
  className: 'flag-container',
  tmpl: $('#tmpl-flag').html(),

  render: function() {
    $(this.el).html(_.template(this.tmpl, { flag: this.model }));
    return this;
  },

  events: {
    'click .checkbox': 'toggleCheckbox'
  },

  checkbox:  function() { return $(this.el).find('.checkbox'); },
  check:     function() { this.checkbox().addClass('checked'); },
  uncheck:   function() { this.checkbox().removeClass('checked'); },
  isChecked: function() { return this.checkbox().hasClass('checked'); },

  toggleCheckbox: function() {
    var name = this.model.get('name');

    if (this.isChecked()) {
      // Removing
      var idx = Notes.selectedFlags.indexOf(name);
      Notes.selectedFlags.splice(idx, 1);
      this.uncheck();
    } else {
      // Adding
      Notes.selectedFlags.push(name);
      this.check();
    }
  }
});



Notes.drawPiechart = function(data) {
  // Dimensions
  var $chart = $('.chart'); // TODO: probably want to pass in selector
  var w = h = $chart.width(); // Delegate width to CSS

  var ringThickness = 35,
      outerRadius   = w / 2,
      innerRadius   = outerRadius - ringThickness;

  // Function that takes in dataset and returns dataset annotated with arc angles, etc
  var pie = d3.layout.pie()
            .value(function(d) { return d; }); // TODO

  var color = d3.scale.category20(); // TODO

  // Arc drawing function
  var arc = d3.svg.arc()
          .innerRadius(innerRadius)
          .outerRadius(outerRadius);

  // Create svg element
  var svg = d3.select(".chart")
              .append("svg")
              .attr('width', w)
              .attr('height', h);

  // Set up groups
  arcs = svg.selectAll("g.arc")
            .data(pie(data))
            .enter()
            .append('g')
            .attr('class', 'arc')
            .attr('transform', "translate(" + outerRadius + "," + outerRadius + ")");

  // Draw arc paths
  // A path's path description is defined in the d attribute
  // so we call the arc generator, which generates the path information
  // based on the data already bound to this group
  arcs.append('path')
      .attr('fill', function(d, i) { return color(i) })
      .attr('d', arc);

  // Draw legend w/ labels
  // function swatchFor(d, i) {
  //   if (d.percent === 0) return; // TODO

  //   //<span class="swatch" style="background-color: #08c"></span> Ruby
  //   return "<span class='swatch' style='background-color: " + color(i) + "'></span> " + d.language +
  //     "<span class='percent'>("+Math.round(d.percent*100)+"%)</span>"
  // }

  // d3.select(selector + " .legend")
  //   .selectAll('li')
  //   .data(legendLangs)
  //   .enter()
  //   .append('li')
  //   .html(function(d, i) { return swatchFor(d,i); })
}


Notes.renderStats = function(stats) {
  var flag_counts = stats.flag_counts;
  if (jQuery.isEmptyObject(flag_counts)) { return; }

  // TODO: add in stats container
  //
  //   <div class="stats-container">
  //     <div class="chart"></div>
  //   </div>
}


// TODO: this only renders the initial state of the sidebar, i.e. defaults
Notes.renderSidebar = function() {
  var $sidebar = $('.flags-container'),
      flag, flagView;

  $sidebar.empty();

  Notes.defaultFlags.forEach(function(flagName) {
    flag     = new Notes.SidebarFlag({ name: flagName })
    flagView = new Notes.SidebarFlagView({ model: flag });
    $sidebar.append(flagView.render().el);
  });
}


Notes.renderTasks = function(tasks) {
  var $container = $('.main-content-container'),
      filename, collection, collectionView;

  $container.empty();

  // filename -> [Notes.Task]
  var taskMap = _.groupBy(tasks, function(t) { return t.get('filename'); });

  if ($.isEmptyObject(taskMap)) {
    // TODO - temporary hack
    $container.html($("<div class='empty-tasks-container'>").append(
      "<h2>No tasks matching the criteria were found!</h2>"));
    return;
  }

  for (filename in taskMap) {
    collection = new Notes.TasksCollection(taskMap[filename]);
    collection.filename   = filename;

    collectionView = new Notes.TaskCollectionView({ collection: collection })
    $container.append(collectionView.render().el);
  }
}


Notes.addProgress = function() {
  $('.loading-container').find('p').append('.')
}


// Fetch tasks from the server and re-render
Notes.fetchTasks = function() {
  progressInterval = setInterval(Notes.addProgress, 175);

  var path = window.location.pathname;

  $.getJSON((path === '/' ? '' : path) + "/tasks.json", { flags: ['FINDME'] }, function(json) {
    var stats = json.stats,
        tasks = json.tasks.map(function(attrs) { return new Notes.Task(attrs) });

    Notes.allTasks = tasks;

    Notes.distinctFlags = stats.distinct_flags;

    // TODO: concat with distinct, default, or selected?
    Notes.allFlags = _.uniq(Notes.distinctFlags.concat(Notes.defaultFlags));
    Notes.colorMap = _.zip(Notes.allFlags, Notes.colors);

    clearInterval(progressInterval);
    Notes.renderStats(stats);
    Notes.renderSidebar();
    Notes.renderTasks(tasks);
  });
}



$(function() {
  Notes.fetchTasks();

  $(document).on('click', '.filter-btn', function() {
    Notes.fetchTasks()
    return false;
  });
});
