require_dependency 'issues_controller'

module IssuesControllerPatch
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method_chain :destroy, :hook
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def destroy_with_hook
      call_hook(:controller_issues_before_delete, {:id => params[:id], :issues => @issues})
      return destroy_without_hook
    end
  end

end