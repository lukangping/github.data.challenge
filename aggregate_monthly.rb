require 'pp'
require 'open-uri'
require 'zlib'
require 'yajl'

TYPES = ["CommitCommentEvent",
  "CreateEvent",
  "DeleteEvent",
  "DownloadEvent",
  "FollowEvent",
  "ForkEvent",
  "ForkApplyEvent",
  "GistEvent",
  "GollumEvent",
  "IssueCommentEvent",
  "IssuesEvent",
  "MemberEvent",
  "PublicEvent",
  "PullRequestEvent",
  "PullRequestReviewCommentEvent",
  "PushEvent",
  "TeamAddEvent",
  "WatchEvent"]

NUM_TYPES = TYPES.length

start = Time.now

hours = 0..23
days = 1..31
months = 1..12
years = 2012..2013
data = {}
for y in years
  for m in months
    languages = {}
    for d in days
      for h in hours
        begin
          time = "#{y}-#{'%02d' % m}-#{'%02d' % d}-#{h}"
          gz = open("rawdata/#{time}.json.gz")
          js = Zlib::GzipReader.new(gz).read

          Yajl::Parser.parse(js) do |event|
            repo = event["repository"]
            next if repo.nil?
            lang = repo["language"]
            unless languages.keys.include? lang
              languages[lang] = Array.new(NUM_TYPES, 0)
            end
            languages[lang][TYPES.index(event["type"])] += 1
          end
        rescue
        end
      end 
    end
    data["#{y}#{'%02d' % m}"] = languages
  end
end

endt = Time.now

# pp data
pp "#{(endt-start)}s"

File.open("output/last-year-monthly.csv", 'w') do |file| 
  file.write("time,language,#{TYPES.join(',')}") 
  file.write("\n")  
  data.each do |time, languages|
    languages.each do |lang, value|
      unless lang.nil? || lang.empty?
        file.write("#{time},#{lang},#{value.join(',')}") 
        file.write("\n")
      end
    end
  end
end
