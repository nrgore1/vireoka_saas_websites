<?php
/**
 * Plugin Name: Vireoka Website Creator
 * Description: Vireoka-Website-Creator agent that generates full Vireoka-branded sites (variants A, B, C, D) using Vireoka UI Kit, menus, categories, and demo posts.
 * Version: 1.1.0
 * Author: Vireoka
 */
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
/**
 * return array of variants with page definitions
 */
function vwc_get_variants() {
    $variants = array();
/*
     * VARIANT A: Multi-Product Vireoka Hub
     */
    $variants['A'] = array(
        'code'        => 'A',
        'label'       => 'Vireoka Multi-Product Hub',
        'description' => 'Corporate hub for all Vireoka products.',
        'pages'       => array(),
    );
$variants['A']['pages']['home'] = array(
        'title'   => 'Home',
        'slug'    => '',
        'content' => <<<'EOT'
[vireoka_hero title="Vireoka — The AI-Agent Company" subtitle="Six breakthrough products. One shared intelligence." button="Join Waitlist" url="/contact"]

[vireoka_feature_grid]
[vireoka_feature title="AtmaSphere LLM"]The core multi-agent reasoning engine powering every Vireoka product.[/vireoka_feature]
[vireoka_feature title="Communication Suite"]AI coaching for storytelling, debate, and leadership communication.[/vireoka_feature]
[vireoka_feature title="Dating Platform Builder"]Niche, curated dating communities powered by AI agents.[/vireoka_feature]
[vireoka_feature title="Memoir Studio"]AI-designed memoirs and coffee-table books for life’s milestones.[/vireoka_feature]
[vireoka_feature title="FinOps AI"]Optimize cloud & AI infrastructure costs autonomously.[/vireoka_feature]
[vireoka_feature title="Quantum-Secure Stablecoin"]Next-gen, quantum-resilient stablecoin architecture.[/vireoka_feature]
[/vireoka_feature_grid]

[vireoka_cta title="Join the Vireoka Early Access Program" text="Be the first to deploy the Vireoka agent ecosystem in your organization or product." button_text="Join Waitlist" button_url="/contact"]
EOT
    );
$variants['A']['pages']['products'] = array(
        'title'   => 'Products',
        'slug'    => 'products',
        'content' => <<<'EOT'
[vireoka_hero title="The Vireoka Product Suite" subtitle="From reasoning engines to consumer experiences, all powered by AtmaSphere."]
[vireoka_personas]
[vireoka_persona name="AtmaSphere LLM" description="Core reasoning engine and multi-agent brain behind Vireoka."][/vireoka_persona]
[vireoka_persona name="Communication Suite" description="AI coaching for storytelling, debate, and leadership communication."][/vireoka_persona]
[vireoka_persona name="Dating Platform Builder" description="Niche, curated dating communities powered by AI agents."][/vireoka_persona]
[vireoka_persona name="Memoir Studio" description="AI-designed memoirs and coffee-table books for life’s milestones."][/vireoka_persona]
[vireoka_persona name="FinOps AI" description="Autonomous cost optimization for cloud & AI infrastructure."][/vireoka_persona]
[vireoka_persona name="Quantum-Secure Stablecoin" description="Stablecoin architecture designed for a post-quantum world."][/vireoka_persona]
[/vireoka_personas]

[vireoka_cta title="Talk to Vireoka about your next AI product" text="We partner with teams seeking deep differentiation via multi-agent systems." button_text="Book a Conversation" button_url="/contact"]
EOT
    );
$variants['A']['pages']['about'] = array(
        'title'   => 'About Vireoka',
        'slug'    => 'about',
        'content' => <<<'EOT'
[vireoka_hero title="We are building the AI-Agent Company." subtitle="Small teams + aligned AI agents = superhuman leverage."]
[vireoka_steps]
[vireoka_step title="Research & Architecture"]We design agent frameworks that coordinate reasoning, memory, and action across domains.[/vireoka_step]
[vireoka_step title="Productization"]We turn research into focused products: communication, dating, memoirs, infra, and finance.[/vireoka_step]
[vireoka_step title="Partnerships & Deployment"]We work with select teams who want differentiated, long-horizon AI systems.[/vireoka_step]
[/vireoka_steps]
EOT
    );
$variants['A']['pages']['contact'] = array(
        'title'   => 'Contact',
        'slug'    => 'contact',
        'content' => <<<'EOT'
[vireoka_hero title="Talk to Vireoka" subtitle="Founders, CTOs, educators, creators, and researchers — we’d love to hear from you." button="Email Us" url="mailto:hello@vireoka.com"]

[vireoka_feature_grid]
[vireoka_feature title="Partnerships & Pilots"]Partner with us to build agent-powered products in your domain.[/vireoka_feature]
[vireoka_feature title="Enterprise Deployments"]Discuss security, compliance, and long-term AI strategy.[/vireoka_feature]
[vireoka_feature title="Research & Collaboration"]Explore co-research on agentic systems, safety, and alignment.[/vireoka_feature]
[/vireoka_feature_grid]
[contact-form-7 id="1" title="Contact Vireoka"]
EOT
    );
/*
     * VARIANT B: AtmaSphere LLM Developer Hub
     */
    $variants['B'] = array(
        'code'        => 'B',
        'label'       => 'AtmaSphere LLM Developer Hub',
        'description' => 'Developer docs and agent blueprints for AtmaSphere.',
        'pages'       => array(),
    );
$variants['B']['pages']['home'] = array(
        'title'   => 'AtmaSphere Developers',
        'slug'    => '',
        'content' => <<<'EOT'
[vireoka_hero title="Build with AtmaSphere LLM" subtitle="A multi-agent-native reasoning engine for real-world systems." button="View API Docs" url="/api-docs"]
[vireoka_feature_grid]
[vireoka_feature title="Agent-Native Architecture"]AtmaSphere is designed to orchestrate multiple agents, memory, and tools out of the box.[/vireoka_feature]
[vireoka_feature title="Flexible Tooling"]SDKs, webhooks, and orchestration patterns for complex workflows.[/vireoka_feature]
[vireoka_feature title="Safety & Alignment"]Configurable guardrails and intent filters for safe deployments.[/vireoka_feature]
[/vireoka_feature_grid]
[vireoka_code lang="python"]
# Example: simple AtmaSphere call
import requests
resp = requests.post("https://api.vireoka.com/atmasphere/chat", json={
    "messages": [{"role": "user", "content": "Hello, AtmaSphere"}]
})
print(resp.json())
[/vireoka_code]
EOT
    );
$variants['B']['pages']['api_docs'] = array(
        'title'   => 'API Docs',
        'slug'    => 'api-docs',
        'content' => <<<'EOT'
[vireoka_hero title="AtmaSphere API" subtitle="Core endpoints for chat, tools, memory, and agent orchestration."]
[vireoka_steps]
[vireoka_step title="Authentication"]Use your API key as a Bearer token.[/vireoka_step]
[vireoka_step title="Chat Endpoint"]Send messages with role + content. Receive structured JSON responses.[/vireoka_step]
[vireoka_step title="Tools & Agents"]Register tools and agents that AtmaSphere can call during reasoning.[/vireoka_step]
[/vireoka_steps]
[vireoka_code lang="bash"]
curl https://api.vireoka.com/atmasphere/chat \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}]}'
[/vireoka_code]
EOT
    );
$variants['B']['pages']['agents'] = array(
        'title'   => 'Agent Blueprints',
        'slug'    => 'agent-blueprints',
        'content' => <<<'EOT'
[vireoka_hero title="Agent Blueprints" subtitle="Reusable patterns for multi-agent workflows."]
[vireoka_feature_grid]
[vireoka_feature title="Research + Critic + Synthesizer"]A trio of agents that research, critique, and synthesize long-form answers.[/vireoka_feature]
[vireoka_feature title="Planner + Executor"]Planner handles decomposition, executor handles tools and actions.[/vireoka_feature]
[vireoka_feature title="Guard + Narrator"]Guard enforces policy; narrator explains agent decisions to humans.[/vireoka_feature]
[/vireoka_feature_grid]
EOT
    );
/*
     * VARIANT C: Business Automation & Cost Optimization
     */
    $variants['C'] = array(
        'code'        => 'C',
        'label'       => 'Business Automation & Cloud Cost Hub',
        'description' => 'Lead-gen site for FinOps and automation offerings.',
        'pages'       => array(),
    );
$variants['C']['pages']['home'] = array(
        'title'   => 'Cloud & AI Cost Optimization',
        'slug'    => '',
        'content' => <<<'EOT'
[vireoka_hero title="Autonomous Cloud & AI Cost Optimization" subtitle="FinOps agents that watch, reason, and act on your infrastructure spend." button="Request Cost Review" url="/contact"]
[vireoka_feature_grid]
[vireoka_feature title="Continuous Spend Monitoring"]Agents that track usage, anomalies, and cost spikes in real time.[/vireoka_feature]
[vireoka_feature title="Optimization Suggestions"]Rightsizing, reserved instances, autoscaling, and GPU utilization insights.[/vireoka_feature]
[vireoka_feature title="Actionable Playbooks"]From recommendation to automated, reversible changes.[/vireoka_feature]
[/vireoka_feature_grid]
[vireoka_pricing]
EOT
    );
$variants['C']['pages']['case_studies'] = array(
        'title'   => 'Case Studies',
        'slug'    => 'case-studies',
        'content' => <<<'EOT'
[vireoka_hero title="Case Studies" subtitle="Real-world savings and automation wins."]
[vireoka_testimonials]
EOT
    );
$variants['C']['pages']['contact'] = array(
        'title'   => 'Request Cost Review',
        'slug'    => 'contact',
        'content' => <<<'EOT'
[vireoka_hero title="Request a Vireoka Cost Review" subtitle="Share your current stack and we’ll show you where agents can help." button="Email Vireoka" url="mailto:hello@vireoka.com"]

[vireoka_faq]
[vireoka_faq_item question="Which clouds do you support?"]We work across AWS, Azure, GCP, and hybrid setups.[/vireoka_faq_item]
[vireoka_faq_item question="How do you measure ROI?"]We track infra cost savings, stability metrics, and team time saved.[/vireoka_faq_item]
[/vireoka_faq]
EOT
    );
/*
     * VARIANT D: Consumer AI Products (Dating, Memoirs, Coaching, Viral)
     */
    $variants['D'] = array(
        'code'        => 'D',
        'label'       => 'Consumer AI Products Hub',
        'description' => 'Vireoka site focused on dating, memoirs, coaching, and viral tools.',
        'pages'       => array(),
    );
$variants['D']['pages']['home'] = array(
        'title'   => 'Vireoka for People & Stories',
        'slug'    => '',
        'content' => <<<'EOT'
[vireoka_hero title="AI for Love, Memory, and Voice." subtitle="Build dating communities, memoirs, and confident communicators with Vireoka agents." button="Explore Experiences" url="/experiences"]
[vireoka_feature_grid]
[vireoka_feature title="Dating Communities"]Launch curated, invite-only dating platforms for diaspora, interests, and stages of life.[/vireoka_feature]
[vireoka_feature title="Memoir Studio"]Turn life events into AI-designed coffee-table books.[/vireoka_feature]
[vireoka_feature title="Coaching & Debate"]AI coaches for students, professionals, and creators.[/vireoka_feature]
[vireoka_feature title="Viral Storytelling"]Short-form script and hook engines for modern creators.[/vireoka_feature]
[/vireoka_feature_grid]
[vireoka_cta title="Ready to build with Vireoka?" text="Whether you’re building for love, legacy, or voice, we can help." button_text="Talk to Vireoka" button_url="/contact"]
EOT
    );

$variants['D']['pages']['dating'] = array(
        'title'   => 'AI Dating Platform Builder',
        'slug'    => 'dating-platform-builder',
        'content' => <<<'EOT'
[vireoka_hero title="Build a Curated Dating Community" subtitle="Invite-only, AI-assisted dating experiences for specific communities and interests." button="Book a Demo" url="/contact"]
[vireoka_steps]
[vireoka_step title="Define Your Community"]Diaspora, interests, values, or age-based communities.[/vireoka_step]
[vireoka_step title="Configure Safety & Onboarding"]AI moderation, profile review, and onboarding flows.[/vireoka_step]
[vireoka_step title="Launch with AI Matching"]Vireoka agents help curate connections, intros, and follow-ups.[/vireoka_step]
[/vireoka_steps]
EOT
    );
$variants['D']['pages']['memoir'] = array(
        'title'   => 'Memoir & Coffee-Table Books',
        'slug'    => 'memoir-studio',
        'content' => <<<'EOT'
[vireoka_hero title="Turn Stories into Books" subtitle="Weddings, graduations, births, anniversaries, and lives well lived." button="Start a Memoir" url="/contact"]
[vireoka_steps]
[vireoka_step title="Capture Memories"]Upload photos, notes, and audio messages from loved ones.[/vireoka_step]
[vireoka_step title="Curate & Design"]AI suggests layouts, themes, and visual storytelling arcs.[/vireoka_step]
[vireoka_step title="Export & Print"]Generate print-ready files for coffee-table books.[/vireoka_step]
[/vireoka_steps]
EOT
    );
$variants['D']['pages']['coaching'] = array(
        'title'   => 'AI Coaching & Debate',
        'slug'    => 'coaching-debate',
        'content' => <<<'EOT'
[vireoka_hero title="Confidence Through Practice" subtitle="AI coaches for debate, public speaking, and interviews." button="Talk to Us" url="/contact"]
[vireoka_feature_grid]
[vireoka_feature title="Debate Practice"]Structured rounds with feedback on clarity, logic, and persuasion.[/vireoka_feature]
[vireoka_feature title="Presentation Coaching"]Practice keynotes, pitches, and internal talks with AI feedback.[/vireoka_feature]
[vireoka_feature title="Student Programs"]School-ready curricula for debate clubs and communication labs.[/vireoka_feature]
[/vireoka_feature_grid]
EOT
    );
return $variants;
}
/**
 * Create / update pages for chosen variant.
 * Returns array key => page_id
 */
