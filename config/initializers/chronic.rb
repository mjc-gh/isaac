# Chronic monkey patch for timezones
def Chronic.parse_in_zone(string)
  old_time_class = Chronic.time_class
  Chronic.time_class = Time.zone
  Chronic.parse(string)
ensure
  Chronic.time_class = old_time_class
end
