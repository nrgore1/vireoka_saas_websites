<?php get_header(); ?>
<section class="v-hero">
  <div class="v-container v-hero-inner">
    <div class="v-kicker">Plans</div>
    <h1>Pricing</h1>
    <p class="v-sub">Launch fast with a product, then expand into the full agent cloud. Enterprise support available for regulated and high-stakes workflows.</p>
    <div class="v-hero-actions">
      <a class="v-btn" href="<?php echo esc_url(home_url('/contact/')); ?>">Request Demo</a>
      <a class="v-btn v-btn-secondary" href="<?php echo esc_url(home_url('/products/')); ?>">Explore Products</a>
    </div>
  </div>
</section>

<section class="v-section">
  <div class="v-container">
    <div class="v-price-grid">
      <div class="v-price">
        <h3>Starter</h3>
        <p class="price">$49</p>
        <p>Early access for builders and creators. Great for single-product pilots.</p>
        <ul>
          <li>1 product access</li>
          <li>Email support</li>
          <li>Basic analytics</li>
        </ul>
        <div style="margin-top:14px"><a class="v-btn v-btn-secondary" href="<?php echo esc_url(home_url('/contact/')); ?>">Join Waitlist</a></div>
      </div>

      <div class="v-price featured">
        <h3>Growth</h3>
        <p class="price">$199</p>
        <p>For teams shipping workflows. Multi-agent features and integrations.</p>
        <ul>
          <li>Up to 3 products</li>
          <li>Priority support</li>
          <li>Workflow templates</li>
        </ul>
        <div style="margin-top:14px"><a class="v-btn" href="<?php echo esc_url(home_url('/contact/')); ?>">Request Early Access</a></div>
      </div>

      <div class="v-price">
        <h3>Enterprise</h3>
        <p class="price">Custom</p>
        <p>Security, compliance, SLAs, and deployment support for high-stakes systems.</p>
        <ul>
          <li>All products + Agent Cloud</li>
          <li>SSO / RBAC (roadmap)</li>
          <li>Dedicated success</li>
        </ul>
        <div style="margin-top:14px"><a class="v-btn v-btn-secondary" href="<?php echo esc_url(home_url('/contact/')); ?>">Talk to Sales</a></div>
      </div>
    </div>

    <div style="height:22px"></div>

    <div class="v-panel">
      <h2>Enterprise Request Demo</h2>
      <p>Tell us your outcome and constraints (privacy, latency, cost, compliance). We’ll propose an agent architecture and rollout plan.</p>
      <a class="v-btn" href="<?php echo esc_url(home_url('/contact/')); ?>">Request Demo</a>
    </div>
  </div>
</section>
<?php get_footer(); ?>
