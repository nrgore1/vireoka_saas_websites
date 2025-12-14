<?php get_header(); ?>
<?php while (have_posts()): the_post();
  $id = get_the_ID();
  $subtitle = get_post_meta($id, '_vireoka_subtitle', true);
  $badge = get_post_meta($id, '_vireoka_badge', true);
  $cta_label = get_post_meta($id, '_vireoka_cta_label', true) ?: 'Request Early Access';
  $cta_url = get_post_meta($id, '_vireoka_cta_url', true) ?: '/contact/';
  $accent = get_post_meta($id, '_vireoka_accent', true) ?: 'luxe';

  $hero_style = 'background: var(--hero);';
  if ($accent === 'teal')  $hero_style = 'background: radial-gradient(900px circle at 20% 20%, rgba(58,244,211,.22), transparent 60%), linear-gradient(180deg, var(--blue), var(--ink));';
  if ($accent === 'gold')  $hero_style = 'background: radial-gradient(900px circle at 20% 20%, rgba(228,180,72,.22), transparent 60%), linear-gradient(180deg, var(--blue), var(--ink));';
  if ($accent === 'neural')$hero_style = 'background: radial-gradient(900px circle at 20% 20%, rgba(90,47,227,.35), transparent 55%), radial-gradient(900px circle at 80% 75%, rgba(58,244,211,.20), transparent 62%), linear-gradient(180deg, var(--blue), var(--ink));';
?>
<section class="v-hero" style="<?php echo esc_attr($hero_style); ?>">
  <div class="v-container v-hero-inner">
    <div class="v-kicker">Vireoka Product</div>
    <h1><?php the_title(); ?></h1>
    <?php if ($subtitle): ?><p class="v-sub"><?php echo esc_html($subtitle); ?></p><?php endif; ?>
    <div class="v-hero-actions">
      <a class="v-btn" href="<?php echo esc_url(home_url($cta_url)); ?>"><?php echo esc_html($cta_label); ?></a>
      <a class="v-btn v-btn-secondary" href="<?php echo esc_url(home_url('/products/')); ?>">All Products</a>
    </div>
    <?php if ($badge): ?><div style="margin-top:16px" class="vireoka-badge"><?php echo esc_html($badge); ?></div><?php endif; ?>
  </div>
</section>

<section class="v-section">
  <div class="v-container">
    <div class="v-panel">
      <?php the_content(); ?>
    </div>
  </div>
</section>
<?php endwhile; ?>
<?php get_footer(); ?>
