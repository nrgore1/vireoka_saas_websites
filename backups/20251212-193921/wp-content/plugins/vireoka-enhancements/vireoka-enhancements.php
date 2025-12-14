<?php
/**
 * Plugin Name: Vireoka Enhancements (Neural Luxe)
 * Description: Product body classes, neural canvas animation, Gutenberg styles, token parity helpers.
 * Version: 1.0.0
 * Author: Vireoka LLC
 */

if (!defined('ABSPATH')) exit;

class Vireoka_Enhancements {
  const VERSION = '1.0.0';

  public function __construct() {
    add_filter('body_class', [$this, 'body_classes']);
    add_action('wp_enqueue_scripts', [$this, 'enqueue_assets']);
    add_action('init', [$this, 'register_block_styles']);
  }

  /** Auto-assign body classes for product pages (by slug) */
  public function body_classes($classes) {
    if (!is_page()) return $classes;

    global $post;
    if (!$post) return $classes;

    $slug = $post->post_name;

    $map = [
      'atmasphere-llm'             => 'page-atmasphere',
      'communication-suite'        => 'page-communicationsuite',
      'dating-platform-builder'    => 'page-datingengine',
      'memoir-studio'              => 'page-memoirstudio',
      'finops-ai'                  => 'page-finopsai',
      'quantum-secure-stablecoin'  => 'page-quantumstablecoin',
      'agent-cloud-platform'       => 'page-agentcloud',
      'pricing'                    => 'page-pricing',
      'founder'                    => 'page-founder',
      'request-demo'               => 'page-requestdemo',
    ];

    if (isset($map[$slug])) $classes[] = $map[$slug];
    $classes[] = 'vireoka-neural-luxe';

    return $classes;
  }

  /** Enqueue lightweight neural canvas + (optional) Gutenberg style CSS */
  public function enqueue_assets() {
    // Canvas animation
    wp_enqueue_script(
      'vireoka-neural-canvas',
      plugins_url('assets/neural-canvas.js', __FILE__),
      [],
      self::VERSION,
      true
    );

    // Block styles (editor + front)
    wp_enqueue_style(
      'vireoka-block-styles',
      plugins_url('assets/blocks.css', __FILE__),
      [],
      self::VERSION
    );
  }

  /** Gutenberg block styles (no builder required) */
  public function register_block_styles() {
    if (!function_exists('register_block_style')) return;

    register_block_style('core/group', [
      'name'  => 'vireoka-card',
      'label' => 'Vireoka Card'
    ]);

    register_block_style('core/button', [
      'name'  => 'vireoka-neural',
      'label' => 'Neural Gradient'
    ]);

    register_block_style('core/columns', [
      'name'  => 'vireoka-feature-grid',
      'label' => 'Feature Grid (Neural Luxe)'
    ]);
  }
}

new Vireoka_Enhancements();
