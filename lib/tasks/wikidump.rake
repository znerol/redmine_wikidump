namespace :wikidump do
  def export_wiki(project, template, path)
    pages = project.wiki.pages.
                    order('title').
                    includes([:content, {:attachments => :author}]).
                    to_a

    assigns = {
      :wiki => project.wiki,
      :project => project,
      :pages => pages,
    }
    view = ActionView::Base.new(ActionController::Base.view_paths, assigns, ActionController::Base.new)

    view.class_eval do
      include Rails.application.routes.url_helpers
      include ApplicationHelper
      include WikiHelper

      def url_options
        {host: Setting.host_name.split('/')[0]}
      end
    end

    File.open(path, "wb") do |f|
      f.write(view.render(:template => template))
    end
  end

  desc <<-END_DESC
Dump the wiki of a project to a PDF file.

Available options:
  * project   => id or identifier of project (defaults to first projects)
  * directory => output directory (defaults to rails temporary directory)

Example:
  rake wikidump:pdf project=1 directory=/home/redmine/dumps RAILS_ENV="production"
END_DESC

  task :pdf => :environment do
    project = ENV['project'] ? Project.find(ENV['project']) : Project.first
    directory = ENV['directory'] || "#{Rails.root}/tmp"
    path = File.join(directory, "#{project.identifier}.pdf")
    export_wiki(project, 'wiki/export.pdf', path)
  end

  desc <<-END_DESC
Dump the wiki of a project to a HTML file.

Available options:
  * project   => id or identifier of project (defaults to first projects)
  * directory => output directory (defaults to rails temporary directory)

Example:
  rake wikidump:html project=1 directory=/home/redmine/dumps RAILS_ENV="production"
END_DESC

  task :html => :environment do
    project = ENV['project'] ? Project.find(ENV['project']) : Project.first
    directory = ENV['directory'] || "#{Rails.root}/tmp"
    path = File.join(directory, "#{project.identifier}.html")
    export_wiki(project, 'wiki/export_multiple.html', path)
  end
end
