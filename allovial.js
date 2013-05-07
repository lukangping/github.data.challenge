var w = 1300,
    h = 800,
    gapratio = .65,
    padding = 10,
    mainHeight = 20;

var svg = d3.select("body")
	.append("svg:svg")
	.attr("width", w)
	.attr("height", h);

function processData(data) {
    var result = {};
    d3.map(data).forEach(function(year, clusters) {
	var newCluster = [];
	for (var key in clusters) {
	    var langs = clusters[key];
	    var newLangs = [];
	    if (typeof(langs) === "string") {
		newLangs.push({name: langs});
	    }
	    else {
		langs.map(function(lang) {
		    newLangs.push({name: lang});
		});
	    }
	    newCluster.push(d3.map({langs: newLangs}));
	}
	result[year] = newCluster;
    });
    return result;
}

d3.json("clusters.json", function(data) {
    var result = processData(data);
    data = d3.map(result);

    var maxCluster = d3.max(data.values(), function(clusters) {
	var clusterNum = 0;
	clusters.map(function(cluster) {
	    clusterNum += 1;
	});
	return clusterNum;
    }),
	maxn = d3.max(data.values(), function(clusters) {
	var nodeNum = 0;
	clusters.map(function(cluster) {
	    nodeNum += cluster.get("langs").length;
	});
	return nodeNum;
    });

    
    var x = d3.scale.ordinal()
            .domain(d3.range(data.values().length))
            .rangeBands([0, w + w/(data.values().length - 1)], gapratio),
	y = d3.scale.linear()
            .domain([0, maxn])
            .range([0, h - maxCluster*padding]),
	line = d3.svg.line().interpolate('basis'),
	height = (h - maxCluster * padding - mainHeight) / maxn;

    data.forEach(function(year, clusters) {
	offsetY = mainHeight;
	clusters.map(function(cluster) {
	    cluster.set("offsetY", offsetY);
	    cluster.get("langs").forEach(function(lang, index) {
		lang.offsetY = offsetY + index * height;
	    });
	    offsetY += y(cluster.get("langs").length) + padding;
	});
    });

    var links = [],
	langColors = {},
	colorBrewer = d3.scale.category20c();

    function findEnd(clusters, langName) {
	var result = null;
	clusters.forEach(function(cluster) {
	    cluster.get("langs").forEach(function(lang) {
		if (lang.name == langName) {
		    result = lang;
		}
	    });
	});
	return result;
    }

    var langNum = 0;
    for (var i = 0; i < data.keys().length - 1; i++) {
	var rc = data.values()[i+1];
	data.values()[i].forEach(function(cluster) {
	    cluster.get("langs").forEach(function(lang) {
		if (langColors[lang.name] == null) {
		    langColors[lang.name] = colorBrewer(langNum);
		    langNum++;
		}
		var rlang = findEnd(rc, lang.name);
		if (rlang != null) {
		    links.push({color: langColors[lang.name],startY: lang.offsetY + height/2, startX: x(i) - x(0) + x.rangeBand(), endX: x(i+1) - x(0), endY: rlang.offsetY + height/2, width: height});
		}
	    });
	});
    }
    
    var years = svg.selectAll("g.year")
	    .data(data.values())
	    .enter().append("svg:g")
	    .attr("transform", function(d, i) { return "translate(" + (x(i) - x(0)) + ",0)"; });
    var clusters = years.selectAll("g.cluster")
	    .data(function(d) {return d;})
	    .enter().append("svg:g");
    var langs = clusters.selectAll("rect.lang").data(function(d) {return d.get("langs");}).enter().append("svg:rect")
	    .attr("fill", function(d) {return langColors[d.name];})
	    .attr("y", function(d, i) {return d.offsetY;})
	    .attr("width", x.rangeBand())
	    .attr("height", function(d, i) {return height;})
	    .append("svg:title")
	    .text(function(d, i) {return d.name;});

    var texts = clusters.selectAll("text.lang").data(function(d) {return d.get("langs");}).enter().append("svg:text")
	    .text(function(d) {return d.name;})
	    .attr("fill", "#eee")
	    .attr("y", function(d, i) {return d.offsetY + height/2 + 2;})
	    .attr("width", x.rangeBand())
	    .attr("height", function(d, i) {return height;})
	    .attr("font-size", 6)
	    .attr("font-family", "Helvetica")
	    .attr("style", "cursor: pointer")
	    .append("svg:title")
	    .text(function(d) {return d.name;});
    
    function linkLine() {
	return function(l) {
	    var points = [[l.startX, l.startY], [l.startX + 25, l.startY], [l.endX-25, l.endY], [l.endX, l.endY]];
	    return line(points);
	};
    }

    var connections = svg.selectAll('path.link')
            .data(links)
	    .enter().append('svg:path')
            .attr('stroke', function(l) {return l.color;})
	    .attr("fill", "none")
	    .attr("opacity", 0.5)
            .style('stroke-width', function(l) { return l.width; })
            .attr('d', linkLine())
            .on('mouseover', function() {
		d3.select(this).attr('opacity', '1');
            })
            .on('mouseout', function() {
		d3.select(this).attr('opacity', '0.5');
            });

    var monthTexts = data.keys();
    var months = svg.selectAll("text.month")
	    .data(monthTexts).enter().append("svg:text")
	    .text(function(d) {return d;})
	    .attr("fill", "#888")
	    .attr("y", 14).attr("x", function(d, i) {return i * x.rangeBand() / (1-gapratio);})
	    .attr("height", mainHeight)
	    .attr("font-size", 14)
	    .attr("font-family", "Helvetica Neue");
});