RedmineApp::Application.routes.draw do
  post "/projects/:id/embedded/upload", :to => "redmine_embedded#upload", :as => :upload_embedded
  get 'projects/:id/embedded(/*request_path(.:format))', :to => "redmine_embedded#index", :as => :show_embedded
end
