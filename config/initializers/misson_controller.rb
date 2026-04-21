Rails.application.configure do
  if ENV["ISAAC_MISSION_CONTROL_PASSWORD"]
    MissionControl::Jobs.http_basic_auth_user = "isaac-admin"
    MissionControl::Jobs.http_basic_auth_password = ENV["ISAAC_MISSION_CONTROL_PASSWORD"]
  end
end
