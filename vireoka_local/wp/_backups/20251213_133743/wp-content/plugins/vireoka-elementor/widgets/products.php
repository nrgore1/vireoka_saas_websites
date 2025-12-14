<?php
use Elementor\Widget_Base;
use Elementor\Controls_Manager;

class Vireoka_Products_Widget extends Widget_Base {
  public function get_name(){ return 'vireoka_products'; }
  public function get_title(){ return 'Vireoka Products Grid'; }
  public function get_icon(){ return 'eicon-posts-grid'; }
  public function get_categories(){ return ['general']; }

  protected function register_controls(){
    $this->start_controls_section('content',['label'=>'Query']);
    $this->add_control('limit',['type'=>Controls_Manager::NUMBER,'default'=>6]);
    $this->end_controls_section();
  }

  protected function render(){
    echo do_shortcode('[vireoka_products_grid limit="'.$this->get_settings_for_display('limit').'"]');
  }
}
