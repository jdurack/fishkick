class Guide < ActiveRecord::Base

  mount_uploader :primary_image, GuidePrimaryImageUploader

  def getFullName()
    if !self.first_name.blank? and !self.last_name.blank?
      return self.first_name.strip + ' ' + self.last_name.strip
    elsif !self.first_name.blank?
      return self.first_name.strip
    elsif !self.last_name.blank?
      return 'M. ' + self.last_name.strip
    end
    return nil
  end
end
