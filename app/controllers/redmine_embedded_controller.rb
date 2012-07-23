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

require 'iconv'

class DataFile < ActiveRecord::Base
  def self.save(directory, zipname, upload)
    path = File.join(directory, zipname)
    File.open(path, "wb") { |f| f.write(upload['datafile'].read) }
  end
end

class RedmineEmbeddedController < ApplicationController
  class RedmineEmbeddedControllerError < StandardError; end
  
  unloadable
  layout 'base'
  before_filter :find_project, :authorize
  
  def index
    file = params[:request_path]
    path = get_real_path(file)
    if File.directory?(path)
      file = get_index_file(path)
      target = file || []
      #target << file
      # Forces redirect to the index file when the requested path is a directory
      # so that relative links in embedded html pages work
      redirect_to :request_path => target
      return
    end
    
    # Check file extension
    raise RedmineEmbeddedControllerError.new('This file can not be viewed (invalid extension).') unless Redmine::Plugins::RedmineEmbedded.valid_extension?(path)
    
    if Redmine::MimeType.is_type?('image', path)
      send_file path, :disposition => 'inline', :type => Redmine::MimeType.of(path)
    else
      embed_file path
    end
    
  rescue Errno::ENOENT => e
    @content = "No documentation found"
    @title = ""
    render :index
  rescue Errno::EACCES => e
    # Can not read the file
    render_error "Unable to read the file: #{e.message}"
  rescue RedmineEmbeddedControllerError => e
    render_error e.message
  end

  def upload
    if params[:upload]
      file = params[:upload]
      zipname = sanitize_filename(params[:upload]['datafile'].original_filename)
      if ["zip"].include?(File.extname(zipname).downcase[1..-1])
        dir = get_project_directory.gsub("/html", "")
        if File.directory? dir
          `rm -rf #{dir}/*` #clean up any exisiting docs
        else
         Dir.mkdir dir 
        end
        filename = DataFile.save(dir, zipname, params[:upload])
        Dir.chdir(dir)
        `unzip #{zipname}`
        redirect_to show_embedded_url(@project), :notice => "Documentation uploaded"
      else 
        render :index, :error => "File must be ZIP format"
      end
    else
      render :index, :error => "No file uploaded"
    end
  end
  
  private
  
  def sanitize_filename(file_name)
    # get only the filename, not the whole path (from IE)
    just_filename = File.basename(file_name) 
    # replace all none alphanumeric, underscore or perioids
    # with underscore
    just_filename.sub(/[^\w\.\-]/,'_') 
  end
  
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Return the path to the html root directory for the current project
  def get_project_directory
    @project_directory ||= Setting.plugin_redmine_embedded['path'].to_s.gsub('{PROJECT}', @project.identifier)
  end
  
  # Returns the absolute path of the requested file
  # Parameter is an Array
  def get_real_path(path)
    real = get_project_directory
    real = File.join(real, path) unless path.nil? || path.empty?
    dir = File.expand_path(get_project_directory)
    real = File.expand_path(real)
    raise Errno::ENOENT unless real.starts_with?(dir) && File.exist?(real)
    real
  end
  
  # Returns the index file in the given directory
  # and raises an exception if none is found
  def get_index_file(dir)
    indexes = Setting.plugin_redmine_embedded['index'].to_s.split
    file = indexes.find {|f| File.exist?(File.join(dir, f))}
    raise RedmineEmbeddedControllerError.new("No index file found in #{dir} (#{indexes.join(', ')}).") if file.nil?
    file
  end
  
  # Renders a given HTML file
  def embed_file(path)
    @content = File.read(path)
    
    # Extract html title from embedded page
    if @content =~ %r{<title>([^<]*)</title>}mi
      @title = $1.strip
    end
    
    # Keep html body only
    @content.gsub!(%r{^.*<body[^>]*>(.*)</body>.*$}mi, '\\1')
    
    # Re-encode content if needed
    source_encoding = Setting.plugin_redmine_embedded['encoding'].to_s
    unless source_encoding.blank?
      begin; @content = Iconv.new('UTF-8', source_encoding).iconv(@content); rescue; end
    end
    
    @doc_template = Redmine::Plugins::RedmineEmbedded.detect_template_from_path(path)
    render :action => 'index'
  end
end
