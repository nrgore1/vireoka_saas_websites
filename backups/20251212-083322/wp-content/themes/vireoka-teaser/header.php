<?php ?><!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo('charset'); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<?php wp_head(); ?>
</head>

<body <?php body_class('vireoka-body'); ?>>
<header class="vireoka-header">
    <div class="vireoka-header-inner">
        <div class="vireoka-logo">
            <a href="<?php echo esc_url( home_url('/') ); ?>">
                <span class="vireoka-logo-mark">V</span>
                <span class="vireoka-logo-text">Vireoka</span>
            </a>
        </div>

        <nav class="vireoka-main-nav">
            <?php wp_nav_menu([
                'theme_location' => 'primary',
                'menu_class' => 'vireoka-nav-list',
                'container' => false
            ]); ?>
        </nav>

        <div class="vireoka-header-cta">
            <a href="/investors" class="vireoka-pill-cta">Investor Briefing</a>
        </div>
    </div>
</header>

<main class="vireoka-main">
