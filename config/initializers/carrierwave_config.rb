CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',                        # required
    :aws_access_key_id      => ENV['FISHKICK_AWS_KEY'],                        # required
    :aws_secret_access_key  => ENV['FISHKICK_AWS_SECRET'],                        # required
    :region                 => 'us-west-2',                  # optional, defaults to 'us-east-1'
    :host                   => 'fishkick-' + ENV['FISHKICK_AWS_SUFFIX'] + '.s3-website-us-west-2.amazonaws.com', # optional, defaults to nil
    :endpoint               => 'https://fishkick-' + ENV['FISHKICK_AWS_SUFFIX'] + '.s3-website-us-west-2.amazonaws.com:8080' # optional, defaults to nil
  }
  config.fog_directory  = 'fishkick-' + ENV['FISHKICK_AWS_SUFFIX'] # required
  config.fog_public     = false                                   # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end