function vwc_generate_pages( $variant_code ) {
    $variants = vwc_get_variants();
    if ( ! isset( $variants[ $variant_code ] ) ) {
        return new WP_Error( 'invalid_variant', 'Unknown variant.' );
    }
$variant = $variants[ $variant_code ];
    $pages   = $variant['pages'];
    $created = array();
    $home_id = 0;
foreach ( $pages as $key => $spec ) {
        $slug    = isset( $spec['slug'] ) ? $spec['slug'] : '';
        $title   = $spec['title'];
        $content = $spec['content'];
$existing = null;
        if ( $slug !== '' ) {
            $existing = get_page_by_path( $slug );
        } else {
            $existing = get_page_by_title( $title );
        }
$postarr = array(
            'post_title'   => $title,
            'post_name'    => $slug ? $slug : sanitize_title( $title ),
            'post_type'    => 'page',
            'post_status'  => 'publish',
            'post_content' => $content,
        );
if ( $existing ) {
            $postarr['ID'] = $existing->ID;
            $page_id       = wp_update_post( $postarr );
        } else {
            $page_id = wp_insert_post( $postarr );
        }
if ( ! is_wp_error( $page_id ) ) {
            $created[ $key ] = $page_id;
            if ( $key === 'home' ) {
                $home_id = $page_id;
            }
        }
    }
if ( $home_id ) {
        update_option( 'page_on_front', $home_id );
        update_option( 'show_on_front', 'page' );
    }
return $created;
}
/**
 * Setup categories and demo posts per variant.
 */
