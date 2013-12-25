// Change underscore templates to {{}} and {{= }} to play nice with ERB
_.templateSettings = {
  interpolate: /\{\{\=(.+?)\}\}/g,
  evaluate: /\{\{(.+?)\}\}/g
};

window.Notes = {}

$(function() {



  $(document).on('click', '.task-toggle-container i', function() {
    var $toggle = $(this),
        $ctx = $toggle.parent().parent().find('.task-context'); // TODO: ugh

    if ($ctx.is(':visible')) {
      $toggle.removeClass('fa-angle-up').addClass('fa-angle-down');
      $ctx.slideUp();
    } else {
      $toggle.removeClass('fa-angle-down').addClass('fa-angle-up');
      $ctx.slideDown();
    }
  });






  $container = $('.tasks-container');
  taskTmpl  = $('#tmpl-task').html();

  var path = window.location.pathname;
  $.getJSON((path === '/' ? '' : path) + "/tasks.json", function(json) {
    var filename, tasks, task, compiled;
    Notes.tasks = json; // TODO: do we want a Task class?

    for (filename in json) {
      tasks = json[filename];

      $container.append("<h2 class='task-filename'>" + filename + "</h2>")

      for (var i=0; i<tasks.length; i++) {
        task = tasks[i];
        compiled = _.template(taskTmpl, { task: task });
        $container.append(compiled);
      }
    }
  });
});


















drawPiechart = function(data) {
  var data = [ 0.25,0.5,0.25]; // TODO

  // Dimensions
  var $chart = $('.chart');
  if ($chart.length === 0) { return; }

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

drawPiechart();
