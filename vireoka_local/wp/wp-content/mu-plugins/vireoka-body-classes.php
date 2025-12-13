<?php
/**
 * Plugin Name: Vireoka Body Class Injector
 */

add_filter('body_class', function ($classes) {
    if (is_page()) {
        global $post;
        $slug = $post->post_name ?? '';
        if ($slug) {
            $classes[] = 'vireoka-page';
            $classes[] = 'vireoka-page-' . sanitize_html_class($slug);
        }
    }
    return $classes;
});
