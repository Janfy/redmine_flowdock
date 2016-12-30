Redmine::Plugin.register :redmine_flowdock do
  name 'Flowdock'
  author 'Janfy'
  description 'Notify your Flowdock flow about Redmine events'
  version '2.0.0'
  url 'https://github.com/Janfy/redmine_flowdock'

  Rails.configuration.to_prepare do
    require_dependency 'flowdock_listener'
    require_dependency 'flowdock_renderer'

    unless IssuesController.included_modules.include?(IssuesControllerPatch)
      IssuesController.send(:include, IssuesControllerPatch)
    end

  end

  settings :partial => 'settings/redmine_flowdock',
    :default => {
      :api_token => {}
    }
end
