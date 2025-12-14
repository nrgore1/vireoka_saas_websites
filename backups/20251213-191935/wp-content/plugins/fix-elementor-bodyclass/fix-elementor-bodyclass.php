<?php
/**
 * Plugin Name: Fix Elementor Body Class Fatal Error (Universal Interceptor)
 * Description: Force body_class() to ALWAYS return an array so Elementor cannot crash, even if plugins return NULL or strings.
 * Version: 2.0
 */

if (!defined('ABSPATH')) exit;

/*
|--------------------------------------------------------------------------
| Universal Body Class Sanitizer
|--------------------------------------------------------------------------
| Many plugins incorrectly return:
|   - NULL
|   - string
|   - boolean
|   - object
| which breaks Elementor on PHP 8.2.
|
| We normalize everything.
|--------------------------------------------------------------------------
*/

add_filter('body_class', function($classes) {

    // Log what comes in (debugging)
    if (!is_array($classes)) {
        error_log("[VIREOKA PATCH] Invalid body_class detected: " . print_r($classes, true));
    }

    // Convert ANY bad type into an empty array
    if (!is_array($classes)) {
        $classes = [];
    }

    // Sanitize array values
    $clean = [];
    foreach ($classes as $c) {
        if (is_string($c) && trim($c) !== '') {
            $clean[] = sanitize_html_class($c);
        }
    }

    return $clean;
}, 1);  // Priority 1 ensures we intercept before Elementor merges classes

