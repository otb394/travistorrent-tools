# Receives the language and a project directory and tries to dispatch the analysis of the logfiles to the correct
# analyzers
require 'csv'

load 'lib/log_file_analyzer.rb'
load 'lib/languages/java_log_file_analyzer_dispatcher.rb'
load 'lib/languages/ruby_log_file_analyzer.rb'


def array_of_hashes_to_csv(array_of_hashes)
  CSV.generate do |csv|
    csv << array_of_hashes.first.keys
    array_of_hashes.each { |hash| csv << hash.values }
  end
end

if (ARGV[0].nil?)
  puts 'Missing argument(s)!'
  puts ''
  puts 'usage: buildlog_analyzer_dispatcher.rb directory'
  exit(1)
end

directory = ARGV[0]
results = Array.new

puts "Starting to analyze buildlogs from #{ARGV[0]} ..."

# dir foreach is much faster than Dir.glob, because the latter builds an array of matched files up-front
Dir.foreach(directory) do |logfile|
  next if logfile == '.' or logfile == '..' or File.extname(logfile) != '.log'

  # begin
  file = "#{directory}/#{logfile}"

  analyzer = LogFileAnalyzer.new file
  analyzer.split
  analyzer.analyze_primary_language
  lang = analyzer.primary_language.downcase

  if lang == 'ruby'
    analyzer = RubyLogFileAnalyzer.new file
  elsif lang == 'java'
    analyzer = JavaLogFileAnalyzerDispatcher.new file, analyzer.logFile
  else
    next
  end

  analyzer.analyze
  results << analyzer.output
  # rescue Exception => e
  #  puts "Error analyzing #{logfile}, rescued"
  # puts e
  # end
end

if !results.empty?
  csv = array_of_hashes_to_csv results
  File.open("#{directory}/buildlog-data-travis.csv", 'w') { |file|
    file.puts csv
  }
end
