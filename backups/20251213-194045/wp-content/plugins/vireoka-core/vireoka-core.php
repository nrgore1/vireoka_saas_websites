<?php
/**
 * Plugin Name: Vireoka Core
 * Description: Core functionality for Vireoka platform (Products CPT, admin UI, SEO/OG).
 * Version: 1.1.0
 */
if (!defined('ABSPATH')) exit;

final class Vireoka_Core {
  const CPT = 'vireoka_product';
  const TAX = 'vireoka_product_tag';

  public static function boot(): void {
    add_action('init', [__CLASS__, 'register_cpt']);
    add_action('init', [__CLASS__, 'register_taxonomy']);

    add_action('add_meta_boxes', [__CLASS__, 'add_metaboxes']);
    add_action('save_post', [__CLASS__, 'save_metaboxes']);

    add_action('admin_menu', [__CLASS__, 'admin_menu']);
    add_action('admin_init', [__CLASS__, 'register_settings']);

    add_filter('template_include', [__CLASS__, 'pricing_template_router']);

    add_action('wp_head', [__CLASS__, 'output_seo_og'], 2);

    add_shortcode('vireoka_products_grid', [__CLASS__, 'shortcode_products_grid']);
  }

  public static function register_cpt(): void {
    $labels = [
      'name' => 'Products',
      'singular_name' => 'Product',
      'add_new_item' => 'Add New Product',
      'edit_item' => 'Edit Product',
      'new_item' => 'New Product',
      'view_item' => 'View Product',
      'search_items' => 'Search Products',
    ];

    register_post_type(self::CPT, [
      'labels' => $labels,
      'public' => true,
      'has_archive' => true,
      'rewrite' => ['slug' => 'products', 'with_front' => false],
      'menu_icon' => 'dashicons-grid-view',
      'supports' => ['title', 'editor', 'thumbnail', 'excerpt', 'revisions'],
      'show_in_rest' => true,
    ]);
  }

  public static function register_taxonomy(): void {
    register_taxonomy(self::TAX, [self::CPT], [
      'label' => 'Product Tags',
      'public' => true,
      'rewrite' => ['slug' => 'product-tag', 'with_front' => false],
      'show_in_rest' => true,
    ]);
  }

  public static function add_metaboxes(): void {
    add_meta_box(
      'vireoka_product_meta',
      'Vireoka Product Details',
      [__CLASS__, 'render_product_metabox'],
      self::CPT,
      'normal',
      'high'
    );
  }

  public static function render_product_metabox(\WP_Post $post): void {
    wp_nonce_field('vireoka_product_meta_save', 'vireoka_product_meta_nonce');

    $fields = [
      'subtitle' => get_post_meta($post->ID, '_vireoka_subtitle', true),
      'badge' => get_post_meta($post->ID, '_vireoka_badge', true),
      'cta_label' => get_post_meta($post->ID, '_vireoka_cta_label', true) ?: 'Request Early Access',
      'cta_url' => get_post_meta($post->ID, '_vireoka_cta_url', true) ?: '/contact/',
      'accent' => get_post_meta($post->ID, '_vireoka_accent', true) ?: 'luxe',
      'order' => get_post_meta($post->ID, '_vireoka_order', true) ?: '0',
    ];

    ?>
    <style>
      .vireoka-meta-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
      .vireoka-meta-grid label{font-weight:600;display:block;margin-bottom:6px}
      .vireoka-meta-grid input,.vireoka-meta-grid select{width:100%}
      .vireoka-meta-help{color:#666;margin-top:6px;font-size:12px}
    </style>
    <div class="vireoka-meta-grid">
      <div>
        <label>Subtitle</label>
        <input type="text" name="vireoka_subtitle" value="<?php echo esc_attr($fields['subtitle']); ?>" />
        <div class="vireoka-meta-help">One-liner under the product title.</div>
      </div>
      <div>
        <label>Badge</label>
        <input type="text" name="vireoka_badge" value="<?php echo esc_attr($fields['badge']); ?>" />
        <div class="vireoka-meta-help">Example: “Flagship”, “Enterprise”, “Launching Soon”.</div>
      </div>

      <div>
        <label>CTA Label</label>
        <input type="text" name="vireoka_cta_label" value="<?php echo esc_attr($fields['cta_label']); ?>" />
      </div>
      <div>
        <label>CTA URL</label>
        <input type="text" name="vireoka_cta_url" value="<?php echo esc_attr($fields['cta_url']); ?>" />
      </div>

      <div>
        <label>Accent Theme</label>
        <select name="vireoka_accent">
          <?php foreach (['luxe','neural','teal','gold'] as $k): ?>
            <option value="<?php echo esc_attr($k); ?>" <?php selected($fields['accent'], $k); ?>><?php echo esc_html($k); ?></option>
          <?php endforeach; ?>
        </select>
        <div class="vireoka-meta-help">Controls hero background flavor on single product page.</div>
      </div>

      <div>
        <label>Sort Order (lower = earlier)</label>
        <input type="number" name="vireoka_order" value="<?php echo esc_attr($fields['order']); ?>" />
      </div>
    </div>
    <?php
  }

  public static function save_metaboxes(int $post_id): void {
    if (get_post_type($post_id) !== self::CPT) return;
    if (!isset($_POST['vireoka_product_meta_nonce']) || !wp_verify_nonce($_POST['vireoka_product_meta_nonce'], 'vireoka_product_meta_save')) return;
    if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) return;
    if (!current_user_can('edit_post', $post_id)) return;

    $map = [
      'vireoka_subtitle' => '_vireoka_subtitle',
      'vireoka_badge' => '_vireoka_badge',
      'vireoka_cta_label' => '_vireoka_cta_label',
      'vireoka_cta_url' => '_vireoka_cta_url',
      'vireoka_accent' => '_vireoka_accent',
      'vireoka_order' => '_vireoka_order',
    ];

    foreach ($map as $in => $meta) {
      $val = isset($_POST[$in]) ? sanitize_text_field(wp_unslash($_POST[$in])) : '';
      update_post_meta($post_id, $meta, $val);
    }
  }

