// Change underscore templates to {{}} and {{= }} to play nice with ERB
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};


// Global namespace object
window.Notes = {};


Notes.escapeHtml = function(text) {
  return $('<div>').text(text).html();
}


// Is Array A a subset of Array B?
Notes.isSubset = function(a,b) {
  return a.length === _.intersection(a,b).length;
}


// How many tabs or spaces does a string start with?
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
Notes.minLtrim = function(lines) {
  var counts = lines.map(function(line) { return Notes.leadingWhitespaceCount(line); })
  return Math.min.apply(null, counts);
}


Notes.defaultFlags = ['TODO', 'OPTIMIZE', 'FIXME'];


Notes.getSelectedFlags = function() {
  return Notes.sidebarView.collection
    .filter(function(f) { return f.get('checked'); })
    .map(function(f) { return f.get('name') });
}


// Color classes to be paired against distinct flags (for consistency)
Notes.colors = [
  'lightblue','purple','fuschia','lightgreen','orange','green','blue',
  'pink','turquoise','deepred',
]

// TODO
Notes.buildColorMap = function(flags) {
  var allFlags   = _.uniq(flags.concat(Notes.defaultFlags));
  Notes.colorMap = _.zip(allFlags, Notes.colors);
}


Notes.colorFor = function(flagName) {
  var map;
  for (var i=0; i<Notes.colorMap.length; i++) {
    map = Notes.colorMap[i];
    if (map[0] === flagName) {
      return map[1];
    } else if (map[0] === undefined) {
      // No existing mapping found - add new flag to colorMap
      map[0] = flagName;
      return map[1];
    }
  }

  return Notes.colors[Notes.colors.length-1]; // TODO - default to last color in list
}



