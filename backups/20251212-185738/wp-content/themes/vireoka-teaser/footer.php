</main>

<footer class="vireoka-footer">
    <div class="vireoka-footer-top">
        <div class="vireoka-footer-brand">
            <div class="vireoka-logo">
                <span class="vireoka-logo-mark">V</span>
                <span class="vireoka-logo-text">Vireoka</span>
            </div>
            <p>The AI-Agent Company — Multi-agent ecosystems across creativity, cloud, finance, and human connection.</p>
        </div>

        <div class="vireoka-footer-nav">
            <?php wp_nav_menu([
                'theme_location' => 'footer',
                'menu_class' => 'vireoka-footer-menu',
                'container' => false
            ]); ?>
        </div>
    </div>

    <div class="vireoka-footer-bottom">
        <span>© <?php echo date('Y'); ?> Vireoka LLC</span>
        <span>Aligned AI Agents • Secure • Efficient</span>
    </div>
</footer>

<?php wp_footer(); ?>
</body>
</html>