function vwc_setup_categories_and_posts( $variant_code ) {
$cat_map = array(
        'A' => array( 'AI Agents', 'Enterprise AI', 'Consumer AI', 'Research' ),
        'B' => array( 'API Guides', 'SDKs', 'Agent Patterns', 'Changelog' ),
        'C' => array( 'FinOps', 'Cloud Optimization', 'Case Studies', 'Playbooks' ),
        'D' => array( 'Dating Stories', 'Memoirs', 'Coaching', 'Viral Campaigns' ),
    );
if ( ! isset( $cat_map[ $variant_code ] ) ) {
        return;
    }
$created_terms = array();
foreach ( $cat_map[ $variant_code ] as $cat_name ) {
        $term = get_term_by( 'name', $cat_name, 'category' );
        if ( ! $term ) {
            $term_result = wp_insert_term( $cat_name, 'category' );
            if ( ! is_wp_error( $term_result ) ) {
                $created_terms[ $cat_name ] = $term_result['term_id'];
            }
        } else {
            $created_terms[ $cat_name ] = $term->term_id;
        }
    }
// Simple demo posts per variant
    $demo_posts = array();
if ( $variant_code === 'A' ) {
        $demo_posts[] = array(
            'title'   => 'Introducing the Vireoka Product Suite',
            'content' => '[vireoka_feature_grid][vireoka_feature title="One Brain, Many Products"]All powered by AtmaSphere.[/vireoka_feature][/vireoka_feature_grid]',
            'cat'     => 'AI Agents',
        );
        $demo_posts[] = array(
            'title'   => 'Why AI Agents (Not Just Tools) Matter',
            'content' => 'AI agents help you achieve outcomes, not just complete tasks.',
            'cat'     => 'Research',
        );
    } elseif ( $variant_code === 'B' ) {
        $demo_posts[] = array(
            'title'   => 'Getting Started with the AtmaSphere API',
            'content' => '[vireoka_code lang="python"]# Install client[/vireoka_code]',
            'cat'     => 'API Guides',
        );
        $demo_posts[] = array(
            'title'   => 'Agent Pattern: Researcher + Critic + Synthesizer',
            'content' => 'A robust multi-agent pattern for deep research tasks.',
            'cat'     => 'Agent Patterns',
        );
    } elseif ( $variant_code === 'C' ) {
        $demo_posts[] = array(
            'title'   => 'How Vireoka Agents Reduced Cloud Spend by 32%',
            'content' => 'A FinOps case study with real numbers and agent workflows.',
            'cat'     => 'Case Studies',
        );
        $demo_posts[] = array(
            'title'   => 'Top 5 FinOps Playbooks for 2025',
            'content' => '[vireoka_feature_grid][vireoka_feature title="Rightsizing"]Cut waste without sacrificing performance.[/vireoka_feature][/vireoka_feature_grid]',
            'cat'     => 'Playbooks',
        );
    } elseif ( $variant_code === 'D' ) {
        $demo_posts[] = array(
            'title'   => 'From Match to Memoir: A Vireoka Love Story',
            'content' => 'How a curated dating community and memoir studio worked together.',
            'cat'     => 'Dating Stories',
        );
        $demo_posts[] = array(
            'title'   => 'How AI Coaching Helped a Student Win a Debate Championship',
            'content' => 'Vireoka coaching agents helped refine arguments and delivery.',
            'cat'     => 'Coaching',
        );
    }
foreach ( $demo_posts as $spec ) {
        $existing = get_page_by_title( $spec['title'], OBJECT, 'post' );
        $cat_name = $spec['cat'];
        $cat_id   = isset( $created_terms[ $cat_name ] ) ? $created_terms[ $cat_name ] : 0;
$postarr = array(
            'post_title'   => $spec['title'],
            'post_content' => $spec['content'],
            'post_status'  => 'publish',
            'post_type'    => 'post',
        );
if ( $existing ) {
            $postarr['ID'] = $existing->ID;
            $post_id       = wp_update_post( $postarr );
        } else {
            $post_id = wp_insert_post( $postarr );
        }
if ( ! is_wp_error( $post_id ) && $cat_id ) {
            wp_set_post_terms( $post_id, array( $cat_id ), 'category', false );
        }
    }
}
/**
 * Create a primary menu and assign pages per variant.
 */
