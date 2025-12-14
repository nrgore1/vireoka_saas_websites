<?php get_header(); ?>
<section class="v-hero">
  <div class="v-container v-hero-inner">
    <div class="v-kicker">Platform Suite</div>
    <h1>Products</h1>
    <p class="v-sub">Six products. One agent cloud. Choose a platform — or deploy the full ecosystem.</p>
    <div class="v-hero-actions">
      <a class="v-btn" href="<?php echo esc_url(home_url('/pricing/')); ?>">Pricing</a>
      <a class="v-btn v-btn-secondary" href="<?php echo esc_url(home_url('/contact/')); ?>">Request Demo</a>
    </div>
  </div>
</section>

<section class="v-section">
  <div class="v-container">
    <?php echo do_shortcode('[vireoka_products_grid limit="24"]'); ?>
  </div>
</section>
<?php get_footer(); ?>
