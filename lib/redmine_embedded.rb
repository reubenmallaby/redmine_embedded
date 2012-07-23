# Redmine - project management software
# Copyright (C) 2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module Plugins
    module RedmineEmbedded
      class << self
        
        # Returns an Array of available templates
        def available_templates
          assets_by_template.keys.sort
        end
        
        # Returns the assets for a given template
        def assets(template)
          assets_by_template.has_key?(template) ? assets_by_template[template] : []
        end
        
        def detect_template_from_path(path)
          t = path.to_s.split(%r{[/\\]}) & available_templates
          t.empty? ? Setting.plugin_redmine_embedded['template'].to_s : t.first
        end
        
        def valid_extension?(path)
          extensions = Setting.plugin_redmine_embedded['extensions'].to_s.split.each(&:downcase)
          extensions.include?(File.extname(path).downcase[1..-1])
        end

        private
        
        # A Hash of available assets by template
        def assets_by_template
          @@assets_by_template ||= scan_assets
        end
        
        # Scans assets directory for templates
        # and returns a Hash of available assets by template
        def scan_assets
          a = Hash.new {|h,k| h[k] = [] }
          Dir.glob(File.join(File.dirname(__FILE__), '../assets/*/*.{css,js}')).each do |asset|
            asset = File.basename(asset)
            template = asset.gsub(%r{\.(js|css)$}, '')
            a[template] << asset
          end
          a
        end
      end
    end
  end
end

class << RedmineApp::Application;self;end.class_eval do
  define_method :clear!, lambda {}
end

