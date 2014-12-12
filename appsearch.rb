require 'csv'
require 'json'

require 'sinatra'

require 'open-uri' 

require 'itunes-search-api'
require 'market_bot'

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

post '/search' do
  query = request[:query]

  itunes  = ITunesSearchAPI.search term: query, limit: 200, media: 'software', entity: 'software'
  play    = MarketBot::Android::SearchQuery.new(query).update.results

  market_names = %w(itunes play)
  unix_time = Time.now.to_i
  
  files = market_names.map { |mn| "tmp/#{query}_#{mn}_#{unix_time}.csv" }
    
  artwork = []

  [itunes, play].each_with_index do |store_results, idx|
    CSV.open(files[idx], "w") do |csv|
      store_results.each_with_index do |hash, idx|
        if idx == 0
          csv << hash.keys
        else
          csv << hash.values
          artwork << hash["artworkUrl60"]
        end
      end
    end
  end
  

  puts artwork.compact!
  puts artwork.count
  iconsDownloader(artwork)

  files.map! {|file| file.gsub('tmp/', 'file/') }
  files.to_json
end

get '/file/*' do |file|
  send_file "tmp/" + file
end


def iconsDownloader(artwork=[])
   if artwork.count == 0 
     puts "Error Empty artwork!!"
   else
     artwork.each_with_index do |name, idx|
       puts "File to be downloaded: #{name}"
       File.open("tmp/icons/#{idx}.png", "wb") do |saved_file|
        open(name,"rb") do |read_file|
          saved_file.write(read_file.read)
        end
      end
     end
   end
end
