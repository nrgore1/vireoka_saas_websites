<?php
/**
 * Plugin Name: Vireoka Home Builder
 * Description: Renders the Vireoka homepage via [vireoka_home] shortcode (styles A–F) with shared CSS.
 * Version: 2.1.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Home styles A–F (metadata only right now).
 */
function vireoka_home_styles() {
    return array(
        'A' => array( 'label' => 'Style A — Ultra Minimal',      'description' => 'Full-width hero, simple copy, one strong CTA.' ),
        'B' => array( 'label' => 'Style B — Product Grid',       'description' => 'Hero + 6 product cards, grid-forward layout.' ),
        'C' => array( 'label' => 'Style C — AI Platform',        'description' => 'Clean platform layout focused on trust & stability.' ),
        'D' => array( 'label' => 'Style D — Conversion',         'description' => 'Landing page with benefits, social proof, CTA.' ),
        'E' => array( 'label' => 'Style E — Luxe Gradient',      'description' => 'Rich gradient hero, Elite Neural Luxe vibe.' ),
        'F' => array( 'label' => 'Style F — D+E Hybrid',         'description' => 'Hybrid of D and E — luxe gradients + conversion.' ),
    );
}

/**
 * Shared inline CSS for the homepage layout.
 */
function vireoka_home_inline_css() {
    ?>
    <style id="vireoka-home-builder-css">
        .vk-home-root {
            min-height: 100vh;
            background: radial-gradient(circle at top left,#5A2FE3 0%,#020617 55%,#020617 100%);
            color: #E5E7EB;
            font-family: system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
            padding: 80px 16px 60px;
        }
        .vk-home-inner {
            max-width: 1120px;
            margin: 0 auto;
        }
        .vk-home-hero-kicker {
            font-size: 0.85rem;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            color: #A5B4FC;
            margin-bottom: 12px;
        }
        .vk-home-hero-title {
            font-size: clamp(2.5rem, 4vw, 3.4rem);
            font-weight: 700;
            color: #F9FAFB;
            margin: 0 0 12px;
        }
        .vk-home-hero-sub {
            font-size: 1.05rem;
            color: #9CA3AF;
            max-width: 640px;
        }
        .vk-home-hero-cta {
            margin-top: 28px;
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: center;
        }
        .vk-btn-primary {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 10px 22px;
            border-radius: 999px;
            border: none;
            background: linear-gradient(90deg,#E4B448,#3AF4D3);
            color: #020617;
            font-weight: 600;
            font-size: 0.95rem;
            text-decoration: none;
            cursor: pointer;
            box-shadow: 0 10px 40px rgba(0,0,0,0.55);
        }
        .vk-btn-secondary {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 9px 20px;
            border-radius: 999px;
            border: 1px solid rgba(148,163,184,0.5);
            color: #E5E7EB;
            font-size: 0.9rem;
            background: transparent;
            text-decoration: none;
            cursor: pointer;
        }
        .vk-home-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            background: rgba(15,23,42,0.9);
            border: 1px solid rgba(148,163,184,0.35);
            font-size: 0.78rem;
            color: #9CA3AF;
        }
        .vk-home-grid {
            margin-top: 48px;
            display: grid;
            grid-template-columns: repeat(auto-fit,minmax(240px,1fr));
            gap: 18px;
        }
        .vk-card {
            border-radius: 20px;
            padding: 18px 18px 16px;
            background: radial-gradient(circle at top left,rgba(90,47,227,0.35),rgba(15,23,42,0.95));
            border: 1px solid rgba(148,163,184,0.35);
            box-shadow: 0 22px 60px rgba(15,23,42,0.9);
        }
        .vk-card-title {
            font-size: 1rem;
            font-weight: 600;
            color: #E5E7EB;
            margin-bottom: 4px;
        }
        .vk-card-tag {
            font-size: 0.78rem;
            text-transform: uppercase;
            letter-spacing: 0.14em;
            color: #A5B4FC;
            margin-bottom: 10px;
        }
        .vk-card-body {
            font-size: 0.9rem;
            color: #9CA3AF;
        }
        .vk-home-section {
            margin-top: 60px;
        }
        .vk-home-section h2 {
            font-size: 1.4rem;
            margin: 0 0 10px;
            color: #E5E7EB;
        }
        .vk-home-section p {
            font-size: 0.98rem;
            color: #9CA3AF;
            max-width: 720px;
        }
        .vk-home-cta {
            margin-top: 70px;
            padding: 28px 24px;
            border-radius: 20px;
            background: radial-gradient(circle at top right,rgba(58,244,211,0.16),rgba(15,23,42,0.98));
            border: 1px solid rgba(148,163,184,0.4);
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            gap: 16px;
            align-items: center;
        }
        .vk-home-cta-text { max-width: 520px; }
        .vk-home-cta-text h3 {
            margin: 0 0 8px;
            font-size: 1.2rem;
            color: #F9FAFB;
        }
        .vk-home-cta-text p {
            margin: 0;
            font-size: 0.95rem;
            color: #9CA3AF;
        }

        /* style variants tweaks */
        .vk-style-c .vk-home-root { background: #020617; }
        .vk-style-e .vk-home-root { background: radial-gradient(circle at 0% 0%,#5A2FE3 0%,#020617 52%,#000000 100%); }
        .vk-style-f .vk-home-root { background: radial-gradient(circle at 15% 0%,#5A2FE3 0%,#020617 45%,#000000 100%); }
        .vk-style-f .vk-home-cta { border-color: #E4B448; }

        @media (max-width: 640px) {
            .vk-home-root { padding-top: 60px; }
        }
    </style>
    <?php
}
add_action( 'wp_head', 'vireoka_home_inline_css' );

/**
 * Render helpers (hero, product grid, about, CTA).
 */

function vireoka_home_render_hero( $style_key, $product, $tagline ) {
    ?>
    <section class="vk-home-hero">
        <div class="vk-home-hero-kicker">
            <?php
            switch ( $style_key ) {
                case 'B': echo esc_html( 'Vireoka Product Suite' ); break;
                case 'C': echo esc_html( 'Multi-Agent AI Platform' ); break;
                case 'D': echo esc_html( 'Agentic Systems, Deployed' ); break;
                case 'E': echo esc_html( 'Elite Neural Luxe' ); break;
                case 'F': echo esc_html( 'Conversion-Ready · Luxe-Infused' ); break;
                case 'A':
                default:  echo esc_html( 'The AI Agent Company' ); break;
            }
            ?>
        </div>
        <h1 class="vk-home-hero-title">
            <?php
            switch ( $style_key ) {
                case 'B': echo esc_html( 'Six aligned products. One shared intelligence.' ); break;
                case 'C': echo esc_html( 'Vireoka — an operating system for AI agents.' ); break;
                case 'D': echo esc_html( 'Turn AI agents into revenue, not experiments.' ); break;
                case 'E': echo esc_html( 'Vireoka — Elite Neural Systems for Builders.' ); break;
                case 'F': echo esc_html( 'High-converting agentic experiences, out of the box.' ); break;
                case 'A':
                default:  echo esc_html( 'Vireoka — The AI Agent Company.' ); break;
            }
            ?>
        </h1>
        <p class="vk-home-hero-sub">
            <?php
            switch ( $style_key ) {
                case 'B':
                    echo esc_html( 'From AtmaSphere LLM to quantum-secure stablecoins, each product shares the same aligned multi-agent core.' );
                    break;
                case 'C':
                    echo esc_html( 'Design, deploy, and observe AI agents across products — from communication training to FinOps and stablecoin rails.' );
                    break;
                case 'D':
                    echo esc_html( 'Launch new lines of business in weeks with agents that are observable, explainable, and cost-aware.' );
                    break;
                case 'E':
                    echo esc_html( 'A luxe-grade design and engineering stack for founders building the next decade of AI-native products.' );
                    break;
                case 'F':
                    echo esc_html( 'Blend deep technical differentiation with a conversion-focused story that speaks to CTOs, CFOs, and founders.' );
                    break;
                case 'A':
                default:
                    echo esc_html( 'Six breakthrough products. One shared intelligence. Built for founders who want defensible AI systems, not just demos.' );
                    break;
            }
            ?>
        </p>
        <div class="vk-home-hero-cta">
            <a href="/contact" class="vk-btn-primary">
                <?php
                echo ( 'F' === $style_key || 'D' === $style_key )
                    ? esc_html( 'Talk to Vireoka' )
                    : esc_html( 'Join the Vireoka waitlist' );
                ?>
            </a>
            <a href="/products" class="vk-btn-secondary">
                <?php echo esc_html( 'Explore the product suite' ); ?>
            </a>
            <span class="vk-home-pill">
                <span>⚙️</span>
                <span><?php echo esc_html( $product ); ?> · <?php echo esc_html( $tagline ); ?></span>
            </span>
        </div>
    </section>
    <?php
}

function vireoka_home_render_product_grid() {
    ?>
    <section class="vk-home-section vk-home-products">
        <h2>Six products, one agentic core.</h2>
        <p>Every Vireoka product shares the same aligned multi-agent foundation — so improvements in safety, observability, and cost control propagate across your entire stack.</p>
        <div class="vk-home-grid">
            <div class="vk-card">
                <div class="vk-card-tag">Core LLM</div>
                <div class="vk-card-title">AtmaSphere LLM</div>
                <div class="vk-card-body">A reasoning-first engine for orchestrating multi-agent workflows, retrieval, and tool-use in decision-heavy domains.</div>
            </div>
            <div class="vk-card">
                <div class="vk-card-tag">Communication</div>
                <div class="vk-card-title">Communication Suite</div>
                <div class="vk-card-body">AI coaching for debates, pitches, leadership communication, and viral storytelling — for students, executives, and creators.</div>
            </div>
            <div class="vk-card">
                <div class="vk-card-tag">Dating</div>
                <div class="vk-card-title">Curated Dating Platform Builder</div>
                <div class="vk-card-body">Spin up invite-only dating communities — from Indian diaspora to sports lovers and 55+ — with curated matching and safety.</div>
            </div>
            <div class="vk-card">
                <div class="vk-card-tag">Memoirs</div>
                <div class="vk-card-title">Memoir Studio</div>
                <div class="vk-card-body">Coffee-table memoirs, wedding albums, and graduation books co-designed with AI from narrative structure to print-ready layouts.</div>
            </div>
            <div class="vk-card">
                <div class="vk-card-tag">FinOps</div>
                <div class="vk-card-title">FinOps & Infra Optimizer</div>
                <div class="vk-card-body">Agents that continuously scan your cloud & AI spend, right-size infrastructure, and propose optimizations you can approve in one click.</div>
            </div>
            <div class="vk-card">
                <div class="vk-card-tag">Stablecoin</div>
                <div class="vk-card-title">Quantum-Secure Stablecoin</div>
                <div class="vk-card-body">Stable rails designed for a post-quantum world, with AI-native observability and governance baked into the protocol.</div>
            </div>
        </div>
    </section>
    <?php
}

function vireoka_home_render_about_section() {
    ?>
    <section class="vk-home-section vk-home-about">
        <h2>Why Vireoka now?</h2>
        <p>
            Vireoka is focused on greenfield spaces where multi-agent AI, strong governance, and thoughtful UX create real leverage — from education and memoirs to stablecoins and FinOps.
            We treat agent frameworks as the foundation, so improvements compound across every new product line.
        </p>
    </section>
    <?php
}

function vireoka_home_render_cta( $style_key ) {
    ?>
    <section class="vk-home-cta">
        <div class="vk-home-cta-text">
            <h3>
                <?php
                echo ( 'F' === $style_key || 'D' === $style_key )
                    ? esc_html( 'Ready to turn agents into a business line?' )
                    : esc_html( 'Build with Vireoka.' );
                ?>
            </h3>
            <p>Founders, CTOs, educators, and operators — if you are exploring AI agent frameworks for real products, Vireoka helps you move from prototype to production with alignment, observability, and cost control in view.</p>
        </div>
        <div class="vk-home-cta-actions">
            <a href="/contact" class="vk-btn-primary"><?php echo esc_html( 'Talk to us about a product or pilot' ); ?></a>
        </div>
    </section>
    <?php
}

/**
 * Shortcode: [vireoka_home style="A" product="AtmaSphere LLM" tagline="..."]
 */
function vireoka_home_shortcode( $atts = array() ) {
    $defaults = array(
        'style'   => 'A',
        'product' => 'AtmaSphere LLM',
        'tagline' => 'Multi-agent AI for real-world decisions.',
    );
    $atts = shortcode_atts( $defaults, $atts, 'vireoka_home' );

    $styles    = vireoka_home_styles();
    $style_key = strtoupper( trim( $atts['style'] ) );
    if ( ! isset( $styles[ $style_key ] ) ) {
        $style_key = 'A';
    }

    $product = sanitize_text_field( $atts['product'] );
    $tagline = sanitize_text_field( $atts['tagline'] );

    ob_start();
    ?>
    <div class="vk-home-root vk-style-<?php echo esc_attr( strtolower( $style_key ) ); ?>">
        <div class="vk-home-inner">
            <?php
            vireoka_home_render_hero( $style_key, $product, $tagline );
            vireoka_home_render_product_grid();
            vireoka_home_render_about_section();
            vireoka_home_render_cta( $style_key );
            ?>
        </div>
    </div>
    <?php
    return ob_get_clean();
}
add_shortcode( 'vireoka_home', 'vireoka_home_shortcode' );
