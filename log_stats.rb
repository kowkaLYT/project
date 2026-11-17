require 'csv'
require 'fileutils'

LOG_FILE = 'data/app.log'
OUTPUT_FILE = 'output/stats.csv'

pattern = /\A(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (?<level>INFO|WARN|ERROR) (?<message>.+)\z/

counts = {
  'INFO' => 0,
  'WARN' => 0,
  'ERROR' => 0
}

invalid = 0
total = 0

error_messages = Hash.new(0)

File.foreach(LOG_FILE) do |line|
  total += 1

  match = pattern.match(line.chomp)

  if match
    level = match[:level]
    message = match[:message]

    counts[level] += 1

    if level == 'ERROR'
      error_messages[message] += 1
    end
  else
    invalid += 1
  end
end

unless counts.values.sum + invalid == total
  raise 'Error: log statistics do not match!'
end

top_errors = error_messages.sort_by { |message, count| [-count, message] }.first(3)

FileUtils.mkdir_p('output')

CSV.open(OUTPUT_FILE, 'w') do |csv|
  csv << ['metric', 'count']

  counts.each do |level, count|
    csv << [level, count]
  end

  csv << ['INVALID', invalid]
  csv << ['TOTAL', total]

  top_errors.each do |message, count|
    csv << ["top_error:#{message}", count]
  end
end

puts "Statistics saved to #{OUTPUT_FILE}"