require "xcprofiler/derived_data"
require "xcprofiler/exceptions"
require "xcprofiler/execution"
require "xcprofiler/profiler"
require "xcprofiler/version"
require "xcprofiler/reporters/abstract_reporter"
require "xcprofiler/reporters/standard_output_reporter"
require "xcprofiler/reporters/json_reporter"
require "colorize"
require "optparse"
require "ostruct"

module Xcprofiler
  class << self
    def execute(args)
      options = OpenStruct.new
      options.order = :time
      options.reporters = [:standard_output]

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: xcprofiler [product name or .xcactivitylog file] [options]".red

        opts.on("--[no-]show-invalids", "Show invalid location results") { |v| options.show_invalid_locations = v }
        opts.on("-o [ORDER]", [:default, :time, :file, :absolute_path], "Sort order") { |v| options.order = v }
        opts.on("-l", "--limit [LIMIT]", Integer, "Limit for display") { |v| options.limit = v }
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end
      parser.parse!(args)

      target = args.pop
      unless target
        puts parser
        exit 1
      end

      order = options[:order] or :time

      begin
        if target.end_with?('.xcactivitylog')
          profiler = Profiler.by_path(target)
        else
          profiler = Profiler.by_product_name(target)
        end
        profiler.reporters = [
          StandardOutputReporter.new(limit: options[:limit],
                                     order: order,
                                     show_invalid_locations: options[:show_invalid_locations])
        ]
        profiler.report!
      rescue Exception => e
        puts e.message.red
      end
    end
  end
end
