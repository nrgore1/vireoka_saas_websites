<?php
/**
 * Plugin Name: Vireoka Blocks
 * Description: Custom blocks for Vireoka (product cards, CTAs, neural hero).
 * Version: 0.1.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function vireoka_blocks_register() {

    register_block_type( 'vireoka/product-cards', array(
        'render_callback' => 'vireoka_render_product_cards',
    ) );

    register_block_type( 'vireoka/cta', array(
        'render_callback' => 'vireoka_render_cta',
    ) );

    register_block_type( 'vireoka/neural-hero', array(
        'render_callback' => 'vireoka_render_neural_hero',
    ) );
}
add_action( 'init', 'vireoka_blocks_register' );

function vireoka_render_product_cards( $attributes, $content ) {
    ob_start();
    ?>
    <div class="vireoka-product-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:20px;">
        <div class="card-dark">
            <h3>AtmaSphere LLM</h3>
            <p>The core intelligence layer behind Vireoka’s agents.</p>
        </div>
        <div class="card-dark">
            <h3>Communication Suite</h3>
            <p>AI-guided communication, debate, and storytelling.</p>
        </div>
        <div class="card-dark">
            <h3>Dating Platform Builder</h3>
            <p>Launch curated, niche dating communities with smart matching.</p>
        </div>
        <div class="card-dark">
            <h3>Memoir Studio</h3>
            <p>Create AI-designed coffee-table books for life’s biggest moments.</p>
        </div>
        <div class="card-dark">
            <h3>FinOps AI</h3>
            <p>Autonomous cloud optimization to reduce spend and improve stability.</p>
        </div>
        <div class="card-dark">
            <h3>Quantum-Secure Stablecoin</h3>
            <p>A radically secure stablecoin architecture for the post-quantum era.</p>
        </div>
    </div>
    <?php
    return ob_get_clean();
}

function vireoka_render_cta( $attributes, $content ) {
    ob_start();
    ?>
    <section style="text-align:center;padding:40px;background:#0B1220;border-radius:16px;border:1px solid #1F2937;">
        <h2 style="color:#F9FAFB;margin-bottom:8px;">Join the Vireoka waitlist</h2>
        <p style="color:#9CA3AF;margin-bottom:16px;">Be first to experience the Vireoka agent ecosystem and AtmaSphere LLM.</p>
        <p style="color:#9CA3AF;font-size:13px;">[Insert your email form shortcode here]</p>
    </section>
    <?php
    return ob_get_clean();
}

function vireoka_render_neural_hero( $attributes, $content ) {
    ob_start();
    ?>
    <section style="padding:80px 20px;">
        <div class="neural-gradient" style="max-width:960px;margin:0 auto;padding:48px;border-radius:24px;box-shadow:0 18px 45px rgba(0,0,0,0.6);">
            <h1 style="text-align:center;color:#020617;font-size:40px;margin:0 0 12px;">Vireoka — The AI-Agent Company</h1>
            <p style="text-align:center;color:#020617;font-size:15px;margin:0 0 20px;">
                Six breakthrough products. One shared agentic brain. A new era of AI ecosystems.
            </p>
        </div>
    </section>
    <?php
    return ob_get_clean();
}
