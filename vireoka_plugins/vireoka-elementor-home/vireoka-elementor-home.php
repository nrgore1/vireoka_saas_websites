<?php
/**
 * Plugin Name: Vireoka Elementor Home
 * Description: Creates a Vireoka-branded Elementor homepage and sets it as the site front page.
 * Version: 1.1.0
 * Author: Vireoka
 */

if (!defined('ABSPATH')) exit;

function vireoka_el_home_activate() {

    // Create error log file if needed
    $log_file = WP_CONTENT_DIR . '/vireoka_home_error.log';
    file_put_contents($log_file, "--- Activation Started ---\n", FILE_APPEND);

    try {

        $page_title = 'Vireoka Home';
        $existing   = get_page_by_title($page_title, OBJECT, 'page');

        $page_id = 0;

        // Elementor JSON (VALIDATED)
        $elementor_data = json_encode([
            [
                "id" => "vk-section-hero",
                "elType" => "section",
                "settings" => [
                    "content_width" => "boxed",
                    "background_background" => "gradient",
                    "background_color" => "#020617",
                    "background_color_b" => "#111827",
                    "padding" => [
                        "unit" => "px",
                        "top" => "120",
                        "right" => "0",
                        "bottom" => "120",
                        "left" => "0",
                        "isLinked" => false
                    ]
                ],
                "elements" => [
                    [
                        "id" => "vk-column-hero",
                        "elType" => "column",
                        "settings" => ["_column_size" => 100],
                        "elements" => [
                            [
                                "id" => "vk-widget-hero-shortcode",
                                "elType" => "widget",
                                "widgetType" => "shortcode",
                                "settings" => [
                                    "shortcode" =>
                                        '[vireoka_hero title="Vireoka — The AI Agent Company" subtitle="Six breakthrough products. One shared intelligence." button="Join Waitlist" url="/contact"]'
                                ],
                                "elements" => []
                            ]
                        ]
                    ]
                ]
            ],

            [
                "id" => "vk-section-features",
                "elType" => "section",
                "settings" => [
                    "content_width" => "boxed",
                    "background_background" => "classic",
                    "background_color" => "#020617",
                    "padding" => [
                        "unit" => "px",
                        "top" => "80",
                        "right" => "0",
                        "bottom" => "80",
                        "left" => "0",
                        "isLinked" => false
                    ]
                ],
                "elements" => [
                    [
                        "id" => "vk-column-features",
                        "elType" => "column",
                        "settings" => ["_column_size" => 100],
                        "elements" => [
                            [
                                "id" => "vk-widget-features-shortcode",
                                "elType" => "widget",
                                "widgetType" => "shortcode",
                                "settings" => [
                                    "shortcode" =>
                                        '[vireoka_feature_grid]
                                            [vireoka_feature title="AtmaSphere LLM"]Core multi-agent reasoning engine.[/vireoka_feature]
                                            [vireoka_feature title="Communication Suite"]AI coaching for debates, pitches, and leadership.[/vireoka_feature]
                                            [vireoka_feature title="Dating Platform Builder"]Niche, curated dating communities.[/vireoka_feature]
                                            [vireoka_feature title="Memoir Studio"]AI-designed memoirs and coffee-table books.[/vireoka_feature]
                                            [vireoka_feature title="FinOps AI"]Autonomous cloud & AI cost optimization.[/vireoka_feature]
                                            [vireoka_feature title="Quantum-Secure Stablecoin"]Stablecoin architecture designed for a post-quantum world.[/vireoka_feature]
                                        [/vireoka_feature_grid]'
                                ],
                                "elements" => []
                            ]
                        ]
                    ]
                ]
            ],

            [
                "id" => "vk-section-cta",
                "elType" => "section",
                "settings" => [
                    "content_width" => "boxed",
                    "background_background" => "gradient",
                    "background_color" => "#111827",
                    "background_color_b" => "#020617",
                    "padding" => [
                        "unit" => "px",
                        "top" => "80",
                        "right" => "0",
                        "bottom" => "80",
                        "left" => "0",
                        "isLinked" => false
                    ]
                ],
                "elements" => [
                    [
                        "id" => "vk-column-cta",
                        "elType" => "column",
                        "settings" => ["_column_size" => 100],
                        "elements" => [
                            [
                                "id" => "vk-widget-cta-shortcode",
                                "elType" => "widget",
                                "widgetType" => "shortcode",
                                "settings" => [
                                    "shortcode" =>
                                        '[vireoka_cta title="Partner with Vireoka" text="Founders, CTOs, and educators: bring multi-agent AI into your products and workflows." button_text="Talk to Us" button_url="/contact"]'
                                ],
                                "elements" => []
                            ]
                        ]
                    ]
                ]
            ]
        ]);

        if (!$elementor_data) {
            file_put_contents($log_file, "JSON ENCODE FAILED\n", FILE_APPEND);
            return;
        }

        // Create or update the page
        if ($existing) {
            $page_id = $existing->ID;
        } else {
            $page_id = wp_insert_post([
                'post_title' => $page_title,
                'post_name' => 'vireoka-home',
                'post_status' => 'publish',
                'post_type' => 'page',
                'post_content' => '',
            ]);
        }

        if (is_wp_error($page_id)) {
            file_put_contents($log_file, "PAGE ERROR: " . $page_id->get_error_message() . "\n", FILE_APPEND);
            return;
        }

        update_post_meta($page_id, '_elementor_edit_mode', 'builder');
        update_post_meta($page_id, '_wp_page_template', 'elementor_canvas');
        update_post_meta($page_id, '_elementor_data', wp_slash($elementor_data));

        update_option('page_on_front', $page_id);
        update_option('show_on_front', 'page');

        file_put_contents($log_file, "Activation OK\n", FILE_APPEND);

    } catch (Exception $e) {
        file_put_contents($log_file, "EXCEPTION: " . $e->getMessage() . "\n", FILE_APPEND);
    }
}

register_activation_hook(__FILE__, 'vireoka_el_home_activate');
