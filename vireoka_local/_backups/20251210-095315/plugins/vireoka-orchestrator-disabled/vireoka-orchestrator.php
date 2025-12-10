<?php
/**
 * Plugin Name: Vireoka Orchestrator
 * Description: Safely rebuilds Vireoka-branded Elementor layouts (hero, products strip, CTA) and repairs broken pages.
 * Version: 0.4.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Get homepage ID (use WP front-page setting; fall back to 93).
 */
function vireoka_orch_get_home_id() {
    $front = (int) get_option( 'page_on_front' );
    if ( $front > 0 ) {
        return $front;
    }
    // Fallback to the ID we know from logs.
    return 93;
}

/**
 * Very conservative HTML cleanup for classic content.
 */
function vireoka_orch_cleanup_html( $html ) {
    if ( ! $html ) {
        return $html;
    }

    // Elementor buttons
    $html = str_replace(
        'class="elementor-button ',
        'class="elementor-button vk-btn vk-btn-primary ',
        $html
    );
    $html = str_replace(
        'class="elementor-button"',
        'class="elementor-button vk-btn vk-btn-primary"',
        $html
    );

    // Elementor sections
    $html = preg_replace(
        '/class="elementor-section([^"]*)"/',
        'class="elementor-section$1 vk-section-dark"',
        $html
    );

    return $html;
}

/**
 * Default copy used for hero/body/CTA.
 */
function vireoka_orch_default_copy( $title ) {
    return array(
        'subtitle'        => 'Six breakthrough products. One shared intelligence.',
        'body'            => $title . ' is part of Vireoka’s AI Agent ecosystem, combining multi-agent reasoning and production-grade automation.',
        'cta_title'       => 'Partner with Vireoka',
        'cta_text'        => 'Founders, CTOs, and educators: bring multi-agent AI into your products and workflows.',
        'cta_button_text' => 'Contact Us',
    );
}

/**
 * SECTION BUILDERS
 */
function vireoka_orch_section_hero( $copy ) {
    $subtitle = isset( $copy['subtitle'] ) ? $copy['subtitle'] : 'Six breakthrough products. One shared intelligence.';

    $shortcode = sprintf(
        '[vireoka_hero title="Vireoka — The AI Agent Company" subtitle="%s" button="Join Waitlist" url="/contact"]',
        esc_attr( $subtitle )
    );

    return array(
        'id'       => 'vk-section-hero',
        'elType'   => 'section',
        'settings' => array(
            'content_width'         => 'boxed',
            'background_background' => 'gradient',
            'background_color'      => '#020617',
            'background_color_b'    => '#111827',
            '_css_classes'          => 'vk-section-dark vireoka-hero',
            'padding'               => array(
                'unit'     => 'px',
                'top'      => '120',
                'bottom'   => '120',
                'isLinked' => false,
            ),
        ),
        'elements' => array(
            array(
                'id'       => 'vk-col-hero',
                'elType'   => 'column',
                'settings' => array(
                    '_column_size' => 100,
                ),
                'elements' => array(
                    array(
                        'id'         => 'vk-hero-widget',
                        'elType'     => 'widget',
                        'widgetType' => 'shortcode',
                        'settings'   => array(
                            'shortcode' => $shortcode,
                        ),
                        'elements'   => array(),
                    ),
                ),
            ),
        ),
    );
}

function vireoka_orch_section_body( $copy ) {
    $body = isset( $copy['body'] ) ? $copy['body'] : 'Vireoka builds AI agent systems that are safe, aligned, and production-ready.';
    $html = '<p>' . esc_html( $body ) . '</p>';

    return array(
        'id'       => 'vk-section-body',
        'elType'   => 'section',
        'settings' => array(
            'content_width'         => 'boxed',
            'background_background' => 'classic',
            'background_color'      => '#020617',
            '_css_classes'          => 'vk-section-dark',
            'padding'               => array(
                'unit'     => 'px',
                'top'      => '60',
                'bottom'   => '60',
                'isLinked' => false,
            ),
        ),
        'elements' => array(
            array(
                'id'       => 'vk-col-body',
                'elType'   => 'column',
                'settings' => array(
                    '_column_size' => 100,
                ),
                'elements' => array(
                    array(
                        'id'         => 'vk-body-widget',
                        'elType'     => 'widget',
                        'widgetType' => 'text-editor',
                        'settings'   => array(
                            'editor' => $html,
                        ),
                        'elements'   => array(),
                    ),
                ),
            ),
        ),
    );
}

