require 'benchmark'
require 'optparse'
require 'fileutils'

require 'kramdown'

options = {:others => false}
OptionParser.new do |opts|
  opts.on("-o", "--[no-]others", "Generate data for other parsers") {|v| options[:others] = v}
  opts.on("-g", "--[no-]graph", "Generate graph") {|v| options[:graph] = v}
  opts.on("-k VERSION", "--kramdown VERSION", String, "Add benchmark data for kramdown version VERSION") {|v| options[:kramdown] = v}
end.parse!


THISRUBY = (self.class.const_defined?(:RUBY_DESCRIPTION) ? RUBY_DESCRIPTION.scan(/^.*?(?=\s*\()/).first.sub(/\s/, '-') : "ruby-#{RUBY_VERSION}") + '-' + RUBY_PATCHLEVEL.to_s

Dir.chdir(File.dirname(__FILE__))
BMDATA = File.read('mdbasics.text')
MULTIPLIER = (0..5).map {|i| 2**i}

if options[:others]
  require 'maruku'
  require 'maruku/version'
  begin
    require 'rdiscount'
  rescue LoadError
  end
  #require 'bluefeather'

  module MaRuKu::Errors
    def tell_user(s)
    end
  end

  bmdata = {}
  labels = []
  MULTIPLIER.each do |i|
    $stderr.puts "Generating benchmark data for other parsers, multiplier #{i}"
    mddata = BMDATA*i
    labels = []
    bmdata[i] = Benchmark::bmbm do |x|
      labels << "Maruku #{MaRuKu::Version}"
      x.report { Maruku.new(mddata, :on_error => :ignore).to_html }
      if self.class.const_defined?(:BlueFeather)
        labels << "BlueFeather #{BlueFeather::VERSION}"
        x.report { BlueFeather.parse(mddata) }
      end
      if self.class.const_defined?(:RDiscount)
        labels << "RDiscount #{RDiscount::VERSION}"
        x.report { RDiscount.new(mddata).to_html }
      end
    end
  end
  File.open("static-#{THISRUBY}.dat", 'w+') do |f|
    f.puts "# " + labels.join(" || ")
    format_str = "%5d" + " %10.5f"*bmdata[MULTIPLIER.first].size
    bmdata.sort.each do |m,v|
      f.puts format_str % [m, *v.map {|tms| tms.real}]
    end
  end
end

if options[:kramdown]
  kramdown = "kramdown-#{THISRUBY}.dat"
  data = if File.exist?(kramdown)
           lines = File.readlines(kramdown).map {|l| l.chomp}
           lines.first << " || "
           lines
         else
           ["#      ", *MULTIPLIER.map {|m| "%3d" % m}]
         end
  data.first << "#{options[:kramdown]}".rjust(10)
  MULTIPLIER.each_with_index do |m, i|
    $stderr.puts "Generating benchmark data for kramdown version #{options[:kramdown]}, multiplier #{m}"
    mddata = BMDATA*m
    begin
      data[i+1] << "%14.5f" % Benchmark::bmbm {|x| x.report { Kramdown::Document.new(mddata).to_html } }.first.real
    rescue
      $stderr.puts $!.message
      data[i+1] << "%14.5f" % 0
    end
  end
  File.open(kramdown, 'w+') do |f|
    data.each {|l| f.puts l}
  end
end

if options[:graph]
  Dir['kramdown-*.dat'].each do |kramdown_name|
    theruby = kramdown_name.sub(/^kramdown-/, '').sub(/\.dat$/, '')
    graph_name = "graph-#{theruby}.png"
    static_name = "static-#{theruby}.dat"
    kramdown_names = File.readlines(kramdown_name).first.chomp[1..-1].split(/\s*\|\|\s*/)
    static_names = (File.exist?(static_name) ? File.readlines(static_name).first.chomp[1..-1].split(/\s*\|\|\s*/) : [])
    File.open("gnuplot.dat", "w+") do |f|
      f.puts <<EOF
set title "Execution Time Performance for #{theruby}"
set xlabel "File Multiplier (i.e. n times mdbasic.text)"
set ylabel "Execution Time in secondes"
set key left top
set grid "on"
set terminal png
set output "#{graph_name}"
EOF
      f.print "plot "
      i, j = 1, 1
      f.puts((kramdown_names.map {|n| i += 1; "\"#{kramdown_name}\" using 1:#{i} with lp title \"#{n}\""} +
              static_names.map {|n| j += 1; n =~ /bluefeather/i ? nil : "\"#{static_name}\" using 1:#{j} with lp title \"#{n}\""}.compact
             ).join(", "))
    end
    `gnuplot gnuplot.dat`
    FileUtils.rm("gnuplot.dat")
  end
end
