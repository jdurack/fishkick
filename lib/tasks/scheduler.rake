task :calculate_fish_scores => :environment do
  puts 'Running!'
  siteFishInfos = SiteFishInfo.where(is_active: true)
  
  siteFishInfos.each do |sfi|
    today = Date.today
    thisMonthIndex = ( today.month - 1 )
    value = sfi['month_value_' + thisMonthIndex.to_s]
    fishScore = FishScore.new({:site_id => sfi.site_id, :fish_id => sfi.fish_id, :date => Date.today, :value => value })
    fishScore.save
  end
end