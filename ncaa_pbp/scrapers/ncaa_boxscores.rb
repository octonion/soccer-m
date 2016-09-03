#!/usr/bin/env ruby

require 'csv'

require 'mechanize'

agent = Mechanize.new{ |agent| agent.history.max_size=0 }
agent.user_agent = 'Mozilla/5.0'
agent.robots = false

year = ARGV[0].to_i
division = ARGV[1]

class String
  def to_nil
    self.empty? ? nil : self
  end
end


base_url = 'http://stats.ncaa.org'
#base_url = 'http://anonymouse.org/cgi-bin/anon-www.cgi/stats.ncaa.org'

boxscores_xpath = '//*[@id="contentarea"]/table[position()>4]/tr[position()>2]'

#'//*[@id="contentArea"]/table[5]/tbody/tr[1]/td'

#periods_xpath = '//table[position()=1 and @class="mytable"]/tr[position()>1]'

nthreads = 1

base_sleep = 0
sleep_increment = 3
retries = 4

ncaa_team_schedules = CSV.open("csv/ncaa_team_schedules_#{year}_#{division}.csv", "r", {:col_sep => "\t", :headers => TRUE})
ncaa_games_boxscores = CSV.open("csv/ncaa_boxscores_#{year}_#{division}.csv", "w", {:col_sep => "\t"})

# Headers

boxscores_header = [
  "game_id", "section_id",
  "player_id", "player_name", "player_url",
  "position",
  "goals", "assists", "sh_att", "sog",
  "fouls", "red_cards", "yellow_cards",
  "gc", "goal_app", "ggs",
  "goalie_min_plyd",
  "ga", "saves", "shutouts",
  "g_wins", "g_loss", "dsaves", "corners"
]

ncaa_games_boxscores << boxscores_header

# Get game IDs

game_ids = []
ncaa_team_schedules.each do |game|
#  if not(game["game_id"].to_i==3495039)
#    next
#  end
  game_ids << game["game_id"]
end

# Pull each game only once
# Modify in-place, so don't chain

game_ids.compact!
game_ids.sort!
game_ids.uniq!

# Randomize

#game_ids.shuffle!

#game_ids = game_ids[0..199]

n = game_ids.size

gpt = (n.to_f/nthreads.to_f).ceil

threads = []

game_ids.each_slice(gpt).with_index do |ids,i|

  threads << Thread.new(ids) do |t_ids|

    found = 0
    n_t = t_ids.size

    t_ids.each_with_index do |game_id,j|

      sleep_time = base_sleep

      #http://stats.ncaa.org/game/box_score/3038494?year_stat_category_id=10461

      game_url = 'http://stats.ncaa.org/game/box_score/%d' % [game_id]

#      print "Thread #{thread_id}, sleep #{sleep_time} ... "
      #      sleep sleep_time

      broken1 = "\\\">\r\n      <SHOTS G="
      broken2 = "\\\"><SHOTS G="
      tries = 0
      begin
        doc = agent.get(game_url).body
        doc = doc.gsub(broken1,"")
        doc = doc.gsub(broken2,"")
        page = Nokogiri::HTML(doc)
      rescue
        sleep_time += sleep_increment
#        print "sleep #{sleep_time} ... "
        sleep sleep_time
        tries += 1
        if (tries > retries)
          next
        else
          retry
        end
      end

      sleep_time = base_sleep

      found += 1

      print "#{i}, #{game_id} : #{j+1}/#{n_t}; found #{found}/#{n_t}\n"

      page.xpath(boxscores_xpath).each do |row|

        table = row.parent
        section_id = table.parent.xpath('table[position()>1 and @class="mytable"]').index(table)

        player_id = nil
        player_name = nil
        player_url = nil

        field_values = []
        row.xpath('td').each_with_index do |element,k|
          case k
          when 0
            raw = element.text.strip

            #"\u00A0"
            #gsub(/\302\240/,"")
            player_name = element.text.strip.gsub("\u00A0","") rescue nil
            link = element.search("a").first

            if not(link.nil?)

              link_url = link.attributes["href"].text
              
              parameters = link_url.split("/")[-1]

              # Player ID

              player_id = parameters.split("=")[2]

              # Player URL

              player_url = base_url+link_url

            end
          when 1
            field_values += [element.text.strip]
          else
            field_values += [element.text.strip.to_i]
          end
        end

        ncaa_games_boxscores << [game_id, section_id, player_id, player_name,
                                 player_url] + field_values

      end

    end

  end

end

threads.each(&:join)

#parts.flatten(1).each { |row| ncaa_play_by_play << row }

ncaa_games_boxscores.close
