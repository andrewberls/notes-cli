// Change underscore templates to {{}} and {{= }} to play nice with ERB
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};

window.Notes = {
  escapeHtml: function(text) {
    return $('<div>').text(text).html();
  },

  // { filename -> Backbone.Collection[Task] },
  allTasks: {},

  // Filled in by the server
  distinctFlags: [],

  defaultFlags: ['TODO', 'OPTIMIZE', 'FIXME'],

  // Color classes to be paired against distinct flags (for consistency)
  colors: [
    'purple','lightblue','fuschia','lightgreen','orange','green','blue',
    'pink','turquoise','deepred',
  ]
}

// Filtering criteria
Notes.selectedFlags = Notes.defaultFlags;





Notes.colorFor = function(flagName) {
  // Map is tuple of [flagName, color]
  return _.find(Notes.colorMap, function(map) { return map[0] == flagName })[1];
}








Notes.Task = Backbone.Model.extend({});


// A view for a single task item
Notes.TaskView = Backbone.View.extend({
  tagName: 'div',
  className: 'task',
  tmpl: $('#tmpl-task').html(),

  render: function() {
    $(this.el).html(_.template(this.tmpl, { task: this.model.attributes }));
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
    $el.append("<h2 class='task-filename'>"+this.collection.filename+"</h2>");

    this.collection.each(function(task) {
      $el.append(new Notes.TaskView({ model: task }).render().el);
    });
    return this;
  }
});


// TODO: how to handle models here?
Notes.SidebarFlag = Backbone.Model.extend({
  defaults: {
    checked: true
  }
});


Notes.SidebarFlagView = Backbone.View.extend({
  tagName: 'div',
  className: 'flag-container',
  tmpl: $('#tmpl-flag').html(),

  render: function() {
    $(this.el).html(_.template(this.tmpl, { flag: this.model.attributes }));
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


// TODO: this only renders the initial state of the sidebar?
// i.e., defaults?
Notes.renderSidebar = function() {
  var $sidebar = $('.flags-container'),
      flag, flagView;

  Notes.defaultFlags.forEach(function(flagName) {
    flag     = new Notes.SidebarFlag({ name: flagName })
    flagView = new Notes.SidebarFlagView({ model: flag });
    $sidebar.append(flagView.render().el);
  });
}


Notes.renderTasks = function(task_map) {
  var $container = $('.main-content-container'),
      filename, tasks, collection, collectionView;

  if ($.isEmptyObject(task_map)) {
    // TODO - temporary hack
    $container.html($("<div class='empty-tasks-container'>").append(
      "<h2>No tasks matching the criteria were found!</h2>"));
    return;
  }

  for (filename in task_map) {
    tasks = task_map[filename];

    collection = new Notes.TasksCollection(tasks);
    collection.filename   = filename;
    Notes.allTasks[filename] = collection;

    collectionView = new Notes.TaskCollectionView({ collection: collection })
    $container.append(collectionView.render().el);
  }
}


$(function() {
  var path = window.location.pathname;

  $.getJSON((path === '/' ? '' : path) + "/tasks.json", function(json) {
    var stats = json.stats;

    // Loading in global state on an async operation is bad mmk,
    // but we're blocking until this point anyways
    Notes.distinctFlags = stats.distinct_flags;

    // TODO: concat with distinct, default, or selected?
    Notes.allFlags = _.uniq(Notes.distinctFlags.concat(Notes.defaultFlags));
    Notes.colorMap = _.zip(Notes.allFlags, Notes.colors);

    Notes.renderStats(stats);
    Notes.renderSidebar()
    Notes.renderTasks(json.task_map);
  });
});
