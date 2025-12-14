<?php
if (!defined('ABSPATH')) exit;

function vire_console_install_roles() {
  // Create a Viewer role for read-only access to Vire Console
  add_role('vire_viewer', 'Vire Viewer', [
    'read' => true,
    'vire_view' => true,
  ]);

  // Ensure admins can view
  $admin = get_role('administrator');
  if ($admin && !$admin->has_cap('vire_view')) {
    $admin->add_cap('vire_view');
  }
}