  // ---------------- SETTINGS + ADMIN UI ----------------
  public static function admin_menu(): void {
    add_menu_page(
      'Vireoka',
      'Vireoka',
      'manage_options',
      'vireoka-settings',
      [__CLASS__, 'render_settings_page'],
      'dashicons-shield',
      58
    );
    add_submenu_page(
      'vireoka-settings',
      'Vireoka Settings',
      'Settings',
      'manage_options',
      'vireoka-settings',
      [__CLASS__, 'render_settings_page']
    );
    add_submenu_page(
      'vireoka-settings',
      'Quick Links',
      'Quick Links',
      'manage_options',
      'vireoka-quicklinks',
      [__CLASS__, 'render_quicklinks_page']
    );
  }

  public static function register_settings(): void {
    register_setting('vireoka_settings', 'vireoka_site_tagline', ['type'=>'string','sanitize_callback'=>'sanitize_text_field','default'=>'De-risking innovation with agentic AI ecosystems']);
    register_setting('vireoka_settings', 'vireoka_social_x', ['type'=>'string','sanitize_callback'=>'esc_url_raw','default'=>'']);
    register_setting('vireoka_settings', 'vireoka_social_linkedin', ['type'=>'string','sanitize_callback'=>'esc_url_raw','default'=>'']);
    register_setting('vireoka_settings', 'vireoka_social_github', ['type'=>'string','sanitize_callback'=>'esc_url_raw','default'=>'']);
    register_setting('vireoka_settings', 'vireoka_og_image', ['type'=>'string','sanitize_callback'=>'esc_url_raw','default'=>'']);

    add_settings_section('vireoka_main', 'Brand & Social', '__return_false', 'vireoka-settings');

    add_settings_field('vireoka_site_tagline', 'Tagline', [__CLASS__, 'field_text'], 'vireoka-settings', 'vireoka_main', [
      'key' => 'vireoka_site_tagline',
      'placeholder' => 'De-risking innovation with agentic AI ecosystems',
    ]);

    add_settings_field('vireoka_og_image', 'Default OG Image URL', [__CLASS__, 'field_text'], 'vireoka-settings', 'vireoka_main', [
      'key' => 'vireoka_og_image',
      'placeholder' => 'https://vireoka.com/path/to/og.jpg',
    ]);

    add_settings_field('vireoka_social_linkedin', 'LinkedIn URL', [__CLASS__, 'field_text'], 'vireoka-settings', 'vireoka_main', [
      'key' => 'vireoka_social_linkedin',
      'placeholder' => 'https://www.linkedin.com/company/...',
    ]);
    add_settings_field('vireoka_social_x', 'X (Twitter) URL', [__CLASS__, 'field_text'], 'vireoka-settings', 'vireoka_main', [
      'key' => 'vireoka_social_x',
      'placeholder' => 'https://x.com/...',
    ]);
    add_settings_field('vireoka_social_github', 'GitHub URL', [__CLASS__, 'field_text'], 'vireoka-settings', 'vireoka_main', [
      'key' => 'vireoka_social_github',
      'placeholder' => 'https://github.com/...',
    ]);
  }

