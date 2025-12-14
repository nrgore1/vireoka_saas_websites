<?php
use Elementor\Widget_Base;
use Elementor\Controls_Manager;

class Vireoka_CTA_Widget extends Widget_Base {
  public function get_name(){ return 'vireoka_cta'; }
  public function get_title(){ return 'Vireoka CTA'; }
  public function get_icon(){ return 'eicon-call-to-action'; }
  public function get_categories(){ return ['general']; }

  protected function register_controls(){
    $this->start_controls_section('content',['label'=>'CTA']);
    $this->add_control('title',['type'=>Controls_Manager::TEXT,'default'=>'Request Enterprise Demo']);
    $this->add_control('button',['type'=>Controls_Manager::TEXT,'default'=>'Request Demo']);
    $this->add_control('url',['type'=>Controls_Manager::TEXT,'default'=>'/contact/']);
    $this->end_controls_section();
  }

  protected function render(){
    $s=$this->get_settings_for_display(); ?>
    <div class="v-panel">
      <h2><?=esc_html($s['title'])?></h2>
      <a class="v-btn" href="<?=esc_url($s['url'])?>"><?=esc_html($s['button'])?></a>
    </div>
  <?php }
}
