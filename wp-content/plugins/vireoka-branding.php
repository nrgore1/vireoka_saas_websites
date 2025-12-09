<?php
/**
 * Plugin Name: Vireoka Branding System
 * Description: Applies the Vireoka Elite Neural Luxe brand colors to Astra + Elementor (global, header, footer, links, buttons).
 * Version: 1.0.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * CORE BRAND COLORS
 */
function vireoka_brand_colors() {
    return array(
        'bg'        => '#020617', // Dark background
        'bg_soft'   => '#0B1220', // Softer section background
        'heading'   => '#F9FAFB', // Headings
        'body'      => '#9CA3AF', // Body text
        'link'      => '#3AF4D3', // Link / primary accent
        'link_hover'=> '#E4B448', // Link hover / active
        'accent'    => '#E4B448', // Gold accent
        'accent2'   => '#5A2FE3', // Violet
        'accent3'   => '#3AF4D3', // Neon teal
    );
}

/**
 * Apply Astra theme_mods (global-ish settings).
 */
add_action( 'after_setup_theme', function () {
    $c = vireoka_brand_colors();

    // Global palette (Astra uses a simple array of hex values)
    set_theme_mod( 'astra-color-palette', array(
        $c['bg'],
        $c['heading'],
        $c['body'],
        $c['link'],
        $c['accent'],
        $c['accent2'],
        $c['accent3'],
    ) );

    // Background and text colors
    set_theme_mod( 'background_color', ltrim( $c['bg'], '#' ) ); // WP expects no '#'
    set_theme_mod( 'body_color', $c['body'] );
    set_theme_mod( 'heading_color', $c['heading'] );

    // Link colors
    set_theme_mod( 'link_color', $c['link'] );
    set_theme_mod( 'link_hover_color', $c['link_hover'] );
} );

/**
 * Try to apply header & footer colors via theme_mod (Astra’s internal keys vary by version,
 * so we ALSO add a CSS layer below to guarantee the look).
 */
add_action( 'init', function () {
    $c = vireoka_brand_colors();

    // Header approximate theme mods (may or may not be used by your Astra version)
    set_theme_mod( 'header-bg-color', $c['bg'] );
    set_theme_mod( 'header-menu-text-color', $c['heading'] );
    set_theme_mod( 'header-menu-text-hover-color', $c['link'] );
    set_theme_mod( 'header-menu-text-active-color', $c['accent'] );

    // Footer approximate theme mods
    set_theme_mod( 'footer-bg-color', $c['bg'] );
    set_theme_mod( 'footer-color', $c['body'] );
    set_theme_mod( 'footer-link-color', $c['heading'] );
    set_theme_mod( 'footer-link-hover-color', $c['link'] );
} );

/**
 * Elementor global colors + typography.
 */
add_action( 'elementor/init', function () {
    if ( ! class_exists( '\Elementor\Plugin' ) ) {
        return;
    }

    $c   = vireoka_brand_colors();
    $kit = \Elementor\Plugin::$instance->kits_manager->get_active_kit();

    if ( ! $kit ) {
        return;
    }

    // Colors
    $kit->set_settings( 'global_colors', array(
        'primary'   => $c['link'],
        'secondary' => $c['accent2'],
        'text'      => $c['body'],
        'accent'    => $c['accent'],
    ) );

    // Typography
    $kit->set_settings( 'global_typography', array(
        'primary' => array(
            'font_family' => 'Inter Tight',
        ),
        'text'    => array(
            'font_family' => 'Inter',
        ),
    ) );
} );

/**
 * FINAL CSS LAYER — guarantees colors even if Astra’s internal option names change.
 */
add_action( 'wp_head', function () {
    $c = vireoka_brand_colors();
    ?>
    <style id="vireoka-branding-css">
        /* Global body */
        body {
            background-color: <?php echo esc_html( $c['bg'] ); ?>;
            color: <?php echo esc_html( $c['body'] ); ?>;
        }

        h1, h2, h3, h4, h5, h6 {
            color: <?php echo esc_html( $c['heading'] ); ?>;
            font-family: "Inter Tight", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        body, p, li, span {
            font-family: "Inter", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        /* Links */
        a {
            color: <?php echo esc_html( $c['link'] ); ?>;
        }

        a:hover,
        a:focus {
            color: <?php echo esc_html( $c['link_hover'] ); ?>;
        }

        /* Header (Astra primary header bar + main menu) */
        .main-header-bar,
        .ast-primary-header-bar,
        .ast-above-header,
        .ast-below-header {
            background-color: <?php echo esc_html( $c['bg'] ); ?> !important;
        }

        .main-header-menu > li > a,
        .ast-header-break-point .main-header-menu .menu-link,
        .ast-desktop .ast-primary-header-bar .main-header-menu > li > .menu-link {
            color: <?php echo esc_html( $c['heading'] ); ?> !important;
        }

        .main-header-menu > li > a:hover,
        .main-header-menu > li.current-menu-item > a,
        .main-header-menu > li.current_page_item > a {
            color: <?php echo esc_html( $c['link'] ); ?> !important;
        }

        /* Header CTA button (Astra header button / customizer button) */
        .ast-header-button-1 .ast-custom-button,
        .ast-header-button-1 .ast-custom-button:hover {
            background-color: <?php echo esc_html( $c['accent'] ); ?> !important;
            color: <?php echo esc_html( $c['bg'] ); ?> !important;
            border-radius: 999px !important;
            padding: 8px 18px !important;
            border: none !important;
        }

        /* Footer */
        .site-footer,
        .ast-footer-overlay,
        .ast-footer-bar,
        .ast-primary-footer-wrap {
            background-color: <?php echo esc_html( $c['bg'] ); ?> !important;
            color: <?php echo esc_html( $c['body'] ); ?> !important;
        }

        .site-footer a,
        .ast-footer-overlay a {
            color: <?php echo esc_html( $c['heading'] ); ?> !important;
        }

        .site-footer a:hover,
        .ast-footer-overlay a:hover {
            color: <?php echo esc_html( $c['link'] ); ?> !important;
        }

        /* Buttons in content */
        .elementor-button,
        button,
        .button,
        input[type="submit"],
        .ast-button {
            background-color: <?php echo esc_html( $c['accent'] ); ?>;
            color: <?php echo esc_html( $c['bg'] ); ?>;
            border-radius: 999px;
            border: none;
        }

        .elementor-button:hover,
        button:hover,
        .button:hover,
        input[type="submit"]:hover,
        .ast-button:hover {
            background-color: <?php echo esc_html( $c['link_hover'] ); ?>;
        }

        /* Optional: softer alt background for Elementor sections if you give them class 'vireoka-section-alt' */
        .vireoka-section-alt {
            background: <?php echo esc_html( $c['bg_soft'] ); ?>;
        }

        /* If you add CSS class 'vireoka-hero' to your top hero section in Elementor, this gradient will apply */
        .vireoka-hero {
            background: radial-gradient(circle at top left, <?php echo esc_html( $c['accent2'] ); ?> 0%, <?php echo esc_html( $c['bg']; ); ?> 55%, <?php echo esc_html( $c['bg']; ); ?> 100%);
        }
    </style>
    <?php
} );