  public static function field_text(array $args): void {
    $key = $args['key'];
    $val = get_option($key, '');
    $ph = $args['placeholder'] ?? '';
    printf(
      '<input type="text" name="%s" value="%s" placeholder="%s" style="width:520px;max-width:100%%" />',
      esc_attr($key),
      esc_attr($val),
      esc_attr($ph)
    );
  }

  public static function render_settings_page(): void {
    ?>
    <div class="wrap">
      <h1>Vireoka Settings</h1>
      <form method="post" action="options.php">
        <?php
          settings_fields('vireoka_settings');
          do_settings_sections('vireoka-settings');
          submit_button('Save Settings');
        ?>
      </form>
      <hr />
      <p><strong>Tip:</strong> Create Products under <em>Products → Add New</em>. Use sort order to control homepage display.</p>
    </div>
    <?php
  }

  public static function render_quicklinks_page(): void {
    ?>
    <div class="wrap">
      <h1>Quick Links</h1>
      <ul style="line-height:1.9">
        <li><a href="<?php echo esc_url(admin_url('edit.php?post_type='.self::CPT)); ?>">Manage Products</a></li>
        <li><a href="<?php echo esc_url(admin_url('post-new.php?post_type='.self::CPT)); ?>">Add Product</a></li>
        <li><a href="<?php echo esc_url(home_url('/products/')); ?>" target="_blank" rel="noopener">View Products Archive</a></li>
        <li><a href="<?php echo esc_url(home_url('/pricing/')); ?>" target="_blank" rel="noopener">View Pricing</a></li>
        <li><a href="<?php echo esc_url(home_url('/')); ?>" target="_blank" rel="noopener">View Homepage</a></li>
      </ul>
    </div>
    <?php
  }

  // ---------------- PRICING TEMPLATE ROUTING ----------------
  public static function pricing_template_router(string $template): string {
    if (is_page('pricing')) {
      $t = get_stylesheet_directory() . '/page-pricing.php';
      if (file_exists($t)) return $t;
    }
    return $template;
  }

  // ---------------- SEO + OG ----------------
  public static function output_seo_og(): void {
    if (is_admin()) return;

    $site = get_bloginfo('name');
    $tagline = get_option('vireoka_site_tagline', get_bloginfo('description'));
    $url = (is_singular() ? get_permalink() : home_url(add_query_arg([], $_SERVER['REQUEST_URI'] ?? '/')));
    $title = $site;
    $desc = $tagline;

    if (is_front_page()) {
      $title = $site;
      $desc = $tagline;
    } elseif (is_singular(self::CPT)) {
      $title = single_post_title('', false) . ' — ' . $site;
      $subtitle = get_post_meta(get_the_ID(), '_vireoka_subtitle', true);
      $desc = $subtitle ? $subtitle : (get_the_excerpt() ?: $tagline);
    } elseif (is_page()) {
      $title = single_post_title('', false) . ' — ' . $site;
      $desc = get_the_excerpt() ?: $tagline;
    } elseif (is_post_type_archive(self::CPT)) {
      $title = 'Products — ' . $site;
      $desc = 'Explore Vireoka’s product suite: six platforms powered by one agent cloud.';
    }

    $og_img = get_option('vireoka_og_image', '');
    if (!$og_img && is_singular() && has_post_thumbnail()) {
      $og_img = get_the_post_thumbnail_url(get_the_ID(), 'large');
    }

    echo "\n<!-- Vireoka SEO/OG -->\n";
    echo '<meta name="description" content="'.esc_attr($desc).'">'."\n";
    echo '<meta property="og:site_name" content="'.esc_attr($site).'">'."\n";
    echo '<meta property="og:title" content="'.esc_attr($title).'">'."\n";
    echo '<meta property="og:description" content="'.esc_attr($desc).'">'."\n";
    echo '<meta property="og:type" content="'.esc_attr(is_singular() ? 'article' : 'website').'">'."\n";
    echo '<meta property="og:url" content="'.esc_url($url).'">'."\n";
    if ($og_img) echo '<meta property="og:image" content="'.esc_url($og_img).'">'."\n";
    echo '<meta name="twitter:card" content="summary_large_image">'."\n";
    echo "<!-- /Vireoka SEO/OG -->\n\n";
  }

