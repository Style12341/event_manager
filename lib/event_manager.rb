# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'
CSV_PATH = 'event_attendees_full.csv'
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  civic_info.representative_info_by_address(
    address: zipcode,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  ).officials
rescue StandardError
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(number)
  number = number.split('').reject { |digit| /[0-9]/.match(digit).nil? }
  number = number.join
  if number.length < 10 || number.length > 11 || (number.length == 11 && number[0] != '1')
    'Bad number'
  else
    number.length == 11 ? number[1..] : number
  end
end

def get_popular_time(time_array)
  time_hash = Hash.new(0)
  time_array.each do |time|
    time_hash[Time.parse(time).hour] += 1
  end
  time_hash.max_by { |_key, value| value }[0]
end

def get_popular_day(day_array)
  day_hash = Hash.new(0)
  day_array.each do |day|
    day_hash[Date.strptime(day, '%m/%d/%Y').strftime('%A')] += 1
  end
  day_hash.max_by { |_key, value| value }[0]
end

def get_column_csv(path, header)
  column_data = []
  data = CSV.open(
    path,
    headers: true,
    header_converters: :symbol
  )
  data.each do |row|
    column_data.push(row[header])
  end
  column_data
end

puts 'EventManager initialized.'

contents = CSV.open(
  CSV_PATH,
  headers: true,
  header_converters: :symbol
)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_num = clean_phone_number(row[:homephone])
  # legislators = legislators_by_zipcode(zipcode)

  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
end

date_column = get_column_csv(CSV_PATH, :regdate)
times = []
days = []
date_column.each do |date|
  days << date.split(' ')[0]
  times << date.split(' ')[1]
end
popular_day = get_popular_day(days)
popular_time = get_popular_time(times)
puts "Most popular day : #{popular_day}"
puts "Most popular hour : #{popular_time}"
