<?php
/**
 * Plugin Name: Vireoka Multilingual Helper
 * Description: Simple multilingual helper that uses an external AI translation API to clone pages/posts into target languages.
 * Version: 1.0.0
 * Author: Vireoka
 */
if ( ! defined( 'ABSPATH' ) ) exit;
/**
 * Register settings.
 */
add_action( 'admin_init', function () {
    register_setting( 'vireoka_multilingual', 'vk_ml_api_url' );
    register_setting( 'vireoka_multilingual', 'vk_ml_api_key' );
    register_setting( 'vireoka_multilingual', 'vk_ml_target_langs' ); // comma-separated, e.g. "hi,es"
} );
/**
 * Settings page.
 */
add_action( 'admin_menu', function () {
    add_options_page(
        'Vireoka Multilingual',
        'Vireoka Multilingual',
        'manage_options',
        'vireoka-multilingual',
        function () {
            ?>
            <div class="wrap">
              <h1>Vireoka Multilingual Settings</h1>
              <form method="post" action="options.php">
                <?php
                  settings_fields( 'vireoka_multilingual' );
                  do_settings_sections( 'vireoka_multilingual' );
                ?>
                <table class="form-table">
                  <tr>
                    <th scope="row"><label for="vk_ml_api_url">Translation API URL</label></th>
                    <td>
                      <input type="text" class="regular-text" name="vk_ml_api_url" id="vk_ml_api_url"
                             value="<?php echo esc_attr( get_option( 'vk_ml_api_url', '' ) ); ?>" />
                      <p class="description">Example: https://api.vireoka.com/translate</p>
                    </td>
                  </tr>
                  <tr>
                    <th scope="row"><label for="vk_ml_api_key">Translation API Key</label></th>
                    <td>
                      <input type="password" class="regular-text" name="vk_ml_api_key" id="vk_ml_api_key"
                             value="<?php echo esc_attr( get_option( 'vk_ml_api_key', '' ) ); ?>" />
                    </td>
                  </tr>
                  <tr>
                    <th scope="row"><label for="vk_ml_target_langs">Target Languages</label></th>
                    <td>
                      <input type="text" class="regular-text" name="vk_ml_target_langs" id="vk_ml_target_langs"
                             value="<?php echo esc_attr( get_option( 'vk_ml_target_langs', 'hi,es' ) ); ?>" />
                      <p class="description">Comma-separated language codes, e.g.: hi,es</p>
                    </td>
                  </tr>
                </table>
                <?php submit_button(); ?>
              </form>
            </div>
            <?php
        }
    );
} );
/**
 * Bulk action: Generate Translations.
 */
add_filter( 'bulk_actions-edit-page', function ( $actions ) {
    $actions['vk_generate_translations'] = 'Generate Translations (Vireoka)';
    return $actions;
} );
add_filter( 'handle_bulk_actions-edit-page', function ( $redirect, $doaction, $post_ids ) {
    if ( $doaction !== 'vk_generate_translations' || empty( $post_ids ) ) {
        return $redirect;
    }
$api_url   = trim( get_option( 'vk_ml_api_url', '' ) );
    $api_key   = trim( get_option( 'vk_ml_api_key', '' ) );
    $languages = array_filter( array_map( 'trim', explode( ',', get_option( 'vk_ml_target_langs', 'hi,es' ) ) ) );
if ( empty( $api_url ) || empty( $languages ) ) {
        return add_query_arg( 'vk_ml_result', 'missing_settings', $redirect );
    }
foreach ( $post_ids as $post_id ) {
        $post = get_post( $post_id );
        if ( ! $post || $post->post_type !== 'page' ) {
            continue;
        }
foreach ( $languages as $lang ) {
            $translated = vireoka_ml_translate_post( $post, $lang, $api_url, $api_key );
            if ( ! is_wp_error( $translated ) && $translated ) {
                // ok
            }
        }
    }
return add_query_arg( 'vk_ml_result', 'ok', $redirect );
}, 10, 3 );
/**
 * Translation helper.
 */
function vireoka_ml_translate_post( WP_Post $post, $lang, $api_url, $api_key ) {
$body = wp_json_encode( array(
        'source_language' => 'en',
        'target_language' => $lang,
        'title'           => $post->post_title,
        'content'         => $post->post_content,
    ) );
$headers = array( 'Content-Type' => 'application/json' );
    if ( ! empty( $api_key ) ) {
        $headers['Authorization'] = 'Bearer ' . $api_key;
    }
$response = wp_remote_post( $api_url, array(
        'headers' => $headers,
        'body'    => $body,
        'timeout' => 30,
    ) );
if ( is_wp_error( $response ) ) {
        return $response;
    }
$code = wp_remote_retrieve_response_code( $response );
    $raw  = wp_remote_retrieve_body( $response );
    $data = json_decode( $raw, true );
if ( $code >= 400 || ! is_array( $data ) ) {
        return new WP_Error( 'vk_ml_api_error', 'Translation API error: ' . $raw );
    }
$new_title   = isset( $data['title'] ) ? $data['title'] : $post->post_title . ' (' . $lang . ')';
    $new_content = isset( $data['content'] ) ? $data['content'] : $post->post_content;
$new_post_id = wp_insert_post( array(
        'post_title'   => $new_title,
        'post_content' => $new_content,
        'post_type'    => $post->post_type,
        'post_status'  => 'draft',
    ) );
return $new_post_id;
}
