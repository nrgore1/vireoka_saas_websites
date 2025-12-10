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
/**
 * Shortcode: [vireoka_pricing]
 */
add_shortcode( 'vireoka_pricing', function () {
    ob_start(); ?>
    <div class="vk-pricing-grid">

        <!-- Tier 1 -->
        <div class="vk-price-card">
            <h3 class="vk-price-title">Starter</h3>
            <div class="vk-price-amount">$9<span>/mo</span></div>
            <ul class="vk-price-list">
                <li>1 AI Agent</li>
                <li>Basic Analytics</li>
                <li>Email Support</li>
            </ul>
            <a class="vk-btn vk-btn-primary" href="#">Choose Plan</a>
        </div>

        <!-- Tier 2 -->
        <div class="vk-price-card vk-featured">
            <h3 class="vk-price-title">Pro</h3>
            <div class="vk-price-amount">$29<span>/mo</span></div>
            <ul class="vk-price-list">
                <li>5 AI Agents</li>
                <li>Agent Conversations</li>
                <li>Priority Support</li>
            </ul>
            <a class="vk-btn vk-btn-primary" href="#">Choose Plan</a>
        </div>

        <!-- Tier 3 -->
        <div class="vk-price-card">
            <h3 class="vk-price-title">Enterprise</h3>
            <div class="vk-price-amount">Custom</div>
            <ul class="vk-price-list">
                <li>Unlimited Agents</li>
                <li>Custom LLM Integration</li>
                <li>White-glove Support</li>
            </ul>
            <a class="vk-btn vk-btn-primary" href="#">Contact Us</a>
        </div>

    </div>
    <?php return ob_get_clean();
} );
/**
 * Shortcode: [vireoka_testimonials]
 */
add_shortcode( 'vireoka_testimonials', function () {
    ob_start(); ?>
    <div class="vk-testimonial-wrap">
        <div class="vk-testimonial">
            <p>“Vireoka’s AI agents saved us months of engineering work.”</p>
            <div class="vk-testimonial-author">— CTO, FinTech Startup</div>
        </div>
        <div class="vk-testimonial">
            <p>“AtmaSphere LLM is unlike anything we’ve tested.”</p>
            <div class="vk-testimonial-author">— AI Researcher</div>
        </div>
    </div>
    <?php return ob_get_clean();
});
/**
 * Shortcode container: [vireoka_steps]...[/vireoka_steps]
 */
add_shortcode( 'vireoka_steps', function ( $atts, $content = '' ) {
    return '<div class="vk-steps-wrap">' . do_shortcode( $content ) . '</div>';
});

/**
 * Shortcode item: [vireoka_step title="Define Problem"]Your text here.[/vireoka_step]
 */
add_shortcode( 'vireoka_step', function ( $atts, $content = '' ) {
    $a = shortcode_atts([
        'title' => 'Step Title'
    ], $atts);
    ob_start(); ?>
    <div class="vk-step">
        <div class="vk-step-title"><?php echo $a['title']; ?></div>
        <div class="vk-step-body"><?php echo wp_kses_post( $content ); ?></div>
    </div>
    <?php return ob_get_clean();
});
/**
 * Shortcode: [vireoka_hero title="..." subtitle="..." button="..." url="..."]
 */
add_shortcode( 'vireoka_hero', function ($atts) {
    $a = shortcode_atts([
        'title' => 'Your AI Agent Starts Here.',
        'subtitle' => 'Build intelligent workflows with Vireoka’s multi-agent platform.',
        'button' => 'Get Started',
        'url' => '#'
    ], $atts);

    ob_start(); ?>
    <section class="vk-hero">
        <div class="vk-hero-inner">
            <h1><?php echo $a['title']; ?></h1>
            <p><?php echo $a['subtitle']; ?></p>
            <a href="<?php echo $a['url']; ?>" class="vk-btn vk-btn-primary"><?php echo $a['button']; ?></a>
        </div>
    </section>
    <?php return ob_get_clean();
});
/**
 * [vireoka_personas]...[vireoka_persona][/vireoka_personas]
 */
add_shortcode( 'vireoka_personas', function ($atts, $content = '') {
    return '<div class="vk-persona-grid">' . do_shortcode($content) . '</div>';
});

add_shortcode( 'vireoka_persona', function ($atts) {
    $a = shortcode_atts([
        'name' => 'Agent',
        'description' => 'Description goes here.',
        'icon' => ''
    ], $atts);

    return '
    <div class="vk-persona-card">
        <div class="vk-persona-icon">' . ($a['icon'] ? '<img src="'.$a['icon'].'" />' : '') . '</div>
        <div class="vk-persona-name">'.$a['name'].'</div>
        <div class="vk-persona-desc">'.$a['description'].'</div>
    </div>';
});
/**
 * [vireoka_code lang="python"]print("Hello")[/vireoka_code]
 */
add_shortcode('vireoka_code', function($atts, $content = '') {
    $a = shortcode_atts(['lang' => 'text'], $atts);

    return '<pre class="vk-code"><code class="language-'.$a['lang'].'">'.
        esc_html($content).
    '</code></pre>';
});
/**
 * [vireoka_faq] ... [/vireoka_faq]
 * [vireoka_faq_item question="What is AtmaSphere?"]It's our LLM.[/vireoka_faq_item]
 */
add_shortcode('vireoka_faq', function($atts, $content = '') {
    return '<div class="vk-faq-wrap">'.do_shortcode($content).'</div>';
});

add_shortcode('vireoka_faq_item', function($atts, $content = '') {
    $a = shortcode_atts(['question' => 'FAQ Question'], $atts);
    return '
    <div class="vk-faq-item">
        <div class="vk-faq-question">'.$a['question'].'</div>
        <div class="vk-faq-answer">'.wp_kses_post($content).'</div>
    </div>';
});
