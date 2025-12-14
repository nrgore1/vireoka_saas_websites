<?php

add_action('after_setup_theme', function () {
    remove_action('astra_header', 'astra_header_markup');
    remove_action('astra_footer', 'astra_footer_markup');
}, 20);

add_action('wp_enqueue_scripts', function () {
    $base = get_stylesheet_directory_uri();

    wp_enqueue_style('vireoka-tokens', $base.'/assets/css/tokens.css', [], '1.0');
    wp_enqueue_style('vireoka-base', $base.'/assets/css/base.css', ['vireoka-tokens'], '1.0');
    wp_enqueue_style('vireoka-header', $base.'/assets/css/header.css', ['vireoka-base'], '1.0');
    wp_enqueue_style('vireoka-hero', $base.'/assets/css/hero.css', ['vireoka-header'], '1.0');
}, 99);