function vireoka_orch_section_products() {
    $shortcode =
        '[vireoka_feature_grid]' .
        '[vireoka_feature title="AtmaSphere LLM"]Core multi-agent reasoning engine.[/vireoka_feature]' .
        '[vireoka_feature title="Communication Suite"]AI coaching for debates, pitches, and leadership.[/vireoka_feature]' .
        '[vireoka_feature title="Dating Platform Builder"]Niche, curated dating communities.[/vireoka_feature]' .
        '[vireoka_feature title="Memoir Studio"]AI-designed memoirs and coffee-table books.[/vireoka_feature]' .
        '[vireoka_feature title="FinOps AI"]Autonomous cloud & AI cost optimization.[/vireoka_feature]' .
        '[vireoka_feature title="Quantum-Secure Stablecoin"]Stablecoin designed for a post-quantum world.[/vireoka_feature]' .
        '[/vireoka_feature_grid]';

    return array(
        'id'       => 'vk-section-products',
        'elType'   => 'section',
        'settings' => array(
            'content_width'         => 'boxed',
            'background_background' => 'classic',
            'background_color'      => '#020617',
            '_css_classes'          => 'vk-section-dark vireoka-products-strip',
            'padding'               => array(
                'unit'     => 'px',
                'top'      => '60',
                'bottom'   => '60',
                'isLinked' => false,
            ),
        ),
        'elements' => array(
            array(
                'id'       => 'vk-col-products',
                'elType'   => 'column',
                'settings' => array(
                    '_column_size' => 100,
                ),
                'elements' => array(
                    array(
                        'id'         => 'vk-products-widget',
                        'elType'     => 'widget',
                        'widgetType' => 'shortcode',
                        'settings'   => array(
                            'shortcode' => $shortcode,
                        ),
                        'elements'   => array(),
                    ),
                ),
            ),
        ),
    );
}

function vireoka_orch_section_cta( $copy ) {
    $title       = isset( $copy['cta_title'] ) ? $copy['cta_title'] : 'Partner with Vireoka';
    $text        = isset( $copy['cta_text'] ) ? $copy['cta_text'] : 'Founders, CTOs, and educators: bring multi-agent AI into your products and workflows.';
    $button_text = isset( $copy['cta_button_text'] ) ? $copy['cta_button_text'] : 'Contact Us';

    $shortcode = sprintf(
        '[vireoka_cta title="%s" text="%s" button_text="%s" button_url="/contact"]',
        esc_attr( $title ),
        esc_attr( $text ),
        esc_attr( $button_text )
    );

    return array(
        'id'       => 'vk-section-cta',
        'elType'   => 'section',
        'settings' => array(
            'content_width'         => 'boxed',
            'background_background' => 'gradient',
            'background_color'      => '#111827',
            'background_color_b'    => '#020617',
            '_css_classes'          => 'vk-section-dark',
            'padding'               => array(
                'unit'     => 'px',
                'top'      => '80',
                'bottom'   => '80',
                'isLinked' => false,
            ),
        ),
        'elements' => array(
            array(
                'id'       => 'vk-col-cta',
                'elType'   => 'column',
                'settings' => array(
                    '_column_size' => 100,
                ),
                'elements' => array(
                    array(
                        'id'         => 'vk-cta-widget',
                        'elType'     => 'widget',
                        'widgetType' => 'shortcode',
                        'settings'   => array(
                            'shortcode' => $shortcode,
                        ),
                        'elements'   => array(),
                    ),
                ),
            ),
        ),
    );
}

/**
 * Build a full homepage layout from scratch.
 */
function vireoka_orch_build_home_layout( $title ) {
    $copy = vireoka_orch_default_copy( $title );

    $layout = array(
        vireoka_orch_section_hero( $copy ),
        vireoka_orch_section_products(),
        vireoka_orch_section_body( $copy ),
        vireoka_orch_section_cta( $copy ),
    );

    return $layout;
}

/**
 * Safely rebuild homepage Elementor JSON.
 */