function vwc_setup_menu( $variant_code, $created_pages ) {
// Desired menu name
    $menu_name = 'Vireoka Primary ' . $variant_code;
// Check if menu exists
    $menu = wp_get_nav_menu_object( $menu_name );
    if ( ! $menu ) {
        $menu_id = wp_create_nav_menu( $menu_name );
    } else {
        $menu_id = $menu->term_id;
    }
if ( is_wp_error( $menu_id ) || ! $menu_id ) {
        return;
    }
// Determine which pages go into menu per variant
    $items = array();
if ( $variant_code === 'A' ) {
        $items = array(
            array( 'type' => 'page_key', 'key' => 'home',     'title' => 'Home' ),
            array( 'type' => 'page_key', 'key' => 'products', 'title' => 'Products' ),
            array( 'type' => 'page_key', 'key' => 'about',    'title' => 'About' ),
            array( 'type' => 'page_key', 'key' => 'contact',  'title' => 'Contact' ),
        );
    } elseif ( $variant_code === 'B' ) {
        $items = array(
            array( 'type' => 'page_key', 'key' => 'home',      'title' => 'Home' ),
            array( 'type' => 'page_key', 'key' => 'api_docs',  'title' => 'API Docs' ),
            array( 'type' => 'page_key', 'key' => 'agents',    'title' => 'Agent Blueprints' ),
        );
    } elseif ( $variant_code === 'C' ) {
        $items = array(
            array( 'type' => 'page_key', 'key' => 'home',        'title' => 'Home' ),
            array( 'type' => 'page_key', 'key' => 'case_studies','title' => 'Case Studies' ),
            array( 'type' => 'page_key', 'key' => 'contact',     'title' => 'Cost Review' ),
        );
    } elseif ( $variant_code === 'D' ) {
        $items = array(
            array( 'type' => 'page_key', 'key' => 'home',    'title' => 'Home' ),
            array( 'type' => 'page_key', 'key' => 'dating',  'title' => 'Dating' ),
            array( 'type' => 'page_key', 'key' => 'memoir',  'title' => 'Memoirs' ),
            array( 'type' => 'page_key', 'key' => 'coaching','title' => 'Coaching' ),
        );
    }
// Clear existing menu items (optional – keep simple for now)
    $existing_items = wp_get_nav_menu_items( $menu_id );
    if ( ! empty( $existing_items ) ) {
        foreach ( $existing_items as $item ) {
            wp_delete_post( $item->ID, true );
        }
    }

// Add new menu items
    foreach ( $items as $item_spec ) {
if ( $item_spec['type'] === 'page_key' ) {
            $key = $item_spec['key'];
            if ( ! isset( $created_pages[ $key ] ) ) {
                continue;
            }
            $page_id = $created_pages[ $key ];
wp_update_nav_menu_item( $menu_id, 0, array(
                'menu-item-title'     => $item_spec['title'],
                'menu-item-object'    => 'page',
                'menu-item-object-id' => $page_id,
                'menu-item-status'    => 'publish',
                'menu-item-type'      => 'post_type',
            ) );
        }
    }
// Assign menu to primary location if available
    $locations = get_theme_mod( 'nav_menu_locations' );
    if ( ! is_array( $locations ) ) {
        $locations = array();
    }
// Astra usually uses 'primary' location
    if ( isset( $locations['primary'] ) || empty( $locations ) ) {
        $locations['primary'] = $menu_id;
    } else {
        // fallback: first available location key
        $keys = array_keys( $locations );
        if ( ! empty( $keys ) ) {
            $locations[ $keys[0] ] = $menu_id;
        }
    }
set_theme_mod( 'nav_menu_locations', $locations );
}
/**
 * Top-level function: generate full site for variant (pages + menu + categories/posts)
 */
