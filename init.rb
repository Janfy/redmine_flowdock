Redmine::Plugin.register :redmine_flowdock do
  name 'Flowdock'
  author 'Janfy'
  description 'Notify your Flowdock flow about Redmine events'
  version '2.0.2'
  url 'https://github.com/Janfy/redmine_flowdock'

  Rails.configuration.to_prepare do
    require_dependency 'flowdock_listener'
    require_dependency 'flowdock_renderer'

    unless IssuesController.included_modules.include?(IssuesControllerPatch)
      IssuesController.send(:include, IssuesControllerPatch)
    end

  end

  default_settings = {
      :api_token => {},
      :color => {
          '1' => 'lime',
          '2' => 'blue',
          '3' => 'green',
          '4' => 'orange',
          '5' => 'grey',
          '6' => 'black',
          :deleted => 'red'
      }
  }

  default_settings = ActionController::Parameters.new(default_settings)

  settings :partial => 'settings/redmine_flowdock',
           :default => default_settings
end
