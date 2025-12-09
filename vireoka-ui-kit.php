<?php
/**
 * Plugin Name: Vireoka UI Kit
 * Description: Universal Vireoka-branded UI components (buttons, cards, CTAs, chat bubbles, feature grids) for AI agent websites.
 * Version: 1.0.0
 * Author: Vireoka
 */
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
define( 'VIREOKA_UI_KIT_VERSION', '1.0.0' );
define( 'VIREOKA_UI_KIT_URL', plugin_dir_url( __FILE__ ) );
define( 'VIREOKA_UI_KIT_PATH', plugin_dir_path( __FILE__ ) );
/**
 * Enqueue front-end styles.
 */
add_action( 'wp_enqueue_scripts', function () {
    wp_enqueue_style(
        'vireoka-ui-kit',
        VIREOKA_UI_KIT_URL . 'assets/css/vireoka-ui.css',
        array(),
        VIREOKA_UI_KIT_VERSION
    );
} );
/**
 * Helper: sanitize attributes with defaults.
 */
function vireoka_ui_parse_atts( $atts, $defaults ) {
    $parsed = shortcode_atts( $defaults, $atts );
    return array_map( 'wp_kses_post', $parsed );
}
/**
 * Shortcode: [vireoka_button text="Join Waitlist" url="/waitlist" variant="primary"]
 */
add_shortcode( 'vireoka_button', function ( $atts ) {
    $a = vireoka_ui_parse_atts( $atts, array(
        'text'    => 'Click here',
        'url'     => '#',
        'variant' => 'primary', // primary | ghost | subtle
    ) );
$variant_class = 'vk-btn-primary';
    if ( $a['variant'] === 'ghost' ) {
        $variant_class = 'vk-btn-ghost';
    } elseif ( $a['variant'] === 'subtle' ) {
        $variant_class = 'vk-btn-subtle';
    }
return sprintf(
        '<a href="%s" class="vk-btn %s">%s</a>',
        esc_url( $a['url'] ),
        esc_attr( $variant_class ),
        esc_html( $a['text'] )
    );
} );
/**
 * Shortcode: [vireoka_agent_card name="" role="" tagline="" avatar=""]
 */
add_shortcode( 'vireoka_agent_card', function ( $atts ) {
    $a = vireoka_ui_parse_atts( $atts, array(
        'name'    => 'Agent Name',
        'role'    => 'Specialization',
        'tagline' => 'Short description of what this agent does.',
        'avatar'  => '', // optional image URL
    ) );
$avatar_html = '';
    if ( ! empty( $a['avatar'] ) ) {
        $avatar_html = sprintf(
            '<div class="vk-agent-avatar"><img src="%s" alt="%s" loading="lazy" /></div>',
            esc_url( $a['avatar'] ),
            esc_attr( $a['name'] )
        );
    } else {
        // Initials fallback
        $initial = strtoupper( mb_substr( $a['name'], 0, 1 ) );
        $avatar_html = '<div class="vk-agent-avatar vk-agent-avatar-initial">' . esc_html( $initial ) . '</div>';
    }
ob_start();
    ?>
    <div class="vk-agent-card">
        <?php echo $avatar_html; ?>
        <div class="vk-agent-content">
            <div class="vk-agent-name"><?php echo esc_html( $a['name'] ); ?></div>
            <div class="vk-agent-role"><?php echo esc_html( $a['role'] ); ?></div>
            <div class="vk-agent-tagline"><?php echo esc_html( $a['tagline'] ); ?></div>
        </div>
    </div>
    <?php
    return ob_get_clean();
} );
/**
 * Shortcode: [vireoka_cta title="" text="" button_text="" button_url=""]
 */
add_shortcode( 'vireoka_cta', function ( $atts ) {
    $a = vireoka_ui_parse_atts( $atts, array(
        'title'       => 'Ready to build with Vireoka?',
        'text'        => 'Join the early access program for our AI agent ecosystem.',
        'button_text' => 'Join Waitlist',
        'button_url'  => '#',
    ) );
ob_start();
    ?>
    <section class="vk-cta">
        <div class="vk-cta-inner">
            <h2 class="vk-cta-title"><?php echo esc_html( $a['title'] ); ?></h2>
            <p class="vk-cta-text"><?php echo esc_html( $a['text'] ); ?></p>
            <a href="<?php echo esc_url( $a['button_url'] ); ?>" class="vk-btn vk-btn-primary">
                <?php echo esc_html( $a['button_text'] ); ?>
            </a>
        </div>
    </section>
    <?php
    return ob_get_clean();
} );
/**
 * Shortcode (paired): [vireoka_chat_bubble speaker="Agent" align="right"]Text[/vireoka_chat_bubble]
 */
add_shortcode( 'vireoka_chat_bubble', function ( $atts, $content = '' ) {
    $a = vireoka_ui_parse_atts( $atts, array(
        'speaker' => 'Agent',
        'align'   => 'left', // left | right
    ) );
$align_class = $a['align'] === 'right' ? 'vk-chat-right' : 'vk-chat-left';
ob_start();
    ?>
    <div class="vk-chat-bubble-row <?php echo esc_attr( $align_class ); ?>">
        <div class="vk-chat-bubble">
            <div class="vk-chat-speaker"><?php echo esc_html( $a['speaker'] ); ?></div>
            <div class="vk-chat-text"><?php echo wp_kses_post( $content ); ?></div>
        </div>
    </div>
    <?php
    return ob_get_clean();
} );
/**
 * Feature grid container + items:
 * [vireoka_feature_grid] [vireoka_feature title="" text=""] ... [/vireoka_feature_grid]
 */
add_shortcode( 'vireoka_feature_grid', function ( $atts, $content = '' ) {
    return '<div class="vk-feature-grid">' . do_shortcode( $content ) . '</div>';
} );
add_shortcode( 'vireoka_feature', function ( $atts, $content = '' ) {
    $a = vireoka_ui_parse_atts( $atts, array(
        'title' => 'Feature title',
        'icon'  => '', // future use
    ) );
ob_start();
    ?>
    <div class="vk-feature-card">
        <div class="vk-feature-title"><?php echo esc_html( $a['title'] ); ?></div>
        <div class="vk-feature-body"><?php echo wp_kses_post( $content ); ?></div>
    </div>
    <?php
    return ob_get_clean();
} );
