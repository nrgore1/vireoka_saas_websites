<?php
/**
 * Plugin Name: Vireoka Runtime Layer (Body Classes + Tokens)
 */

function vireoka_get_product_slug_map() {
  // Map WP page slugs → canonical product ids
  // Adjust/add as your slugs evolve.
  return [
    'atmasphere-llm' => 'atmasphere',
    'communication-suite' => 'comms',
    'dating-platform-builder' => 'dating',
    'memoir-studio' => 'memoir',
    'finops-ai' => 'finops',
    'quantum-secure-finance' => 'quantum',
    'quantum-secure-stablecoin' => 'quantum',
    'agent-cloud-platform' => 'agentcloud',
  ];
}

add_filter('body_class', function ($classes) {
  if (is_page()) {
    global $post;
    $slug = $post->post_name ?? '';
    $classes[] = 'vireoka';
    $classes[] = 'vireoka-page';
    if ($slug) $classes[] = 'vireoka-page-' . sanitize_html_class($slug);

    $map = vireoka_get_product_slug_map();
    if ($slug && isset($map[$slug])) {
      $classes[] = 'vireoka-product';
      $classes[] = 'vireoka-product-' . sanitize_html_class($map[$slug]);
    }
  }
  return $classes;
});

add_filter('language_attributes', function($output) {
  // Add a data attribute on <html> for CSS/JS targeting
  if (!is_page()) return $output;
  global $post;
  $slug = $post->post_name ?? '';
  if (!$slug) return $output;

  $map = vireoka_get_product_slug_map();
  $product = isset($map[$slug]) ? $map[$slug] : '';
  if ($product) {
    $output .= ' data-vireoka-product="' . esc_attr($product) . '"';
  }
  return $output;
});
