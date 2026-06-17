require 'xcodeproj'

project_path = 'VideoTranscripterTool.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Group path
group = project.main_group.find_subpath(File.join('VideoTranscripterTool', 'Views'), true)
file_ref = group.new_file('SettingsView.swift')

# Add to compile sources
target.source_build_phase.add_file_reference(file_ref)

project.save
