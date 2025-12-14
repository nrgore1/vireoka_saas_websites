<?php
use Elementor\Widget_Base;
use Elementor\Controls_Manager;

class Vireoka_Hero_Widget extends Widget_Base {
  public function get_name(){ return 'vireoka_hero'; }
  public function get_title(){ return 'Vireoka Hero'; }
  public function get_icon(){ return 'eicon-banner'; }
  public function get_categories(){ return ['general']; }

  protected function register_controls(){
    $this->start_controls_section('content',['label'=>'Content']);
    $this->add_control('kicker',['type'=>Controls_Manager::TEXT,'default'=>'AI Agent Platform']);
    $this->add_control('title',['type'=>Controls_Manager::TEXT,'default'=>'De-risking Innovation with Agentic AI']);
    $this->add_control('subtitle',['type'=>Controls_Manager::TEXTAREA,'default'=>'Six products. One agent cloud.']);
    $this->end_controls_section();
  }

  protected function render(){
    $s=$this->get_settings_for_display(); ?>
    <section class="v-hero">
      <div class="v-container v-hero-inner">
        <div class="v-kicker"><?=esc_html($s['kicker'])?></div>
        <h1><?=esc_html($s['title'])?></h1>
        <p class="v-sub"><?=esc_html($s['subtitle'])?></p>
      </div>
    </section>
  <?php }
}
