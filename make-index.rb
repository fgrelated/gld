#!/usr/bin/env ruby

require 'open-uri'
require 'date'
require 'bigdecimal'

cache = 'GLD_US_archive_EN.csv'
data_url = 'http://www.spdrgoldshares.com/assets/dynamic/GLD/GLD_US_archive_EN.csv'
source = FileTest.exist?(cache) ? cache : data_url

data = []

URI.open(source) do |f|
  f.each_line do |l|
    l.strip!
    next unless l =~ /^[0-9]/
    next if l =~ /HOLIDAY.*HOLIDAY/
    fields = l.split(/\s*,\s*/)
    next unless fields[9] =~ /^[0-9.]*$/
    date, oz, tonnes = Date.parse(fields[0]), BigDecimal(fields[9]), BigDecimal(fields[10])
    data << [date, tonnes, oz]
  end
end

puts <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link href="c3.css" rel="stylesheet">
    <script src="d3.v5.min.js" charset="utf-8"></script>
    <script src="c3.min.js"></script>
    <style>
      #graph { margin: 2em 1em; }
      table { border: 2px solid black; border-collapse: collapse; }
      table th { border: 1px solid #aaa; padding: 0.2em 0.5em; }
      table th:not([colspan]) { border-bottom: 2px solid black; }
      table td { text-align: right; border: 1px solid #aaa; padding: 0.2em 0.5em; }
      footer { padding-top: 1em; border-top: 1px solid #aaa; margin-top: 2em; text-align: center; color: #aaa; font-size: 70%; }
      footer a { color: #aaa; }
    </style>
    <title>GLD tonnage</title>
  </head>
  <body>
    <h1>GLD tonnage</h1>
    <h2>Graph</h2>
    <div id="graph"></div>
    <script>
    var chart = c3.generate({
  bindto: '#graph',
  size: {
      height: 600,
  },
  data: {
    x: 'x',
   columns: [
     ['x',
#{data.reverse.map { |x| x[0].strftime("%Y-%m-%d").inspect }.join(", ")}
     ],
     ['tonnes',
#{data.reverse.map { |x| "%.02f" % x[1] }.join(", ")}
     ]
   ],
  },
  point: {
   show: false
  },
  axis: {
   x: {
    type: 'timeseries',
    tick: {
     format: '%Y-%m-%d'
    },
   },
   y: {
    tick: {
	format: d3.format('.2f'),
    },
    label: {
	text: 'tonnes',
	position: 'outer-middle'
    },
   },
  },
 });
    </script>
    <h2>Timeseries</h2>
    <table>
      <tr><th>Date</th><th>Tonnage</th><th>Troy OZ</th><th>Δ Tonnage</th><th>Δ Troy OZ</th></tr>
EOF

def color_for(x)
  if x > 0
    "color: green;"
  elsif x < 0
    "color: red;"
  else
    ""
  end
end
dr = data.reverse
dr.zip(dr[1..-1]).each do |(date, t, oz), (d2, t2, oz2)|
  puts "<tr>"
  puts "<td>#{date.strftime("%Y-%m-%d")}</td><td>#{"%.02f" % t}</td><td>#{"%.02f" % oz}</td>"
  if d2
    puts "<td style=\"#{color_for(t-t2)}\">#{"%.02f" % (t-t2)}</td><td style=\"#{color_for(t-t2)}\">#{"%.02f" % (oz-oz2)}</td>"
  else
    puts "<td>&nbsp;</td><td>&nbsp;</td>"
  end
  puts "</tr>"
end
puts <<EOF
    </table>
    <footer>Generated at #{Time.now.gmtime.strftime("%Y-%m-%d %H:%M:%S GMT")}.</footer>
  </body>
</html>
EOF
