<?php
/**
 * Vireoka Core — Standalone Theme
 */

// Enqueue theme stylesheet
add_action('wp_enqueue_scripts', function () {

    wp_enqueue_style(
        'vireoka-core-style',
        get_stylesheet_uri(),
        [],
        filemtime(get_stylesheet_directory() . '/style.css')
    );

}, 999);
