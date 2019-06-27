module ProjectsTreeView
  module ProjectsHelperPatch
    extend ActiveSupport::Concern

    module ClassMethods
    end

    def render_project_progress(project)
      s = ''
      cond = project.project_condition(Setting.display_subprojects_issues?)

      open_issues = Issue.visible.open.where(cond).count
      total_issues = Issue.visible.where(cond).count

     if total_issues > 0
		if open_issues == total_issues
			issues_closed_percent = 0
		else
			issues_closed_percent = (1 - open_issues.to_f/total_issues) * 100
		end
        s << "<table width=100%><tr><td width=165px>" +
                         link_to( l(:label_x_open_issues_abbr, :count => open_issues), :controller => 'issues', :action => 'index', :project_id => project, :set_filter => 1) +
          "<small> / " + link_to( l(:label_x_closed_issues_abbr, :count => total_issues-open_issues), :controller => 'issues', :action => 'index', :project_id => project, :status_id => 'c', :set_filter => 1) +
          "<small> | &Sigma; " + link_to( "#{total_issues}", :controller => 'issues', :action => 'index', :project_id => project, :status_id => '*', :set_filter => 1) +		     
	s << "</td><td>" +
          progress_bar(issues_closed_percent, :width => '100px', :legend => '%0.0f%%' % issues_closed_percent) + "</td></tr></table>"
      end
#      project_versions = versions_open(project)

#      unless project_versions.empty?
#        s << "<div>"
#        project_versions.reverse_each do |version|
#          unless version.completed?
#            s << "<div style=\"clear:both;display: block; margin-bottom: -2%;\">" + link_to_version(version) + ": " +
#            link_to( l(:label_x_open_issues_abbr, :count => version.open_issues_count), :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'o', :fixed_version_id => version, :set_filter => 1) +
#            "<small> / " + link_to( l(:label_x_closed_issues_abbr, :count => version.closed_issues_count), :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'c', :fixed_version_id => version, :set_filter => 1) + "</small>. "
#            s << due_date_distance_in_words(version.effective_date) if version.effective_date
#            s << "</div><div style=\"display: inline-flex; align-items: center;\">" +
#            progress_bar([version.closed_percent, version.completed_percent], :width => '30em', :legend => ('%0.0f%%' % version.completed_percent)) + "</div>"
#          end
#        end
#        s << "</div>"
#      end
      s.html_safe
    end

    def favorite_project_modules_links(project)
      links = []
      menu_items_for(:project_menu, project) do |node|
	  if node.name != :new_object && node.name != :overview
          details = extract_node_details(node, project)
          links << link_to(details[0], details[1])
        end
      end
      links.join(", ").html_safe
    end

    def versions_open(project)
      #trackers = project.trackers.order(:position)
      #retrieve_selected_tracker_ids(trackers, trackers.select {|t| t.is_in_roadmap?})
      with_subprojects =  Setting.display_subprojects_issues?
      project_ids = with_subprojects ? project.self_and_descendants.collect(&:id) : [project.id]

      versions = project.shared_versions || []
      versions += project.rolled_up_versions.visible if with_subprojects
      versions = versions.uniq.sort
      completed_versions = versions.select {|version| version.closed? || version.completed? }
      versions -= completed_versions

      issues_by_version = {}
      versions.reject! {|version| !project_ids.include?(version.project_id) && issues_by_version[version].blank?}
      versions
    end
  end
end
