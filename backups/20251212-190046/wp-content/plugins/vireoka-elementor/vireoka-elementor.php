<?php
/**
 * Plugin Name: Vireoka Elementor Extensions
 * Description: Elite Neural Luxe widgets + presets for Vireoka
 * Version: 1.1.0
 */
if (!defined('ABSPATH')) exit;

add_action('elementor/widgets/register', function($widgets){
  require_once __DIR__.'/widgets/hero.php';
  require_once __DIR__.'/widgets/products.php';
  require_once __DIR__.'/widgets/cta.php';
  require_once __DIR__.'/widgets/investor.php';

  $widgets->register(new \Vireoka_Hero_Widget());
  $widgets->register(new \Vireoka_Products_Widget());
  $widgets->register(new \Vireoka_CTA_Widget());
  $widgets->register(new \Vireoka_Investor_Widget());
});

/* Motion Presets */
add_action('elementor/controls/register', function() {
  add_filter('elementor/controls/animations/additional_animations', function($anims){
    return array_merge($anims, [
      'vireoka_neural_fade' => 'Neural Fade',
      'vireoka_lattice_rise' => 'Lattice Rise'
    ]);
  });
});

/* ============================
   AI Variant Hooks (Future)
   ============================ */
add_filter('vireoka_ai_variant_copy', function($copy, $variant){
  // Placeholder for AI-generated variants
  return $copy;
}, 10, 2);
