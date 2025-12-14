<?php
if (!defined('ABSPATH')) exit;

add_action('rest_api_init', function () {
  register_rest_route('vire/v1', '/whoami', [
    'methods' => 'GET',
    'permission_callback' => function () {
      return is_user_logged_in();
    },
    'callback' => function () {
      $u = wp_get_current_user();
      $is_admin = current_user_can('manage_options');
      $is_viewer = current_user_can('vire_view');

      return [
        'ok' => true,
        'user' => [
          'id' => $u->ID,
          'email' => $u->user_email,
          'display_name' => $u->display_name,
          'roles' => $u->roles,
        ],
        'caps' => [
          'admin' => $is_admin,
          'viewer' => $is_viewer,
        ],
      ];
    }
  ]);

  // Read-only endpoints (Admin OR Viewer)
  $read_perm = function () {
    return current_user_can('manage_options') || current_user_can('vire_view');
  };

  // Admin-only endpoints
  $admin_perm = function () {
    return current_user_can('manage_options');
  };

  register_rest_route('vire/v1', '/status', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      // Reads your sync status JSON if present
      $paths = [
        ABSPATH . '_sync_status/status.json',
        WP_CONTENT_DIR . '/_sync_status/status.json',
      ];
      $data = null;
      foreach ($paths as $p) {
        if (file_exists($p)) { $data = json_decode(file_get_contents($p), true); break; }
      }
      return $data ?: ['ok'=>true,'note'=>'status.json not found in known locations'];
    }
  ]);

  register_rest_route('vire/v1', '/plan', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      $paths = [
        ABSPATH . '_sync_status/plan.json',
        WP_CONTENT_DIR . '/_sync_status/plan.json',
      ];
      $data = null;
      foreach ($paths as $p) {
        if (file_exists($p)) { $data = json_decode(file_get_contents($p), true); break; }
      }
      return $data ?: ['ok'=>true,'note'=>'plan.json not found'];
    }
  ]);

  register_rest_route('vire/v1', '/explain', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      $paths = [
        ABSPATH . '_sync_status/ai_conflicts_report.json',
        WP_CONTENT_DIR . '/_sync_status/ai_conflicts_report.json',
      ];
      $data = null;
      foreach ($paths as $p) {
        if (file_exists($p)) { $data = json_decode(file_get_contents($p), true); break; }
      }
      return $data ?: ['ok'=>true,'note'=>'ai_conflicts_report.json not found'];
    }
  ]);

  register_rest_route('vire/v1', '/plugin-risk', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      // Lightweight heuristic: list plugins + risk based on update age + common patterns
      if (!function_exists('get_plugins')) {
        require_once ABSPATH . 'wp-admin/includes/plugin.php';
      }
      $plugins = get_plugins();
      $items = [];

      foreach ($plugins as $file => $meta) {
        $name = $meta['Name'] ?? $file;
        $ver  = $meta['Version'] ?? '';
        $author = $meta['AuthorName'] ?? ($meta['Author'] ?? '');
        $risk = 10;

        // heuristic bumpers
        $s = strtolower($name . ' ' . $file);
        if (strpos($s, 'cache') !== false) $risk += 8;
        if (strpos($s, 'security') !== false) $risk += 6;
        if (strpos($s, 'backup') !== false) $risk += 5;
        if (strpos($s, 'elementor') !== false) $risk += 6;
        if (strpos($s, 'woocommerce') !== false) $risk += 8;
        if (strpos($s, 'ai') !== false) $risk += 5;

        $active = is_plugin_active($file);
        $risk += $active ? 5 : -3;

        $risk = max(1, min(100, $risk));

        $items[] = [
          'plugin' => $name,
          'file' => $file,
          'version' => $ver,
          'active' => $active,
          'author' => wp_strip_all_tags($author),
          'risk' => $risk,
          'notes' => $active ? 'Active plugin' : 'Inactive (lower operational risk)',
        ];
      }

      usort($items, function($a,$b){ return $b['risk'] <=> $a['risk']; });

      return ['ok'=>true,'count'=>count($items),'items'=>$items];
    }
  ]);

  register_rest_route('vire/v1', '/editorial', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      $opt = get_option('vire_editorial_calendar', []);
      if (!is_array($opt)) $opt = [];
      return ['ok'=>true,'items'=>$opt];
    }
  ]);

  register_rest_route('vire/v1', '/editorial', [
    'methods' => 'POST',
    'permission_callback' => $admin_perm,
    'callback' => function ($req) {
      $b = $req->get_json_params();
      $items = get_option('vire_editorial_calendar', []);
      if (!is_array($items)) $items = [];

      $row = [
        'id' => uniqid('ed_', true),
        'title' => sanitize_text_field($b['title'] ?? ''),
        'topic' => sanitize_text_field($b['topic'] ?? ''),
        'target_date' => sanitize_text_field($b['target_date'] ?? ''),
        'mode' => sanitize_text_field($b['mode'] ?? 'Creator'),
        'notes' => sanitize_text_field($b['notes'] ?? ''),
        'created_at' => gmdate('c'),
      ];
      array_unshift($items, $row);
      update_option('vire_editorial_calendar', $items, false);

      vire_audit_log('editorial_add', $row);

      return ['ok'=>true,'item'=>$row];
    }
  ]);

  register_rest_route('vire/v1', '/approval', [
    'methods' => 'POST',
    'permission_callback' => $admin_perm,
    'callback' => function ($req) {
      $b = $req->get_json_params();
      $action = sanitize_text_field($b['action'] ?? '');
      if (!in_array($action, ['apply','reject'], true)) {
        return new WP_REST_Response(['ok'=>false,'error'=>'invalid action'], 400);
      }

      $payload = [
        'ok' => true,
        'action' => $action,
        'at' => gmdate('c'),
        'user_id' => get_current_user_id(),
      ];

      update_option('vire_last_approval', $payload, false);
      vire_audit_log('approval_' . $action, $payload);

      return $payload;
    }
  ]);

  register_rest_route('vire/v1', '/audit', [
    'methods' => 'GET',
    'permission_callback' => $admin_perm,
    'callback' => function ($req) {
      $limit = intval($req->get_param('limit') ?: 50);
      return ['ok'=>true,'items'=>vire_audit_list($limit)];
    }
  ]);

  register_rest_route('vire/v1', '/monitor', [
    'methods' => 'GET',
    'permission_callback' => $read_perm,
    'callback' => function () {
      return [
        'ok' => true,
        'wp' => [
          'home' => home_url('/'),
          'admin' => admin_url('/'),
          'version' => get_bloginfo('version'),
        ],
        'php' => [
          'version' => PHP_VERSION,
        ],
        'time' => gmdate('c'),
      ];
    }
  ]);
});
