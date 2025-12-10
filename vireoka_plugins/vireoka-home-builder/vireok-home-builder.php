<?php
/**
 * Plugin Name: Vireoka Home Builder
 * Description: Provides 6 Vireoka homepage styles (A–F), bulk apply via WP-CLI, admin UI, menus, and SEO schema.
 * Version: 2.0.0
 * Author: Vireoka
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Home styles A–F.
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
 * Inline CSS (shared).
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
        .vk-style-c .vk-home-root { background: #020617; }
        .vk-style-e .vk-home-root { background: radial-gradient(circle at 0% 0%,#5A2FE3 0%,#020617 52%,#000000 100%); }
        .vk-style-f .vk-home-root { background: radial-gradient(circle at 15% 0%,#5A2FE3 0%,#020617 45%,#000000 100%); }
        .vk-style-f .vk-home-cta { border-color: #E4B448; }
        @media (max-width: 640px) { .vk-home-root { padding-top: 60px; } }
    </style>
    <?php
}
add_action( 'wp_head', 'vireoka_home_inline_css' );

/**
 * Render helpers.
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

/**
 * Core engine used by CLI + Admin UI.
 */
function vireoka_home_apply_to_page( $page_id, $style, $product, $set_home = false ) {
    $page_id = (int) $page_id;
    if ( ! $page_id || ! get_post( $page_id ) ) {
        return new WP_Error( 'invalid_page', 'Invalid page ID' );
    }

    $styles    = vireoka_home_styles();
    $style_key = strtoupper( trim( $style ) );
    if ( ! isset( $styles[ $style_key ] ) ) {
        $style_key = 'A';
    }

    $product  = sanitize_text_field( $product );
    $shortcode = sprintf( '[vireoka_home style="%s" product="%s"]', $style_key, $product );

    wp_update_post(
        array(
            'ID'           => $page_id,
            'post_content' => $shortcode,
        )
    );

    // Make Elementor-friendly if used.
    update_post_meta( $page_id, '_elementor_edit_mode', 'builder' );
    update_post_meta( $page_id, '_elementor_template_type', 'wp-page' );
    update_post_meta( $page_id, '_wp_page_template', 'elementor_canvas' );

    if ( $set_home ) {
        update_option( 'show_on_front', 'page' );
        update_option( 'page_on_front', $page_id );
    }

    return true;
}

/**
 * Simple admin UI: Settings → Vireoka Home
 */
function vireoka_home_admin_menu() {
    add_options_page(
        'Vireoka Home',
        'Vireoka Home',
        'manage_options',
        'vireoka-home',
        'vireoka_home_admin_page'
    );
}
add_action( 'admin_menu', 'vireoka_home_admin_menu' );

function vireoka_home_admin_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }

    $styles = vireoka_home_styles();
    $pages  = get_pages( array( 'post_status' => array( 'publish' ) ) );

    ?>
    <div class="wrap">
        <h1>Vireoka Home Layouts</h1>
        <p>Select a style and primary product per page. On save, the plugin will overwrite page content with the appropriate <code>[vireoka_home]</code> shortcode.</p>
        <form method="post">
            <?php wp_nonce_field( 'vireoka_home_save', 'vireoka_home_nonce' ); ?>
            <table class="widefat striped">
                <thead>
                <tr>
                    <th>Page</th>
                    <th>Style</th>
                    <th>Product Label</th>
                </tr>
                </thead>
                <tbody>
                <?php foreach ( $pages as $p ) : ?>
                    <tr>
                        <td>
                            <?php echo esc_html( $p->post_title ); ?>
                            <br><code>ID: <?php echo (int) $p->ID; ?></code>
                        </td>
                        <td>
                            <select name="vireoka_style[<?php echo (int) $p->ID; ?>]">
                                <option value="">(no change)</option>
                                <?php foreach ( $styles as $key => $def ) : ?>
                                    <option value="<?php echo esc_attr( $key ); ?>"><?php echo esc_html( $key . ' — ' . $def['label'] ); ?></option>
                                <?php endforeach; ?>
                            </select>
                        </td>
                        <td>
                            <input type="text"
                                   name="vireoka_product[<?php echo (int) $p->ID; ?>]"
                                   value=""
                                   placeholder="e.g. AtmaSphere LLM"
                                   style="width: 100%;" />
                        </td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
            <p><button type="submit" class="button button-primary">Apply layouts</button></p>
        </form>
    </div>
    <?php
}

function vireoka_home_admin_save() {
    if ( ! is_admin() || ! isset( $_POST['vireoka_home_nonce'] ) ) {
        return;
    }
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }
    if ( ! wp_verify_nonce( $_POST['vireoka_home_nonce'], 'vireoka_home_save' ) ) {
        return;
    }

    $styles   = isset( $_POST['vireoka_style'] ) ? (array) $_POST['vireoka_style'] : array();
    $products = isset( $_POST['vireoka_product'] ) ? (array) $_POST['vireoka_product'] : array();

    foreach ( $styles as $page_id => $style ) {
        $page_id = (int) $page_id;
        $style   = trim( $style );
        if ( ! $style ) {
            continue;
        }
        $product = isset( $products[ $page_id ] ) && $products[ $page_id ]
            ? $products[ $page_id ]
            : 'Vireoka Product';

        vireoka_home_apply_to_page( $page_id, $style, $product, false );
    }
}
add_action( 'admin_init', 'vireoka_home_admin_save' );

/**
 * SEO schema + OG (light, avoids clashing with RankMath).
 */