  // ---------------- SHORTCODE ----------------
  public static function shortcode_products_grid($atts): string {
    $atts = shortcode_atts([
      'limit' => 12,
    ], $atts);

    $q = new \WP_Query([
      'post_type' => self::CPT,
      'posts_per_page' => (int)$atts['limit'],
      'orderby' => 'meta_value_num',
      'meta_key' => '_vireoka_order',
      'order' => 'ASC',
    ]);

    if (!$q->have_posts()) {
      return '<div class="vireoka-empty">No products yet. Add them in the admin under Products.</div>';
    }

    ob_start();
    echo '<div class="vireoka-grid">';
    while ($q->have_posts()) {
      $q->the_post();
      $id = get_the_ID();
      $subtitle = get_post_meta($id, '_vireoka_subtitle', true);
      $badge = get_post_meta($id, '_vireoka_badge', true);
      $cta = get_post_meta($id, '_vireoka_cta_label', true) ?: 'View';
      $link = get_permalink($id);

      echo '<article class="vireoka-card">';
      if ($badge) echo '<div class="vireoka-badge">'.esc_html($badge).'</div>';
      echo '<h3 class="vireoka-card-title"><a href="'.esc_url($link).'">'.esc_html(get_the_title()).'</a></h3>';
      if ($subtitle) echo '<p class="vireoka-card-sub">'.esc_html($subtitle).'</p>';
      echo '<div class="vireoka-card-actions"><a class="vireoka-btn" href="'.esc_url($link).'">'.esc_html($cta).'</a></div>';
      echo '</article>';
    }
    echo '</div>';
    wp_reset_postdata();
    return (string)ob_get_clean();
  }
}

Vireoka_Core::boot();

register_activation_hook(__FILE__, function () {
  Vireoka_Core::register_cpt();
  Vireoka_Core::register_taxonomy();
  flush_rewrite_rules();
});
register_deactivation_hook(__FILE__, function () {
  flush_rewrite_rules();
});

/* ============================
   VIREOKA JSON-LD Schema
   ============================ */
add_action('wp_head', function () {
  if (is_admin()) return;

  $org = [
    '@context' => 'https://schema.org',
    '@type' => 'Organization',
    'name' => 'Vireoka',
    'url' => home_url('/'),
    'email' => 'hello@vireoka.com',
    'sameAs' => array_values(array_filter([
      get_option('vireoka_social_linkedin', ''),
      get_option('vireoka_social_x', ''),
      get_option('vireoka_social_github', ''),
    ])),
  ];

  $site = [
    '@context' => 'https://schema.org',
    '@type' => 'WebSite',
    'name' => get_bloginfo('name'),
    'url' => home_url('/'),
  ];

  $graphs = [$org, $site];

  if (is_singular('vireoka_product')) {
    $id = get_the_ID();
    $subtitle = get_post_meta($id, '_vireoka_subtitle', true);
    $badge = get_post_meta($id, '_vireoka_badge', true);
    $prod = [
      '@context' => 'https://schema.org',
      '@type' => 'Product',
      'name' => get_the_title($id),
      'description' => $subtitle ? $subtitle : wp_strip_all_tags(get_the_excerpt($id)),
      'brand' => ['@type'=>'Brand','name'=>'Vireoka'],
      'category' => 'Software',
      'url' => get_permalink($id),
      'sku' => 'vireoka-' . $id,
    ];
    if ($badge) $prod['slogan'] = $badge;
    if (has_post_thumbnail($id)) $prod['image'] = [get_the_post_thumbnail_url($id, 'large')];
    $graphs[] = $prod;
  }

  echo "\n<!-- VIREOKA JSON-LD -->\n";
  foreach ($graphs as $g) {
    echo '<script type="application/ld+json">' . wp_json_encode($g, JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE) . "</script>\n";
  }
  echo "<!-- /VIREOKA JSON-LD -->\n\n";
}, 3);
