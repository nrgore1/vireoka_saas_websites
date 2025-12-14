<?php
use Elementor\Widget_Base;
use Elementor\Controls_Manager;

class Vireoka_Investor_Widget extends Widget_Base {
  public function get_name(){ return 'vireoka_investor'; }
  public function get_title(){ return 'Vireoka Investor Panel'; }
  public function get_icon(){ return 'eicon-site-logo'; }
  public function get_categories(){ return ['general']; }

  protected function register_controls(){
    $this->start_controls_section('content',['label'=>'Investor']);
    $this->add_control('headline',['type'=>Controls_Manager::TEXT,'default'=>'A Multi-Product AI Agent Platform']);
    $this->add_control('copy',['type'=>Controls_Manager::TEXTAREA,'default'=>'Six products powered by a shared agent cloud. Built for trust, orchestration, and enterprise outcomes.']);
    $this->end_controls_section();
  }

  protected function render(){
    $s=$this->get_settings_for_display(); ?>
    <div class="v-panel">
      <h2><?=esc_html($s['headline'])?></h2>
      <p><?=esc_html($s['copy'])?></p>
      <a class="v-btn v-btn-secondary" href="/investors/">Investor Overview</a>
    </div>
  <?php }
}
