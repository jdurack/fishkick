class FishScore < ActiveRecord::Base
  belongs_to :site
  belongs_to :fish


  def self.calculateAndSaveFishScore( site_fish_info, date ) # Static ("self." makes it so)
    thisMonthIndex = ( date.month - 1 )
    value = (site_fish_info['max_score'].to_f / Settings.max_fish_score) * site_fish_info['month_value_' + thisMonthIndex.to_s].to_f
    scalingFactor = getDischargeRateFishScoreScalingFactor( site_fish_info, date )
    value = value * scalingFactor

    findParams = {:site_id => site_fish_info.site_id, :fish_id => site_fish_info.fish_id, :date => date}
    fishScoreData = findParams.merge({ :value => value })
    fishScore = FishScore.find_or_initialize_by(findParams)
    fishScore.update(fishScoreData)
  end

  # Should return a value between 0 and 1 for what to scale the ideal fish score value by
  # based on discharge rates
  def self.getDischargeRateFishScoreScalingFactor( site_fish_info, date ) # Static ("self." makes it so)
    site = site_fish_info.site
    
    unless site.min_stream_flow_cfs or site.max_stream_flow_cfs
      return 1
    end
    medianDischargeRate = getMedianDischargeRate site, date
    if medianDischargeRate.blank?
      return 1
    end

    scalingFactor = 1

    if site.min_stream_flow_cfs and ( medianDischargeRate < site.min_stream_flow_cfs )
      difference = site.min_stream_flow_cfs - medianDischargeRate
      percentageDifference = difference / site.min_stream_flow_cfs
      effectFactor = 2 # So if it's 50% off, it's 100% reduced
      discountFactor = percentageDifference * effectFactor
      scalingFactor = 1 - discountFactor
    end

    if site.max_stream_flow_cfs and ( medianDischargeRate > site.max_stream_flow_cfs )
      difference = medianDischargeRate - site.max_stream_flow_cfs
      percentageDifference = difference / site.max_stream_flow_cfs
      effectFactor = 2 # So if it's 50% off, it's 100% reduced
      discountFactor = percentageDifference * effectFactor
      scalingFactor = 1 - discountFactor
    end

    if scalingFactor < 0
      return 0
    elsif scalingFactor > 1
      return 1
    end

    puts 'min: ' + site.min_stream_flow_cfs.to_s + ', max: ' + site.max_stream_flow_cfs.to_s + ', median: ' + medianDischargeRate.to_s + ', scalingFactor: ' + scalingFactor.to_s

    return scalingFactor
  end

  def self.getMedianDischargeRate( site, date ) # Static ("self." makes it so)
    whereString = "site_id = " + site.id.to_s
    whereString += " AND datetime >= '" + date.to_s + "'"
    whereString += " AND datetime <= '" + ( date + 1 ).to_s + "'"

    # This makes an assumption that this setting won't change.  I put a note there.
    whereString += " AND report_data_parameter_id = " + Settings.report.report_data_parameter_id.to_s

    usgsData = ReportData.where(whereString)
    puts 'whereString: ' + whereString + ', usgsData: ', usgsData.inspect

    unless usgsData.length > 0
      return nil
    end
    sortedData = usgsData.sort_by {|datum| datum.value}
    if sortedData.length.odd?
      median = sortedData[(sortedData.length/2).floor].value
    else
      median = ( sortedData[(sortedData.length/2).floor].value + sortedData[(sortedData.length/2).ceil].value ) / 2
    end
    puts 'min: ' + sortedData[0].value.to_s + ', median: ' + median.to_s + ', max: ' + sortedData[sortedData.length - 1].value.to_s
    return median
  end
end