function vwc_generate_site( $variant_code ) {
    $variant_code = strtoupper( $variant_code );
$pages = vwc_generate_pages( $variant_code );
    if ( is_wp_error( $pages ) ) {
        return $pages;
    }
vwc_setup_categories_and_posts( $variant_code );
    vwc_setup_menu( $variant_code, $pages );
update_option( 'vwc_last_variant', $variant_code );
    update_option( 'vwc_last_pages', $pages );
return $pages;
}
/**
 * Admin menu & settings page.
 */
add_action( 'admin_menu', function () {
    add_options_page(
        'Vireoka Website Creator',
        'Vireoka Creator',
        'manage_options',
        'vireoka-website-creator',
        'vwc_render_settings_page'
    );
} );
function vwc_render_settings_page() {
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }
$variants = vwc_get_variants();
    $current  = get_option( 'vwc_last_variant', 'A' );
    $message  = '';
if ( isset( $_POST['vwc_generate_nonce'] ) && wp_verify_nonce( $_POST['vwc_generate_nonce'], 'vwc_generate_action' ) ) {
        $selected = sanitize_text_field( $_POST['vwc_variant'] ?? 'A' );
        $result   = vwc_generate_site( $selected );
        if ( is_wp_error( $result ) ) {
            $message = '<div class="notice notice-error"><p>' . esc_html( $result->get_error_message() ) . '</p></div>';
        } else {
            $message = '<div class="notice notice-success"><p>Generated/updated pages, menu, and demo content for variant ' . esc_html( $selected ) . '.</p></div>';
            $current = $selected;
        }
    }
