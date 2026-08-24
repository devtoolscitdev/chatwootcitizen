class EnhanceDashboardAppsAndSettings < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:dashboard_apps, :show_on_sidebar)
      add_column :dashboard_apps, :show_on_sidebar, :boolean, default: true
    end

    unless column_exists?(:dashboard_apps, :icon)
      add_column :dashboard_apps, :icon, :string, default: 'i-lucide-layout-grid'
    end

    unless column_exists?(:dashboard_apps, :position)
      add_column :dashboard_apps, :position, :integer, default: 0
    end

    unless column_exists?(:dashboard_apps, :sidebar_placement)
      add_column :dashboard_apps, :sidebar_placement, :string, default: 'main'
    end
  end
end
