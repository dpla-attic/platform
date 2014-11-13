# Patch for reflected XSS vulnerability in twitter-bootstrap-rails
# source: https://gist.github.com/forced-request/9772316
# more info: http://blog.nvisium.com/2014/03/reflected-xss-vulnerability-in-twitter.html

module BootstrapFlashHelperPatched
  ALERT_TYPES = [:error, :info, :success, :warning] unless const_defined?(:ALERT_TYPES)

  def bootstrap_flash_patched
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = type.to_sym
      type = :success if type == :notice
      type = :error   if type == :alert
      next unless ALERT_TYPES.include?(type)

      Array(message).each do |msg|
        text = content_tag(:div,
                           content_tag(:button, raw("&times;"), :class => "close", "data-dismiss" => "alert") +
                           msg, :class => "alert fade in alert-#{type}")
        flash_messages << text if msg
      end
    end
    flash_messages.join("\n").html_safe
  end
end