echo '<div class="wrap"><h1>Vireoka Website Creator</h1>';
    echo wp_kses_post( $message );
    echo '<form method="post">';
    wp_nonce_field( 'vwc_generate_action', 'vwc_generate_nonce' );
    echo '<p>Select which variant you want to generate:</p>';
    echo '<table class="form-table"><tbody>';
foreach ( $variants as $code => $variant ) {
        echo '<tr><th scope="row">';
        echo '<label>';
        printf(
            '<input type="radio" name="vwc_variant" value="%s" %s /> %s',
            esc_attr( $code ),
            checked( $current, $code, false ),
            esc_html( $variant['label'] )
        );
        echo '</label>';
        echo '</th><td>';
        echo '<p>' . esc_html( $variant['description'] ) . '</p>';
        echo '</td></tr>';
    }
echo '</tbody></table>';
    submit_button( 'Generate Vireoka Site' );
    echo '</form></div>';
}
/**
 * REST endpoint so external scripts can trigger generation.
 * Route: /wp-json/vireoka/v1/generate
 */
add_action( 'rest_api_init', function () {
    register_rest_route( 'vireoka/v1', '/generate', array(
        'methods'             => 'POST',
        'permission_callback' => function () {
            return current_user_can( 'manage_options' );
        },
        'callback'            => function ( WP_REST_Request $request ) {
            $variant = strtoupper( $request->get_param( 'variant' ) ?: 'A' );
            $result  = vwc_generate_site( $variant );
            if ( is_wp_error( $result ) ) {
                return new WP_REST_Response(
                    array( 'ok' => false, 'error' => $result->get_error_message() ),
                    400
                );
            }
            return array(
                'ok'      => true,
                'variant' => $variant,
                'pages'   => $result,
            );
        },
    ) );
} );