Notes.Task = Backbone.Model.extend({
  escapedLine: function() {
    return Notes.escapeHtml(this.get('line'));
  },

  escapedContextLines: function() {
    var ctx = this.get('context');
    if (ctx === '') { return []; }

    return ctx.split("\n")
               .map(function(line) { return Notes.escapeHtml(line); });
  },

  allLines: function() {
    return [this.escapedLine()].concat(this.escapedContextLines());
  },

  highlightedLine: function() {
    var regex = new RegExp(this.get('flags').join('|'), 'gi');
    return this.escapedLine().replace(regex, function(flag) {
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
  template: _.template($('#tmpl-task').html()),

  render: function() {
    $(this.el).html(this.template({ task: this.model }));
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


// A view for a collection of tasks grouped under a common filename
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



// A flag accompanied by a checkbox in the sidebar
Notes.Flag = Backbone.Model.extend({
  defaults: { checked: true },

  checkedClass: function() { return this.get('checked') ? 'checked' : ''; }
});


Notes.FlagView = Backbone.View.extend({
  tagName: 'div',
  className: 'flag-container',
  template: _.template($('#tmpl-flag').html()),

  render: function() {
    $(this.el).html(this.template({ flag: this.model }));
    return this;
  },

  events: {
    'click .checkbox': 'toggleCheck',
    'click .delete-flag-btn': 'deleteFlag'
  },

  $checkbox: function() { return $(this.el).find('.checkbox'); },
  isChecked: function() { return this.$checkbox().hasClass('checked'); },
  check: function() {
    this.model.set('checked', true);
    this.$checkbox().addClass('checked');
  },
  uncheck: function() {
    this.model.set('checked', false);
    this.$checkbox().removeClass('checked');
  },
  toggleCheck: function() { this.isChecked() ? this.uncheck() : this.check(); },

  deleteFlag: function() {
    Notes.sidebarView.collection.remove(this.model);
    var $el = $(this.el);
    $el.slideUp(200, function() { $el.remove(); });
  }
});


Notes.FlagCollection = Backbone.Collection.extend({
  model: Notes.Flag,

  // Add a flag into the collection unless it's already present
  merge: function(flag) {
    var attrs = { name: flag.toUpperCase() }
        match = this.findWhere(attrs);
    if (!match) { this.add(attrs); }
  }
});


Notes.FlagCollectionView = Backbone.View.extend({
  tagName: 'div',

  render: function() {
    var $el = $(this.el);
    $el.html('');

    this.collection.each(function(flag) {
      $el.append(new Notes.FlagView({ model: flag }).render().el);
    });
    return this;
  }
});



// Merge a custom flag into the sidebar and re-render
Notes.addFlag = function(flag) {
  if (flag === '') { return false; }
  Notes.sidebarView.collection.merge(flag);
  Notes.renderSidebar();
}


// Build (or rebuild) the sidebar from the flags
// used to query the server
Notes.buildSidebar = function(flags) {
  var attrs = flags.map(function(f) { return { name: f }; });

  Notes.sidebarView = new Notes.FlagCollectionView({
    collection: new Notes.FlagCollection(attrs)
  });
  Notes.renderSidebar();
}

// TODO: calling this more than once breaks click handlers ???
Notes.renderSidebar = function() {
  var $container = $('.flags-container');
  $container.empty();
  $container.append(Notes.sidebarView.render().el);
}


Notes.renderStats = function(stats) {
  var flag_counts = stats.flag_counts;
  if (jQuery.isEmptyObject(flag_counts)) { return; }

  // TODO: add in stats container
  //   <div class="stats-container">
  //     <div class="chart"></div>
  //   </div>
}


// tasks - Array[Notes.Task]
Notes.renderTasks = function(tasks) {
  var $container = $('.main-content-container'),
      filename, collection, collectionView;

  $container.empty();

  if (tasks.length === 0) {
    $container.html($("<div class='empty-tasks-container'>").append(
      "<h2>No tasks matching the criteria were found!</h2>"));
    return;
  }

  // filename -> Array[Notes.Task]
  var taskMap = _.groupBy(tasks, function(t) { return t.get('filename'); });

  for (filename in taskMap) {
    collection = new Notes.TasksCollection(taskMap[filename]);
    collection.filename   = filename;

    collectionView = new Notes.TaskCollectionView({ collection: collection })
    $container.append(collectionView.render().el);
  }
}


Notes.addProgress = function() {
  $('.loading-container').find('p').append('.');
}



// Check if a set of tasks can be filtered based on flags we've already searched for
// This allows us to avoid hitting the server when we don't need to
//
// flags - Array[String]
Notes.isSubsetQuery = function(flags) {
  return Notes.isSubset(flags, Notes.lastQueryFlags);
}


// Find a subset of locally-cached tasks that match a set of search flags
// Returns Array[Notes.Task]
//
// TODO: this behaves weirdly if a task has multiple flags, punting for now
Notes.filterTasks = function(queryFlags) {
  if (queryFlags.length === 0) { return []; }

  return Notes.tasks.filter(function(task) {
    var taskFlags = task.get('flags');
    return (Notes.isSubset(taskFlags, queryFlags) ||
            Notes.isSubset(queryFlags, taskFlags));
  });
}


// Returns the URL to query the server at
Notes.queryPath = function() {
  var path = window.location.pathname;
  return (path === '/' ? '' : path) + "/tasks.json"
}


// Fetch tasks from the server and re-render
Notes.queryTasks = function(queryFlags) {
  if (!Notes.colorMap) { Notes.buildColorMap(queryFlags); }

  if (Notes.lastQueryFlags && Notes.isSubsetQuery(queryFlags)) {
    // Subset query - don't need to hit server
    var tasks = Notes.filterTasks(queryFlags);
    Notes.renderTasks(tasks);
    return;
  }

  // Can't filter client-side - need to hit server
  $('.main-content-container').html("<div class='loading-container'><p>Loading </p></div>");
  var progressInterval = setInterval(Notes.addProgress, 175);

  if (!Notes.sidebarView) { Notes.buildSidebar(queryFlags); }

  $.getJSON(Notes.queryPath(), { flags: queryFlags }, function(json) {
    var stats = json.stats,
        tasks = json.tasks.map(function(attrs) { return new Notes.Task(attrs) });

    Notes.tasks = tasks;
    Notes.lastQueryFlags = queryFlags; // Save the most recent search terms for checking subsets

    clearInterval(progressInterval);
    Notes.renderStats(stats);
    Notes.renderTasks(tasks);

  });
}



// Page Load
// ----------------------------------
Notes.queryTasks(Notes.defaultFlags);


$(function() {
  var $doc = $(document);

  $doc.on('keyup', '.add-flag', function(e) {
    if (e.keyCode === 13) {
      var $input = $(this);
      Notes.addFlag($input.val());
      $input.val('');
    }
  });


  $doc.on('click', '.add-flag-btn', function() {
    var $input = $('.add-flag');
    Notes.addFlag($input.val());
    $input.val('');
    return false;
  });


  $doc.on('click', '.filter-btn', function() {
    Notes.queryTasks(Notes.getSelectedFlags());
    return false;
  });


  $doc.on('click', '.restore-defaults-btn', function() {
    Notes.queryTasks(Notes.defaultFlags);
    return false;
  });


  $doc.on('click', '.toggle-all-context-btn', function() {
    var $toggle = $('.task-toggle'),
        $ctx    = $('.task-context');

    if ($ctx.is(':visible')) {
      $(this).html("Show all context <i class='fa fa-angle-down'></i>");
      $toggle.removeClass('fa-angle-up').addClass('fa-angle-down');
      $ctx.slideUp();
    } else {
      $(this).html("Hide all context <i class='fa fa-angle-up'></i>");
      $toggle.removeClass('fa-angle-down').addClass('fa-angle-up');
      $ctx.slideDown();
    }

    return false;
  });
});
