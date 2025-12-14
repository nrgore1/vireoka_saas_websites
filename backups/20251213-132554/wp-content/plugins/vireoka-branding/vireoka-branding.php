<?php
/**
 * Plugin Name: Vireoka Branding
 * Description: Global branding styles and color tokens for Vireoka product pages.
 * Version: 1.0.1
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Enqueue global branding CSS on front-end.
 */
add_action( 'wp_enqueue_scripts', function() {
    wp_enqueue_style(
        'vireoka-branding',
        plugins_url( 'assets/css/vireoka-branding.css', __FILE__ ),
        array(),
        '1.0.1'
    );
}, 5 ); // load early so others can build on tokens

/**
 * Also load inside Elementor editor so layouts look the same there.
 */
add_action( 'elementor/editor/after_enqueue_styles', function() {
    wp_enqueue_style(
        'vireoka-branding',
        plugins_url( 'assets/css/vireoka-branding.css', __FILE__ ),
        array(),
        '1.0.1'
    );
});
