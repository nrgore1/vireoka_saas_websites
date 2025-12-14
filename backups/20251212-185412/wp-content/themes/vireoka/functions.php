<?php
add_action('wp_enqueue_scripts', function () {
  $theme = get_template_directory_uri();

  // Tokens + components
  wp_enqueue_style('vireoka-tokens', $theme . '/tokens/design-tokens.css', [], null);
  wp_enqueue_style('vireoka-components', $theme . '/assets/css/components.css', ['vireoka-tokens'], null);

  // Canvas
  wp_enqueue_script('vireoka-neural', $theme . '/assets/js/neural-canvas.v2.js', [], null, true);
});

add_action('after_setup_theme', function () {
  add_theme_support('editor-styles');
  add_editor_style('tokens/design-tokens.css');
  add_editor_style('assets/css/components.css');
  add_theme_support('align-wide');
});

require_once __DIR__ . '/gutenberg.php';
