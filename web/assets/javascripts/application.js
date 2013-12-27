// Change underscore templates to {{}} and {{= }} to play nice with ERB
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};

window.Notes = {}

Notes.allTasks = {}; // { filename -> Backbone.Collection[Task] }


Notes.Task = Backbone.Model.extend({});


// A view for a single task item
Notes.TaskView = Backbone.View.extend({
  tagName: 'div',
  className: 'task',
  tmpl: $('#tmpl-task').html(),

  render: function() {
    $(this.el).html(_.template(this.tmpl, { task: this.model.attributes }))
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
  var totals = stats.totals;
  if (jQuery.isEmptyObject(totals)) { return; }

  // TODO: add in stats container
  //
  //   <div class="stats-container">
  //     <div class="chart"></div>
  //   </div>
}


Notes.renderTasks = function(all_tasks) {
  var $container = $('.main-content-container'),
      filename, tasks, collection, collectionView;

  if ($.isEmptyObject(all_tasks)) {
    // TODO - temporary hack
    $container.html($("<div class='empty-tasks-container'>").append(
      "<h2>No tasks matching the criteria were found!</h2>"));
    return;
  }

  for (filename in all_tasks) {
    tasks = all_tasks[filename];

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
    Notes.renderStats(json.stats);
    Notes.renderTasks(json.all_tasks);
  });
});
