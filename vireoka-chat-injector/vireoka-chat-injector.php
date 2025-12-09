<?php
/**
 * Plugin Name: Vireoka Chat Injector
 * Description: Automatically appends the Vireoka agent chat widget shortcode to selected templates.
 * Version: 1.0.0
 * Author: Vireoka
 */
if ( ! defined( 'ABSPATH' ) ) exit;
add_filter( 'the_content', function ( $content ) {
    if ( is_singular( array( 'page', 'post' ) ) ) {
        // Append chat to all pages/posts, or refine conditions:
        // e.g., if ( has_shortcode( $content, 'vireoka_hero' ) ) { ... }
        $content .= "\n\n[vireoka_agent_chat]";
    }
    return $content;
} );
