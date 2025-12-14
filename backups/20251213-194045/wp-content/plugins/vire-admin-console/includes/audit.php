<?php
if (!defined('ABSPATH')) exit;

function vire_console_install_audit_table() {
  global $wpdb;
  $table = $wpdb->prefix . 'vire_audit';
  $charset = $wpdb->get_charset_collate();

  $sql = "CREATE TABLE IF NOT EXISTS $table (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    created_at DATETIME NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    action VARCHAR(190) NOT NULL,
    details LONGTEXT NULL,
    ip VARCHAR(64) NULL,
    PRIMARY KEY (id),
    KEY created_at (created_at),
    KEY action (action)
  ) $charset;";

  require_once ABSPATH . 'wp-admin/includes/upgrade.php';
  dbDelta($sql);
}

function vire_audit_log($action, $details = []) {
  global $wpdb;
  $table = $wpdb->prefix . 'vire_audit';

  $user_id = get_current_user_id();
  $ip = isset($_SERVER['REMOTE_ADDR']) ? sanitize_text_field($_SERVER['REMOTE_ADDR']) : null;

  $wpdb->insert($table, [
    'created_at' => current_time('mysql', 1),
    'user_id' => $user_id ? $user_id : null,
    'action' => sanitize_text_field($action),
    'details' => wp_json_encode($details),
    'ip' => $ip,
  ]);
}

function vire_audit_list($limit = 50) {
  global $wpdb;
  $table = $wpdb->prefix . 'vire_audit';
  $limit = max(1, min(200, intval($limit)));

  $rows = $wpdb->get_results(
    $wpdb->prepare("SELECT * FROM $table ORDER BY id DESC LIMIT %d", $limit),
    ARRAY_A
  );

  return array_map(function($r){
    $r['details'] = json_decode($r['details'], true);
    return $r;
  }, $rows ?: []);
}
