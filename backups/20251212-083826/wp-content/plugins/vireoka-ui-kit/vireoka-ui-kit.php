<?php
/**
 * Plugin Name: Vireoka UI Kit
 * Description: Shared UI components (cards, grids, buttons) for Vireoka layouts.
 * Version: 1.0.1
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Enqueue UI kit CSS on front-end.
 */
add_action( 'wp_enqueue_scripts', function() {
    wp_enqueue_style(
        'vireoka-ui-kit',
        plugins_url( 'assets/css/vireoka-ui-kit.css', __FILE__ ),
        array( 'vireoka-branding' ),
        '1.0.1'
    );
}, 8 );

/**
 * Also load inside Elementor editor.
 */
add_action( 'elementor/editor/after_enqueue_styles', function() {
    wp_enqueue_style(
        'vireoka-ui-kit',
        plugins_url( 'assets/css/vireoka-ui-kit.css', __FILE__ ),
        array( 'vireoka-branding' ),
        '1.0.1'
    );
});
