require 'redmine'
require 'redmine_embedded'

Redmine::Plugin.register :redmine_embedded do
  name 'Redmine Embedded Documentation' 
  author 'Jean-Philippe Lang, Reuben Mallaby'
  description 'Embed various documentations in your projects'
  version '0.0.2'
  settings  :partial => 'settings/redmine_embedded',
            :default => { 'path' => '/var/doc/{PROJECT}/html',
                         'index' => 'main.html overview-summary.html index.html',
                         'extensions' => 'html png gif',
                         'template' => '',
                         'encoding' => '',
                         'menu' => 'Embedded' }
  project_module :redmine_embedded do
    permission :view_embedded_doc, {:redmine_embedded => :index}
    permission :edit_embedded_doc, {:redmine_embedded => :upload}
  end
  menu :project_menu, :redmine_embedded,
    { 
      :controller => "redmine_embedded", 
      :action => "index"
    },
    :caption => Proc.new { Setting.plugin_redmine_embedded['menu'] },
    :if => Proc.new { !Setting.plugin_redmine_embedded['menu'].blank? }
end

