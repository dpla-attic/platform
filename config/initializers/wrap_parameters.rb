# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
# Disabled because it was polluting the controller params hash when Content-Type was set to application/json
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end

# Disable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
