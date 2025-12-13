<?php
function vireoka_teaser_setup() {
    add_theme_support( 'title-tag' );
    register_nav_menus( array(
        'primary' => __( 'Primary Menu', 'vireoka-teaser' ),
        'footer'  => __( 'Footer Menu', 'vireoka-teaser' ),
    ) );
}
add_action( 'after_setup_theme', 'vireoka_teaser_setup' );

function vireoka_teaser_assets() {
    wp_enqueue_style(
        'vireoka-teaser-style',
        get_stylesheet_uri(),
        array(),
        wp_get_theme()->get( 'Version' )
    );
}
add_action( 'wp_enqueue_scripts', 'vireoka_teaser_assets' );
