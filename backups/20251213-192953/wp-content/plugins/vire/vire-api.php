<?php
/**
 * Plugin Name: Vire Control API
 */

add_action('rest_api_init', function () {

  register_rest_route('vire', '/status', [
    'methods' => 'GET',
    'callback' => function () {
      $f = WP_CONTENT_DIR . '/_sync_status/status.json';
      return file_exists($f) ? json_decode(file_get_contents($f), true) : null;
    },
    'permission_callback' => fn() => current_user_can('manage_options')
  ]);

  register_rest_route('vire', '/plan', [
    'methods' => 'GET',
    'callback' => fn() =>
      json_decode(@file_get_contents(WP_CONTENT_DIR . '/_sync_status/plan.json'), true),
    'permission_callback' => fn() => current_user_can('manage_options')
  ]);

  register_rest_route('vire', '/explain', [
    'methods' => 'GET',
    'callback' => fn() =>
      json_decode(@file_get_contents(WP_CONTENT_DIR . '/_sync_status/ai_conflicts_report.json'), true),
    'permission_callback' => fn() => current_user_can('manage_options')
  ]);

  register_rest_route('vire', '/plugin-risk', [
    'methods' => 'GET',
    'callback' => fn() =>
      json_decode(@file_get_contents(WP_CONTENT_DIR . '/_sync_status/plugin_risk.json'), true),
    'permission_callback' => fn() => current_user_can('manage_options')
  ]);

  register_rest_route('vire', '/editorial', [
    'methods' => ['GET','POST'],
    'callback' => function ($req) {
      $f = WP_CONTENT_DIR . '/_sync_status/editorial.json';
      if ($req->get_method() === 'POST') {
        file_put_contents($f, json_encode($req->get_json_params(), JSON_PRETTY_PRINT));
      }
      return file_exists($f) ? json_decode(file_get_contents($f), true) : [];
    },
    'permission_callback' => fn() => current_user_can('edit_posts')
  ]);

  register_rest_route('vire', '/approval', [
    'methods' => 'POST',
    'callback' => function ($req) {
      $action = $req->get_json_params()['action'] ?? 'unknown';
      file_put_contents(
        WP_CONTENT_DIR . '/_sync_status/approval.json',
        json_encode([
          'action' => $action,
          'approved_by' => wp_get_current_user()->user_login,
          'time' => current_time('mysql')
        ], JSON_PRETTY_PRINT)
      );
      return ['ok' => true];
    },
    'permission_callback' => fn() => current_user_can('manage_options')
  ]);

});
