require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'
require 'pry-byebug'

def clean_zipcode(zipcode)
    #if the zip code is exactly five digits, assume that it is ok
    #if the zip code is more than five digits, truncate it to the first five digits
    #if the zip code is less than five digits, add zeros to the front until it becomes five digits
    zipcode.to_s.rjust(5,'0')[0..4]
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin  
        legislators = civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials

    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_phone_number(phone_number)
    phone_number = phone_number.gsub(/[^0-9]/,'').to_s
    if phone_number.length ==11 && phone_number.chr == '1'
        phone_number[1..-1]
    elsif phone_number.length != 10 
        phone_number = ''
    end
    phone_number.rjust(10,'0')
end
def find_peak(reg_dates,n,criteria)
    if criteria == 'hour'
        reg = reg_dates.map {|date| date = Time.strptime(date,'%m/%d/%y %k:%M').hour}
    else

        reg = reg_dates.map do|date|
            #date = date.split(' ')[0] 
            date = Date.strptime(date,'%m/%d/%y').wday
        end
    end

    occurence = reg.tally
    max_occurence = occurence.values.max(n)  
    peak = []
    occurence.each do |i,o|
        peak.push(i) if max_occurence.include?(o)
    end
    peak
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_dates = []
contents.each do |row|
    id = row[0]
    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])
    
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id,form_letter) 
    
    phone_number = clean_phone_number(row[:homephone])
    
    reg_dates.push(row[:regdate])
end

peak = find_peak(reg_dates,2,'day')
p peak