function vireoka_orch_rebuild_homepage() {
    $home_id = vireoka_orch_get_home_id();
    if ( ! $home_id ) {
        return new WP_Error( 'no_home', 'Could not determine homepage ID.' );
    }

    $post = get_post( $home_id );
    if ( ! $post || 'page' !== $post->post_type ) {
        return new WP_Error( 'invalid_home', 'Homepage ID is not a valid page.' );
    }

    // Backup existing content & elementor data
    $old_content = $post->post_content;
    $old_data    = get_post_meta( $home_id, '_elementor_data', true );

    update_post_meta( $home_id, '_vireoka_backup_elementor_data', $old_data );
    update_post_meta( $home_id, '_vireoka_backup_post_content', $old_content );

    // Build new layout
    $layout = vireoka_orch_build_home_layout( get_the_title( $post ) );

    $encoded = function_exists( 'wp_json_encode' ) ? wp_json_encode( $layout ) : json_encode( $layout );

    // Apply Elementor meta
    update_post_meta( $home_id, '_elementor_data', $encoded );
    update_post_meta( $home_id, '_elementor_edit_mode', 'builder' );
    update_post_meta( $home_id, '_wp_page_template', 'elementor_canvas' );

    // Also provide minimal fallback HTML if Elementor is disabled
    $fallback_html  = '<div class="vireoka-fallback">';
    $fallback_html .= '<h1>Vireoka — The AI Agent Company</h1>';
    $fallback_html .= '<p>Six breakthrough products. One shared intelligence.</p>';
    $fallback_html .= '</div>';

    wp_update_post(
        array(
            'ID'           => $home_id,
            'post_content' => $fallback_html,
        )
    );

    return true;
}

/**
 * Repair all pages (simple version – mainly for future use).
 */
function vireoka_orch_repair_all_pages() {
    $args  = array(
        'post_type'      => 'page',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
    );
    $pages = get_posts( $args );

    foreach ( $pages as $p ) {
        // Just run conservative cleanup for now
        $cleaned = vireoka_orch_cleanup_html( $p->post_content );
        if ( $cleaned !== $p->post_content ) {
            wp_update_post(
                array(
                    'ID'           => $p->ID,
                    'post_content' => $cleaned,
                )
            );
        }
    }
}

/**
 * Admin page UI.
 */
function vireoka_orch_admin_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $message = '';

    if ( isset( $_POST['vireoka_orch_rebuild_home'] ) ) {
        check_admin_referer( 'vireoka_orch_rebuild_home_nonce' );
        $result = vireoka_orch_rebuild_homepage();
        if ( is_wp_error( $result ) ) {
            $message = '<div class="notice notice-error"><p>Home rebuild failed: ' . esc_html( $result->get_error_message() ) . '</p></div>';
        } else {
            $message = '<div class="notice notice-success"><p>Homepage has been rebuilt with a fresh Vireoka layout.</p></div>';
        }
    } elseif ( isset( $_POST['vireoka_orch_repair_all'] ) ) {
        check_admin_referer( 'vireoka_orch_repair_all_nonce' );
        vireoka_orch_repair_all_pages();
        $message = '<div class="notice notice-success"><p>All pages have been cleaned (buttons & sections styled).</p></div>';
    }

    echo '<div class="wrap">';
    echo '<h1>Vireoka Orchestrator v4</h1>';
    echo '<p>Use this tool to safely rebuild the homepage layout and clean up other pages.</p>';
    echo $message;

    echo '<h2>Homepage Actions</h2>';
    echo '<form method="post" style="margin-bottom:2rem;">';
    wp_nonce_field( 'vireoka_orch_rebuild_home_nonce' );
    echo '<p><input type="submit" class="button button-primary button-hero" name="vireoka_orch_rebuild_home" value="Rebuild Homepage Now"></p>';
    echo '</form>';

    echo '<h2>Repair All Pages</h2>';
    echo '<form method="post">';
    wp_nonce_field( 'vireoka_orch_repair_all_nonce' );
    echo '<p><input type="submit" class="button" name="vireoka_orch_repair_all" value="Clean Buttons & Sections on All Pages"></p>';
    echo '</form>';

    echo '</div>';
}

/**
 * Add menu under Tools.
 */
function vireoka_orch_admin_menu() {
    add_management_page(
        'Vireoka Orchestrator',
        'Vireoka Orchestrator',
        'manage_options',
        'vireoka-orchestrator',
        'vireoka_orch_admin_page'
    );
}
add_action( 'admin_menu', 'vireoka_orch_admin_menu' );