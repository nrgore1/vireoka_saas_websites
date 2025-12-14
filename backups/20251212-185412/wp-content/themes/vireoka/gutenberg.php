<?php
add_action('init', function () {
  // Register block styles (core)
  if (function_exists('register_block_style')) {
    register_block_style('core/button', [
      'name'  => 'vireoka-primary',
      'label' => 'Vireoka Primary',
      'inline_style' => '.is-style-vireoka-primary .wp-element-button{background:var(--v-gradient-neural)!important;color:#fff!important;border-radius:var(--v-radius-md)!important;box-shadow:var(--v-shadow-gold)!important;font-weight:700;}'
    ]);

    register_block_style('core/group', [
      'name'  => 'vireoka-panel',
      'label' => 'Vireoka Panel',
      'inline_style' => '.is-style-vireoka-panel{background:rgba(27,34,53,.70)!important;border:1px solid var(--v-graphite)!important;border-radius:var(--v-radius-lg)!important;box-shadow:var(--v-shadow-panel)!important;padding:24px!important;}'
    ]);
  }

  // Register patterns (WP looks in /patterns automatically for block themes,
  // but for classic themes we register explicitly)
  if (function_exists('register_block_pattern')) {
    register_block_pattern('vireoka/hero', [
      'title' => 'Vireoka Hero',
      'content' => file_get_contents(__DIR__ . '/patterns/hero.php')
    ]);
    register_block_pattern('vireoka/feature-grid', [
      'title' => 'Vireoka Feature Grid',
      'content' => file_get_contents(__DIR__ . '/patterns/feature-grid.php')
    ]);
    register_block_pattern('vireoka/cta', [
      'title' => 'Vireoka CTA',
      'content' => file_get_contents(__DIR__ . '/patterns/cta.php')
    ]);
  }
});
