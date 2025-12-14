<?php
/**
 * Fallback main template for Vireoka Teaser Theme
 */
get_header();
?>

<main id="site-content">
    <?php
    while ( have_posts() ) :
        the_post();
        the_content();
    endwhile;
    ?>
</main>

<?php get_footer(); ?>
