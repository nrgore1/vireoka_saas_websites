<?php
/**
 * Plugin Name: Vire Admin Console
 * Description: Admin + Viewer console for Vire sync, approvals, content workflows, and monitoring.
 * Version: 6.3.0
 * Author: Vireoka
 */

if (!defined('ABSPATH')) exit;

define('VIRE_CONSOLE_VER', '6.3.0');
define('VIRE_CONSOLE_DIR', plugin_dir_path(__FILE__));
define('VIRE_CONSOLE_URL', plugin_dir_url(__FILE__));

require_once VIRE_CONSOLE_DIR . 'includes/rest.php';
require_once VIRE_CONSOLE_DIR . 'includes/audit.php';
require_once VIRE_CONSOLE_DIR . 'includes/roles.php';

register_activation_hook(__FILE__, function () {
  vire_console_install_roles();
  vire_console_install_audit_table();
});

add_action('admin_menu', function () {
  add_menu_page(
    'Vire Console',
    'Vire Console',
    'read', // we’ll gate inside the page using capabilities
    'vire-console',
    'vire_console_render_admin_page',
    'dashicons-shield-alt',
    58
  );
});

function vire_console_render_admin_page() {
  // Gate: allow Admin OR Viewer
  if (!current_user_can('manage_options') && !current_user_can('vire_view')) {
    wp_die('Admin access required.');
  }

  echo '<div class="wrap" style="padding:0;margin-left:-20px">';
  echo '<iframe src="' . esc_url(admin_url('admin.php?page=vire-console&vire_ui=1')) . '" style="width:100%;height:calc(100vh - 60px);border:0;"></iframe>';
  echo '</div>';
}

// Serve the static UI in the same origin via an iframe URL param
add_action('admin_init', function () {
  if (!is_admin()) return;
  if (!isset($_GET['page']) || $_GET['page'] !== 'vire-console') return;
  if (!isset($_GET['vire_ui'])) return;

  // Gate again
  if (!current_user_can('manage_options') && !current_user_can('vire_view')) {
    wp_die('Admin access required.');
  }

  $index = VIRE_CONSOLE_DIR . 'assets/index.html';
  if (!file_exists($index)) {
    wp_die('Vire UI not published yet. Run publish script to copy dist → plugin assets.');
  }

  // Output the exported Next app
  header('Content-Type: text/html; charset=utf-8');
  readfile($index);
  exit;
});
