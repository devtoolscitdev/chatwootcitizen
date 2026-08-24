json.id resource.id
json.title resource.title
json.content resource.content
json.show_on_sidebar resource.respond_to?(:show_on_sidebar) ? (resource.show_on_sidebar.nil? ? true : resource.show_on_sidebar) : true
json.icon resource.respond_to?(:icon) ? (resource.icon || 'i-lucide-layout-grid') : 'i-lucide-layout-grid'
json.position resource.respond_to?(:position) ? (resource.position || 0) : 0
json.sidebar_placement resource.respond_to?(:sidebar_placement) ? (resource.sidebar_placement || 'main') : 'main'
json.created_at resource.created_at