function vireoka_home_schema() {
    if ( ! is_front_page() ) {
        return;
    }

    $site_name = get_bloginfo( 'name' );
    $url       = home_url( '/' );

    ?>
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "<?php echo esc_js( $site_name ); ?>",
      "url": "<?php echo esc_url( $url ); ?>",
      "logo": "<?php echo esc_url( get_site_icon_url() ); ?>",
      "sameAs": []
    }
    </script>
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "<?php echo esc_js( $site_name ); ?>",
      "url": "<?php echo esc_url( $url ); ?>",
      "potentialAction": {
        "@type": "SearchAction",
        "target": "<?php echo esc_url( $url ); ?>?s={search_term_string}",
        "query-input": "required name=search_term_string"
      }
    }
    </script>
    <?php

    // Only add OG meta if RankMath is not active.
    if ( ! defined( 'RANK_MATH_VERSION' ) ) :
        ?>
        <meta property="og:title" content="<?php echo esc_attr( $site_name ); ?>" />
        <meta property="og:url" content="<?php echo esc_url( $url ); ?>" />
        <meta property="og:type" content="website" />
        <?php
    endif;
}
add_action( 'wp_head', 'vireoka_home_schema', 5 );

/**
 * Create primary + footer menus on activation if empty.
 */
function vireoka_home_ensure_menus() {
    $locations = get_nav_menu_locations();
    $primary_slug = 'primary';
    if ( empty( $locations[ $primary_slug ] ) ) {
        $menu_id = wp_create_nav_menu( 'Primary' );
        // Try to attach key pages if they exist.
        $titles = array( 'Vireoka Home', 'Products', 'AtmaSphere LLM', 'FinOps AI', 'Memoir Studio', 'Quantum-Secure Stablecoin', 'About', 'Blog', 'Contact' );
        foreach ( $titles as $t ) {
            $page = get_page_by_title( $t );
            if ( $page ) {
                wp_update_nav_menu_item(
                    $menu_id,
                    0,
                    array(
                        'menu-item-title'  => $page->post_title,
                        'menu-item-object' => 'page',
                        'menu-item-object-id' => $page->ID,
                        'menu-item-type'   => 'post_type',
                        'menu-item-status' => 'publish',
                    )
                );
            }
        }
        $locations[ $primary_slug ] = $menu_id;
        set_nav_menu_locations( $locations );
    }
}
register_activation_hook( __FILE__, 'vireoka_home_ensure_menus' );

/**
 * WP-CLI integration.
 */
if ( defined( 'WP_CLI' ) && WP_CLI ) {
    class Vireoka_Home_CLI extends WP_CLI_Command {

        /**
         * Apply a Vireoka home layout to a page using the shortcode.
         *
         * ## OPTIONS
         *
         * --page_id=<id>
         * : Page ID to update.
         *
         * --style=<A-F>
         * : Layout style (A,B,C,D,E,F).
         *
         * [--product=<name>]
         * : Product label to highlight in the hero pill.
         *
         * [--set_home=<0|1>]
         * : If 1, make this page the site front page.
         */
        public function apply( $args, $assoc_args ) {
            $page_id = isset( $assoc_args['page_id'] ) ? (int) $assoc_args['page_id'] : 0;
            $style   = isset( $assoc_args['style'] ) ? strtoupper( $assoc_args['style'] ) : 'A';
            $product = isset( $assoc_args['product'] ) ? $assoc_args['product'] : 'Vireoka Product';

            if ( ! $page_id || ! get_post( $page_id ) ) {
                WP_CLI::error( 'Invalid or missing --page_id' );
            }

            $set_home = isset( $assoc_args['set_home'] ) && (int) $assoc_args['set_home'] === 1;

            $result = vireoka_home_apply_to_page( $page_id, $style, $product, $set_home );
            if ( is_wp_error( $result ) ) {
                WP_CLI::error( $result->get_error_message() );
            }

            WP_CLI::success( sprintf( 'Applied Vireoka home style %s to page %d.', $style, $page_id ) );
        }

        /**
         * Bulk apply styles to known pages based on titles.
         *
         * ## EXAMPLES
         *     wp vireoka-home bulk
         */
        public function bulk( $args, $assoc_args ) {
            $map = array(
                'Vireoka Home'              => array( 'style' => 'F', 'product' => 'Vireoka Platform', 'home' => true ),
                'Products'                  => array( 'style' => 'B', 'product' => 'Vireoka Product Suite' ),
                'AtmaSphere LLM'            => array( 'style' => 'C', 'product' => 'AtmaSphere LLM' ),
                'FinOps AI'                 => array( 'style' => 'D', 'product' => 'FinOps AI' ),
                'Memoir Studio'             => array( 'style' => 'E', 'product' => 'Memoir Studio' ),
                'Quantum-Secure Stablecoin' => array( 'style' => 'F', 'product' => 'Quantum-Secure Stablecoin' ),
                'About'                     => array( 'style' => 'A', 'product' => 'About Vireoka' ),
                'Blog'                      => array( 'style' => 'E', 'product' => 'Insights & Updates' ),
                'Contact'                   => array( 'style' => 'D', 'product' => 'Contact Vireoka' ),
            );

            foreach ( $map as $title => $cfg ) {
                $page = get_page_by_title( $title );
                if ( ! $page ) {
                    WP_CLI::warning( "Page not found: {$title}" );
                    continue;
                }
                $set_home = ! empty( $cfg['home'] );
                $result   = vireoka_home_apply_to_page( $page->ID, $cfg['style'], $cfg['product'], $set_home );
                if ( is_wp_error( $result ) ) {
                    WP_CLI::warning( "Failed to update {$title}: " . $result->get_error_message() );
                } else {
                    WP_CLI::success( "Updated {$title} (ID {$page->ID}) with style {$cfg['style']}" );
                }
            }
        }
    }

    WP_CLI::add_command( 'vireoka-home', 'Vireoka_Home_CLI' );
}